create or replace package body saas_auth_pkg as


procedure delete_user(
   p_user_name in varchar2) is 
begin 
   delete from saas_auth where user_name=lower(p_user_name);
end;

function does_user_name_exist (
   -- Return true if the user name exists.
   --
   p_user_name in varchar2) return boolean is
   n number;
   v_user_name saas_auth.user_name%type := lower(p_user_name);
begin 
   arcsql.debug('does_user_name_exist: '||v_user_name);
   select count(*) into n 
      from v_saas_auth_available_accounts
     where user_name=v_user_name;
   return n = 1;
end;


procedure raise_user_name_not_found (
   -- Raises error if user name does not exist.
   --
   p_user_name in varchar2 default null) is 
begin 
   if not does_user_name_exist(p_user_name) then
      raise_application_error(-20001, 'raise_user_name_not_found: '||p_user_name);
   end if;
end;


function get_uuid (p_user_name in varchar2) return varchar2 is 
   -- Return a user's uuid from user name.
   --
   n number;
   v_uuid saas_auth.uuid%type;
begin 
   select uuid into v_uuid 
     from v_saas_auth_available_accounts
    where user_name=lower(p_user_name);
   return v_uuid;
end;


function get_email_address_override (
   -- Returns the override address if set otherwise returns the original address.
   --
   p_email varchar2) return varchar2 is 
begin 
   return nvl(trim(saas_auth_config.send_all_emails_to), p_email);
end;  


procedure set_error_message (p_message in varchar2) is 
begin 
   apex_error.add_error (
      p_message          => p_message,
      p_display_location => apex_error.c_inline_in_notification );
end;


function does_email_exist (
   -- Return true if the email exists.
   --
   p_email in varchar2) return boolean is
   n number;
   v_email saas_auth.email%type := lower(p_email);
begin 
   arcsql.debug('does_email_exist: '||v_email);
   select count(*) into n 
      from v_saas_auth_available_accounts
     where email=v_email;
   return n = 1;
end;


procedure raise_password_failed_complexity_check (
   p_password in varchar2) is 
begin 
   if not arcsql.str_complexity_check(text=>p_password, chars=>8) then 
      set_error_message('Password needs to be at least 8 characters long.');
      raise_application_error(-20001, 'Password needs to be at least 8 characters long.');
   end if;
   if not arcsql.str_complexity_check(text=>p_password, uppercase=>1) then 
      set_error_message('Password needs at least 1 upper-case character.');
      raise_application_error(-20001, 'Password needs at least 1 upper-case character.');
   end if;
   if not arcsql.str_complexity_check(text=>p_password, lowercase=>1) then 
      set_error_message('Password needs at least 1 lower-case character.');
      raise_application_error(-20001, 'Password needs at least 1 lower-case character.');
   end if;
   if not arcsql.str_complexity_check(text=>p_password, digit=>1) then 
      set_error_message('Password needs at least 1 digit.');
      raise_application_error(-20001, 'Password needs at least 1 digit.');
   end if;
end;


function get_hashed_password (
   -- Returns SHA256 hash we will store in the password field.
   --
   p_secret_string in varchar2) return raw is
begin
   return arcsql.encrypt_sha256(saas_auth_config.saas_auth_salt || p_secret_string);
end;


procedure raise_email_not_found (
   p_email in varchar2 default null) is 
   -- Raises error if user is not found.
   n number;
begin 
   arcsql.debug('raise_email_not_found: ');
   if not does_email_exist(p_email) then
      set_error_message('Email not found.');
      raise_application_error(-20001, 'raise_email_not_found: '||p_email);
   end if;
end;


procedure fire_on_login_event (
   -- Calls the on_login procedure if it exists.
   --
   -- This is the hook apps using auth can use to trigger workflow when a user logs on.
   p_user_id in varchar2) is 
   
   n number;
begin 
   arcsql.debug('file_login_event: user='||p_user_id);
   update saas_auth 
      set reset_pass_token=null, 
          reset_pass_expire=null,
          last_login=sysdate,
          login_count=login_count+1,
          last_session_id=v('APP_SESSION'),
          failed_login_count=0
    where user_id=p_user_id;
   select count(*) into n from user_source 
    where name = 'ON_LOGIN'
      and type='PROCEDURE';
   if n > 0 then 
      arcsql.debug('fire_on_login_event: '||p_user_id);
      execute immediate 'begin on_login('||p_user_id||'); end;';
   end if;
end;


procedure set_password (
   -- Sets a user password. 
   --
   -- Note that the complexity check does not run here.
   p_user_name in varchar2,
   p_password in varchar2) is 
   hashed_password varchar2(120);
   v_uuid saas_auth.uuid%type;
begin 
   arcsql.debug('set_password: '||p_user_name);
   raise_user_name_not_found(p_user_name=>p_user_name);
   v_uuid := get_uuid(p_user_name=>p_user_name);
   hashed_password := get_hashed_password(p_secret_string=>v_uuid||p_password);
   update saas_auth
      set password=hashed_password
    where user_name=lower(p_user_name);
exception 
   when others then
      arcsql.log_err('set_password: '||dbms_utility.format_error_stack);
      raise;
end;


function is_email_verified (
   -- Return true if email has been verified. 
   --
   p_user_name in varchar2) return boolean is 
   n number;
begin 
   select count(*) into n 
     from v_saas_auth_available_accounts  
    where user_name=lower(p_user_name) 
      and email_verified is not null;
   return n = 1;
end;


function is_email_verification_enabled return boolean is 
begin 
   return saas_auth_config.allowed_logins_before_email_verification_is_required is not null;
end; 


function is_account_locked (
   -- Return true if email has been verified. 
   --
   p_user_name in varchar2) return boolean is 
   n number;
begin 
   select count(*) into n from saas_auth  
    where user_name=lower(p_user_name) 
      and account_status='locked';
   return n=1;
end;


procedure raise_account_is_locked (
   -- Raises an error if the account is locked.
   --
   p_user_name in varchar2) is 
   n number;
begin 
   if is_account_locked(p_user_name) then 
      raise_application_error(-20001, 'raise_account_is_locked: '||lower(p_user_name));
   end if;
end;


procedure raise_too_many_auth_requests is 
   -- Raises error if too many authorization requests are being made.
   --
begin 
   arcsql.debug('raise_too_many_auth_requests: ');
   if saas_auth_config.auth_request_rate_limit is null then 
      return;
   end if;
   -- If there have been more than 20 requests in the past minute raise an error.
   if arcsql.get_request_count(p_request_key=>'saas_auth', p_min=>10) > saas_auth_config.auth_request_rate_limit then
     set_error_message('Authorization request rate has been exceeded.');
     raise_application_error(-20001, 'Authorization request rate has been exceeded.');
     apex_util.pause(1);
   end if;
end;


function ui_branch_to_main_after_auth (
   -- Go to main page after registration if condition exists.
   --
   p_email in varchar2) return boolean is  
   v_saas_auth saas_auth%rowtype;
begin 
   arcsql.debug('ui_branch_to_main_after_auth: ');
   select * into v_saas_auth from v_saas_auth_available_accounts 
    where email=lower(p_email);
   if v_saas_auth.email_verified is not null then 
      arcsql.debug('true1');
      return true;
   end if;
   if saas_auth_config.allowed_logins_before_email_verification_is_required is null then 
      arcsql.debug('true2');
      return true;
   end if;
   -- Register button was clicked
   if v_saas_auth.login_count = 0 then 
      if saas_auth_config.allowed_logins_before_email_verification_is_required > 0 then 
         arcsql.debug('true3');
         return true;
      end if;
   else
      -- Login button was clicked
      if v_saas_auth.login_count > saas_auth_config.allowed_logins_before_email_verification_is_required then 
         arcsql.debug('true4');
         return true;
      end if;
   end if;
   return false;
end;


procedure send_email_verification_code_to (
   -- Sends a verification code to a user if the address is valid.
   --
   p_user_name in varchar2) is 
   t              saas_auth.email_verification_token%type   := arcsql.str_random(6, 'an');
   v_app_name     varchar2(120)                             := apex_utl2.get_app_name;
   v_app_id       number                                    := apex_utl2.get_app_id;
   v_protocol     varchar2(12)                              := saas_auth_config.saas_auth_protocol;
   v_domain       varchar2(120)                             := saas_auth_config.saas_auth_domain;
   v_from_address varchar2(120)                             := arcsql_cfg.default_email_from_address;
   good_for       number                                    := saas_auth_config.token_good_for_minutes;
   m              varchar2(1200);
   v_saas_auth    saas_auth%rowtype;
begin 
   if is_account_locked(p_user_name) then 
      return;
   end if;
   if is_email_verified(p_user_name) then
      return;
   end if;
   if not is_email_verification_enabled then 
      return;
   end if;

   select * into v_saas_auth  
     from v_saas_auth_available_accounts 
    where user_name=lower(p_user_name);

   update saas_auth 
      set email_verification_token=t,
          email_verification_token_expires_at=decode(nvl(good_for, 0), 0, null, sysdate+good_for/1440)
    where user_name=lower(p_user_name);

   m := '
Hello,

Thanks for signing up with '||v_app_name||'! Please verify your email address by clicking the link below.

'||v_protocol||'://'||v_domain||'/ords/f?p='||v_app_id||':verify:::::SAAS_AUTH_EMAIL,SAAS_AUTH_TOKEN:'||lower(v_saas_auth.email)||','||t||'

Thanks,

- The '||v_app_name||' Team';

   send_email (
      p_from=>v_from_address,
      p_to=>get_email_address_override(v_saas_auth.email),
      p_subject=>'Welcome to '||v_app_name||'. Please verify your email.',
      p_body=>m);

   if saas_auth_config.flash_notifications then 
      add_flash_message (
         p_message=>'Please look for a verification email in your inbox and click the provided link.',
         p_user_name=>lower(p_user_name),
         p_expires_at=>sysdate+5/1440);
   end if;

exception 
   when others then
      arcsql.log_err('send_email_verification_code_to: '||dbms_utility.format_error_stack);
      raise;
end;  


procedure verify_email_using_token (
   -- 
   --
   p_email in varchar2,
   p_auth_token in varchar2) is 
   n number;
   v_saas_auth saas_auth%rowtype;
begin 
   arcsql.debug('verify_email_using_token: '||p_auth_token);
   arcsql.count_request(p_request_key=>'saas_auth');
   raise_too_many_auth_requests;   
   raise_email_not_found(p_email);

   select * into v_saas_auth 
     from v_saas_auth_available_accounts 
    where email=lower(p_email);

   if v_saas_auth.email_verification_token = p_auth_token  
      and (v_saas_auth.email_verification_token_expires_at is null 
       or v_saas_auth.email_verification_token_expires_at >= sysdate) then 
      fire_on_login_event(get_user_id_from_email(p_email=>lower(p_email)));
      update saas_auth 
         set email_verification_token=null, 
             email_verification_token_expires_at=null, 
             email_verified=sysdate
       where user_id=v_saas_auth.user_id;
      apex_authentication.post_login (
         p_username=>lower(v_saas_auth.user_name), 
         -- Password does not matter here.
         p_password=>utl_raw.cast_to_raw(dbms_random.string('x',10)));
   end if;
exception 
   when others then
      arcsql.log_err('verify_email_using_token: '||dbms_utility.format_error_stack);
      raise;
end;


procedure set_timezone_name (
   -- Called when user logs in to set the current timezone name.
   -- 
   p_user_name in varchar2,
   p_timezone_name in varchar2) is 
   v_offset varchar2(12);
begin 
   arcsql.debug('set_timezone_name: user='||p_user_name||', '||p_timezone_name);
   select tz_offset(p_timezone_name) into v_offset from dual;
   update saas_auth 
      set timezone_name=p_timezone_name,
          timezone_offset=v_offset
    where user_name=lower(p_user_name);
   apex_util.set_session_time_zone(p_time_zone=>v_offset);
exception 
   when others then
      arcsql.log_err('set_timezone_name: '||dbms_utility.format_error_stack);
      raise;
end;


function does_email_already_exist (
   -- Return true if email exists.
   --
   p_email in varchar2) return boolean is
   n number;
begin
   arcsql.debug('does_email_already_exist: email='||p_email);
   select count(*) into n 
     from v_saas_auth_available_accounts
    where email=lower(p_email);
   return n > 0;
end;


procedure raise_email_already_exists (
   p_email in varchar2) is 
   -- Raises error if the email address exists.
   n number;
begin 
   if does_email_already_exist(p_email) then
      set_error_message('User is already registered.');
      raise_application_error(-20001, 'User is already registered.');
   end if;
end;


procedure raise_duplicate_user_name (
   p_user_name in varchar2) is 
   -- Raises error if user exists.
   n number;
begin 
   if does_user_name_exist(p_user_name) then
      set_error_message('User name already exists. Try using a different one.');
      raise_application_error(-20001, 'User name already exists.');
   end if;
end;


procedure raise_invalid_password_prefix (
   p_password in varchar2) is 
   -- Raises error if password prefix is defined and the password does not use it.
   p varchar2(120);
begin 
   p := saas_auth_config.saas_auth_pass_prefix;
   if trim(p) is not null then 
      if substr(p_password, 1, length(p)) != p then 
         set_error_message('This environment may not be available to the public (secret prefix defined).');
         raise_application_error(-20001, 'Secret prefix missing or did not match.');
      end if;
   end if;
end;


function get_email_from_user_name (
   p_user_name in varchar2) return varchar2 is 
   e saas_auth.email%type;
begin 
   select lower(email) into e 
     from v_saas_auth_available_accounts 
    where user_name = lower(p_user_name);
   return e;
end;


function get_user_id_from_user_name (
   -- Return the user id using the user name. 
   --
   p_user_name in varchar2 default v('APP_USER')) return number is 
   n number;
   v_user_name saas_auth.user_name%type := lower(p_user_name);
begin 
   arcsql.debug('get_user_id_from_user_name: user='||p_user_name);
   select user_id into n 
     from v_saas_auth_available_accounts 
    where user_name = v_user_name;
   return n;
exception 
   when others then
      arcsql.log_err('get_user_id_from_user_name: '||dbms_utility.format_error_stack);
      raise;
end;


function get_user_id_from_email (
   -- Return the user id using the user name. 
   --
   p_email in varchar2) return number is 
   n number;
begin 
   arcsql.debug('get_user_id_from_email: email='||lower(p_email));
   raise_email_not_found(p_email);
   select user_id into n 
     from v_saas_auth_available_accounts 
    where email = lower(p_email);
   return n;
exception 
   when others then
      arcsql.log_err('get_user_id_from_email: '||dbms_utility.format_error_stack);
      raise;
end;


function get_user_name (p_user_id in number) return varchar2 is 
   -- Return the user name by using the user id. 
   --
   n number;
   v_user_name saas_auth.user_name%type;
begin 
   select lower(user_name) into v_user_name 
     from v_saas_auth_available_accounts 
    where user_id=p_user_id;
   return v_user_name;
end;


procedure raise_does_not_appear_to_be_an_email_format (
   -- Raises an error if the string does not look like an email.
   --
   p_email in varchar2) is 
begin 
   if not arcsql.str_is_email(p_email) then 
      set_error_message('Email does not appear to be a valid email address.');
      raise_application_error(-20001, 'Email does not appear to be a valid email address.');
   end if;
end;


procedure add_test_user (
   -- Add a user which is only accessible in dev mode.
   --
   p_user_name in varchar2,
   -- If email is not provided it is assumed the user name is an email address.
   p_email in varchar2 default null) is 

   v_email varchar2(120) := p_email;
   test_pass varchar2(120);
begin
   arcsql.debug('add_test_user: '||p_user_name);
   test_pass := saas_auth_config.saas_auth_test_pass;
   if v_email is null then 
      v_email := p_user_name;
   end if;
   if not does_user_name_exist(p_user_name=>p_user_name) then
      add_user (
         p_user_name=>p_user_name,
         p_email=>v_email,
         p_password=>test_pass,
         p_is_test_user=>true);
   end if;
end;


procedure fire_create_account(p_user_id in varchar2) is 
   n number;
begin 
   arcsql.debug('saas_auth_pkg.fire_create_account: '||p_user_id);
   select count(*) into n from user_source 
    where name = 'ON_CREATE_ACCOUNT'
      and type='PROCEDURE';
   if n > 0 then 
      arcsql.debug('fire_create_account: '||p_user_id);
      execute immediate 'begin on_create_account('||p_user_id||'); end;';
   end if;
end;
    

procedure add_user (
   p_user_name in varchar2,
   p_email in varchar2,
   p_password in varchar2,
   p_is_test_user in boolean default false) is
   v_message varchar2(4000);
   v_password raw(64);
   v_user_id number;
   v_email varchar2(120) := lower(p_email);
   v_user_name varchar2(120) := lower(p_user_name);
   v_is_test_user varchar2(1) := 'n';
   v_uuid saas_auth.uuid%type;
   v_hashed_password saas_auth.password%type;
begin
   arcsql.debug('add_user: '||p_user_name||'~'||v_email);
   raise_does_not_appear_to_be_an_email_format(v_email);
   raise_duplicate_user_name(p_user_name=>v_email);
   if p_is_test_user then 
      v_is_test_user := 'y';
   end if;
   v_uuid := sys_guid();
   v_hashed_password := get_hashed_password(p_secret_string=>v_uuid||p_password);
   insert into saas_auth (
      user_name,
      email, 
      password,
      uuid,
      role_id,
      last_session_id,
      is_test_user) values (
      v_user_name,
      v_email, 
      v_hashed_password,
      v_uuid,
      1,
      v('APP_SESSION'),
      v_is_test_user);
   set_password (
      p_user_name=>p_user_name,
      p_password=>p_password);
   v_user_id := get_user_id_from_user_name(p_user_name=>v_user_name);
   fire_create_account(v_user_id);
end;


function is_email_verification_required (
   -- Return true if the user must verify email before logging in.
   --
   p_email in varchar2) return boolean is 
   v_saas_auth saas_auth%rowtype;
begin 
   arcsql.debug('is_email_verification_required: '||p_email);
   raise_email_not_found(p_email);
   select * into v_saas_auth 
     from v_saas_auth_available_accounts 
    where email=lower(p_email);
   if v_saas_auth.email_verified is not null then 
      arcsql.debug('false1');
      return false;
   end if;
   if v_saas_auth.login_count >= saas_auth_config.allowed_logins_before_email_verification_is_required then 
      arcsql.debug('true');
      return true;
   else
      arcsql.debug('false2');
      return false;
   end if;
exception 
   when others then
      arcsql.log_err('is_email_verification_required: '||dbms_utility.format_error_stack);
      set_error_message('There was an error processing this request.');
      return true;
end;


procedure create_account (
   -- Creates a new user account.
   --
   p_user_name in varchar2,
   p_email in varchar2,
   p_password in varchar2,
   p_confirm in varchar2,
   p_timezone_name in varchar2 default null) is
   v_message varchar2(4000);
   v_user_name varchar2(120) := lower(p_user_name);
   v_email varchar2(120) := lower(p_email);
   v_password raw(64);
   v_user_id number;
begin
   arcsql.debug('create_account: '||lower(p_email));
   arcsql.count_request(p_request_key=>'saas_auth');
   raise_too_many_auth_requests;

   raise_duplicate_user_name(p_user_name=>v_user_name);
   raise_invalid_password_prefix(p_password);
   if p_password != p_confirm then 
      set_error_message('Passwords do not match.');
      raise_application_error(-20001, 'Passwords do not match.');
   end if;
   raise_password_failed_complexity_check(p_password);
   add_user (
      p_user_name=>v_user_name,
      p_email=>v_email,
      p_password=>p_password);
   set_timezone_name (
      p_user_name => v_user_name,
      p_timezone_name => p_timezone_name);
   -- This only works if it is enabled.
   send_email_verification_code_to(v_email);
   -- Can we auto login the user right away?
   if saas_auth_config.allowed_logins_before_email_verification_is_required > 0 then
      v_password := utl_raw.cast_to_raw(dbms_random.string('x',10));
      apex_authentication.post_login (
         p_username=>v_user_name, 
         p_password=>p_password);
   end if;
   if saas_auth_config.send_email_on_create_account then 
      arcsql.log_email('saas_auth_pkg.create_account: '||v_user_name);
   end if;
exception 
   when others then
      arcsql.log_err('create_account: '||dbms_utility.format_error_stack);
      raise;
end;


function custom_auth (
   -- Custom authorization function registered as APEX authorization scheme.
   --
   p_username in varchar2,
   p_password in varchar2) return boolean is

   v_password                    saas_auth.password%type;
   v_stored_password             saas_auth.password%type;
   v_user_name                   saas_auth.user_name%type := lower(p_username);
   v_user_id                     saas_auth.user_id%type;
   v_uuid                        saas_auth.uuid%type;

begin
   arcsql.debug('custom_auth: user='||v_user_name);
   arcsql.count_request(p_request_key=>'saas_auth');
   raise_too_many_auth_requests;
   raise_user_name_not_found(v_user_name);

   v_user_id := get_user_id_from_user_name(p_user_name=>v_user_name);

   select password, uuid
     into v_stored_password, v_uuid
     from v_saas_auth_available_accounts
    where user_name=v_user_name;
   v_password := get_hashed_password(p_secret_string=>v_uuid||p_password);

   arcsql.debug('v_password='||v_password||', v_stored_password='||v_stored_password);
   if v_password=v_stored_password then
      arcsql.debug('custom_auth: true');
      fire_on_login_event(v_user_id);
      return true;
   end if;

   -- Things have failed if we get here.
   update saas_auth 
      set reset_pass_token=null, 
          reset_pass_expire=null,
          last_failed_login=sysdate,
          failed_login_count=failed_login_count+1,
          last_session_id=v('APP_SESSION')
    where user_name=v_user_name;
   arcsql.debug('custom_auth: false');
   return false;
   -- ToDo: May want to add fire_failed_login event here.
exception 
   when others then
      arcsql.log_err('custom_auth: '||dbms_utility.format_error_stack);
      return false;
end;


procedure post_auth is
   cursor package_names is 
   -- Looks for any procedure name called "post_auth" in any user owned
   -- packages and executes the procedure. This allows you to write your
   -- own post_auth events. Ideally it would be nice to pass the user name.
   select name from user_source 
    where lower(text) like '% post_auth;%'
      and name not in ('SAAS_AUTH_PKG')
      and type='PACKAGE';
begin
   arcsql.debug('post_auth: saas_auth_pkg');
   for n in package_names loop 
      arcsql.debug('post_auth: '||n.name||'.post_auth');
      execute immediate 'begin '||n.name||'.post_auth; end;';
   end loop;
end;


procedure send_reset_pass_token (
   -- Sends the user a security token which can be used on the password reset form.
   --
   p_email in varchar2) is 
   n number;
   v_token varchar2(120);
   v_app_name varchar2(120);
   m varchar2(1200);
begin 
   arcsql.debug('send_reset_pass_token: '||p_email);
   arcsql.count_request(p_request_key=>'saas_auth');
   raise_too_many_auth_requests;

   -- Fail quietly. Querying emails is potential malicious activity.
   if not does_email_already_exist(lower(p_email)) then 
      arcsql.log_err('send_reset_pass_token: Email address not found: '||lower(p_email));
      return;
   end if;

   while 1=1 loop 
      v_token := arcsql.str_random(6, 'an');
      select count(*) into n from v_saas_auth_available_accounts
       where reset_pass_token=v_token;
      if n=0 then 
         exit;
      end if;
   end loop;

   -- ToDo: Add a config parameter for the expiration time.
   update saas_auth 
      set reset_pass_token=v_token,
          reset_pass_expire=sysdate+nvl(saas_auth_config.password_reset_token_good_for_minutes, 15)/1440,
          last_session_id=v('APP_SESSION')
    where email=lower(p_email);

   v_app_name := apex_utl2.get_app_name;
   m := '
Hello,

You have requested to reset the password of your '||v_app_name||' account. 

Please use the security code to change your password.

'||v_token||'

Thanks,

- The '||v_app_name||' Team';
   send_email (
      p_to=>get_email_address_override(p_email),
      p_from=>arcsql_cfg.default_email_from_address,
      p_subject=>'Resetting your '||v_app_name||' account password!',
      p_body=>m);
exception 
   when others then
      arcsql.log_err('send_reset_pass_token: '||dbms_utility.format_error_stack);
      raise;
end;


procedure reset_password (
   p_token in varchar2,
   p_password in varchar2,
   p_confirm in varchar2) is 
   v_hashed_password varchar2(100);
   n number;
   v_user_name varchar2(120);
begin
   arcsql.debug('reset_password: ');
   arcsql.count_request(p_request_key=>'saas_auth');
   raise_too_many_auth_requests;

   select count(*) into n 
     from v_saas_auth_available_accounts 
    where reset_pass_token=p_token 
      and reset_pass_expire > sysdate;
   if n=0 then 
      set_error_message('Your token is either expired or invalid.');
      raise_application_error(-20001, 'Invalid password reset token.');
   end if;
   if p_password != p_confirm then 
      set_error_message('Passwords do not match.');
      raise_application_error(-20001, 'Passwords do not match.');
   end if;
   raise_password_failed_complexity_check(p_password);
   select lower(user_name) into v_user_name 
     from v_saas_auth_available_accounts 
    where reset_pass_token=p_token 
      and reset_pass_expire > sysdate;
   set_password (
      p_user_name=>v_user_name,
      p_password=>p_password);
   update saas_auth 
      set email_verified=sysdate,
          email_verification_token=null, 
          email_verification_token_expires_at=null 
    where email_verified is null 
      and user_name=v_user_name;
exception 
   when others then
      arcsql.log_err('reset_password: '||dbms_utility.format_error_stack);
      raise;
end;


function is_signed_in return boolean is 
begin 
   if lower(v('APP_USER')) not in ('guest', 'nobody') then 
      return true;
   else 
      return false;
   end if;
end;


function is_not_signed_in return boolean is 
begin 
   if lower(v('APP_USER')) in ('guest', 'nobody') then 
      return true;
   else 
      return false;
   end if;
end;


function is_admin (
   p_user_id in number) return boolean is
   x varchar2(1);
begin
   select 'Y'
    into x
    from v_saas_auth_available_accounts a
   where user_id=p_user_id
     and a.role_id=(select role_id from saas_auth_role where role_name='admin');
   return true;
exception
   when no_data_found then
      return false;
end;


procedure login_with_new_demo_account is 
   v_user varchar2(120);
   v_pass varchar2(120);
   n number;
begin 
   -- Generate a random demo user and password.
   v_user := 'Demo'||arcsql.str_random(5, 'a');
   v_pass := 'FooBar'||arcsql.str_random(5)||'@foo$';
   select count(*) into n 
     from v_saas_auth_available_accounts 
    where last_session_id=v('APP_SESSION') 
      and created >= sysdate-(.1/1440);
   if n = 0 then 
      saas_auth_pkg.create_account (
         p_user_name=>v_user,
         p_email=>v_user||'@null.com',
         p_password=>v_pass,
         p_confirm=>v_pass);
      apex_authentication.login(
         p_username => v_user,
         p_password => v_pass);
      post_auth;
   else 
      apex_error.add_error ( 
         p_message=>'Please wait 10 seconds before trying to create a new account.',
         p_display_location=>apex_error.c_inline_in_notification);
   end if;
end;


/* 
-----------------------------------------------------------------------------------
FLASH MESSAGES
-----------------------------------------------------------------------------------
*/


procedure add_flash_message (
   --
   --
   p_message in varchar2,
   p_message_type in varchar2 default 'notice',
   p_user_name in varchar2 default null,
   p_expires_at in date default null) is 
   v_user_id saas_auth.user_id%type;
   v_session_id flash_message.session_id%type;
begin 
   arcsql.debug('add_flash_message: '||p_message);
   if p_user_name is not null then 
      v_user_id := get_user_id_from_user_name(p_user_name);
   else 
      v_session_id := v('APP_SESSION');
   end if;
   insert into flash_message (
      message_type,
      message,
      user_id,
      session_id,
      expires_at) values (
      p_message_type, 
      p_message, 
      v_user_id,
      v_session_id,
      p_expires_at);
exception 
   when others then
      arcsql.log_err('add_flash_message: '||dbms_utility.format_error_stack);
      raise;
end;


function get_flash_message (
   --
   --
   p_message_type in varchar2 default 'notice',
   p_delete in boolean default false) return varchar2 is 
   cursor c_messages is 
   select * from flash_message 
    where message_type=p_message_type 
      and (user_id=saas_auth_pkg.get_user_id_from_user_name(v('APP_USER')) 
       or session_id=v('APP_SESSION'))
      and (expires_at is null  
       or expires_at > sysdate)
    order by id desc;
   r varchar2(1200);
begin 
   arcsql.debug('get_flash_messages: '||p_message_type);
   for m in c_messages loop 
      r := r || m.message;
      if p_delete then 
         delete from flash_message where id=m.id;
      end if;
      exit;
   end loop;
   return r;
exception 
   when others then
      arcsql.log_err('get_flash_message: '||dbms_utility.format_error_stack);
      raise;
end;


function get_flash_messages (
   --
   --
   p_message_type in varchar2 default 'notice',
   p_delete in boolean default false) return varchar2 is 
   cursor c_messages is 
   select * from flash_message 
    where message_type=p_message_type 
      and (user_id=saas_auth_pkg.get_user_id_from_user_name(v('APP_USER')) 
       or session_id=v('APP_SESSION'))
      and (expires_at is null  
       or expires_at > sysdate)
    order by id desc;
   r varchar2(1200);
   loop_count number := 0;
begin 
   arcsql.debug('get_flash_messages: '||p_message_type);
   for m in c_messages loop 
      loop_count := loop_count + 1;
      if loop_count = 1 then
         r := r || m.message;
      else 
         r := r || m.message ||' 
      ';
      end if;
      if p_delete then 
         delete from flash_message where id=m.id;
      end if;
   end loop;
   -- arcsql.debug('r='||r);
   return r;
exception 
   when others then
      arcsql.log_err('get_flash_message: '||dbms_utility.format_error_stack);
      raise;
end;


function flash_message_count (
   --
   --
   p_message_type in varchar2 default 'notice') return number is
   n number;
begin 
   select count(*) into n 
     from flash_message 
    where message_type = p_message_type
      and (user_id=saas_auth_pkg.get_user_id_from_user_name(v('APP_USER')) 
       or session_id=v('APP_SESSION'));
   arcsql.debug2('flash_message_count: '||n);
   return n;
exception 
   when others then
      arcsql.log_err('flash_message_count: '||dbms_utility.format_error_stack);
      raise;
end;


end;
/
