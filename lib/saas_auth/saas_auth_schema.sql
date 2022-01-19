

-- uninstall: drop table saas_auth_role cascade constraints purge;
begin
   if not does_table_exist('saas_auth_role') then 
      execute_sql('
      create table saas_auth_role (
      role_id number not null,  
      role_name varchar2(120) not null
      )', false);
      execute_sql('alter table saas_auth_role add constraint pk_saas_auth_role primary key (role_id)', false);
      execute_sql('create unique index saas_auth_role_1 on saas_auth_role(role_name)', false);
   end if;
end;
/

begin 
   update saas_auth_role set role_id=1 where role_id=1;
   if sql%rowcount = 0 then 
      insert into saas_auth_role (
         role_id,
         role_name) values (
         1,
         'user');
   end if;
   update saas_auth_role set role_id=2 where role_id=2;
   if sql%rowcount = 0 then 
      insert into saas_auth_role (
         role_id,
         role_name) values (
         2,
         'admin');
   end if;
end;
/

-- uninstall: drop table saas_auth cascade constraints purge;
begin
   if not does_table_exist('saas_auth') then 
      execute_sql('
      create table saas_auth (
      user_id number generated by default on null as identity minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 start with 1 cache 20 noorder nocycle nokeep noscale not null,
      role_id number,
      user_name varchar2(120) not null,
      email varchar2(120) not null,                               
      uuid varchar2(120) default sys_guid(),                      -- Used as an additional salt to hash pass.
      email_verification_token varchar2(12) default null,         -- Token used for email verification.
      email_verification_token_expires_at date default null,      -- A token is only good for so long.
      email_verified date default null,                           -- When the email was verified.
      email_old varchar2(120) default null,
      -- App should check here to see if any custom init code needs to be run.
      app_init date default null,
      password varchar2(120) not null,
      last_session_id varchar2(120) default null,
      last_login date default null,
      login_count number default 0,
      last_failed_login date default null,
      failed_login_count number default 0,
      reset_pass_token varchar2(120),
      reset_pass_expire date default null,
      -- active, locked, inactive, delete
      account_status varchar2(12) default ''
      is_test_user varchar2(1) default ''n'',
      created date not null,
      created_by varchar2(120) not null,
      updated date not null,
      updated_by varchar2(120) not null,
      -- This is set each time the user logs in by detecting the current value from the browser.
      timezone_name varchar2(120) default null,
      timezone_offset varchar2(12) default null
      )', false);
      execute_sql('alter table saas_auth add constraint pk_saas_auth primary key (user_id)', false);
      execute_sql('create index saas_auth_2 on saas_auth(role_id)', false);
      execute_sql('alter table saas_auth add constraint saas_auth_fk_role_id foreign key (role_id) references saas_auth_role (role_id) on delete cascade', false);
   end if;
   if not does_column_exist('saas_auth', 'email_verification_token') then 
      execute_sql('
         alter table saas_auth add (email_verification_token varchar2(12) default null)', false);
   end if;
   if not does_column_exist('saas_auth', 'email_verification_token_expires_at') then 
      execute_sql('
         alter table saas_auth add (email_verification_token_expires_at date default null)', false);
   end if;
   if not does_column_exist('saas_auth', 'email_verified') then 
      execute_sql('
         alter table saas_auth add (email_verified date default null)', false);
   end if;
   if not does_column_exist('saas_auth', 'email_old') then 
      execute_sql('
         alter table saas_auth add (email_old varchar2(120) default null)', false);
   end if;
   if not does_column_exist('saas_auth', 'uuid') then 
      execute_sql('
         alter table saas_auth add (uuid varchar2(120) default sys_guid())', false);
   end if;
   if not does_column_exist('saas_auth', 'account_status') then 
      execute_sql('
         alter table saas_auth add (account_status varchar2(12) default ''active'')', false);
   end if;
end;
/


create or replace view v_saas_auth_available_accounts as
   select * from saas_auth where account_status in ('active', 'inactive')
      and account_status not in ('delete', 'locked');


create or replace trigger saas_auth_trig
   before insert or update
   on saas_auth
   for each row
begin
   if inserting then
      :new.created := sysdate;
      :new.created_by := nvl(sys_context('apex$session','app_user'), user);
      if :new.user_name is null then 
         :new.user_name := lower(:new.email);
      end if;
   end if;
   :new.updated := sysdate;
   :new.updated_by := nvl(sys_context('apex$session','app_user'), user);
   :new.email := lower(:new.email);
end;
/


-- uninstall: drop table flash_message cascade constraints purge;
begin
   if not does_table_exist('flash_message') then 
      execute_sql('
      create table flash_message (
         id number generated by default on null as identity cache 20 noorder nocycle nokeep noscale not null,
         message_type varchar2(120) default ''notice'' not null,
         user_id number default null,
         session_id number default null,
         message varchar2(1200),
         created_at date default sysdate,
         expires_at date default null
         )', false);
      execute_sql('alter table flash_message add constraint pk_flash_message_id primary key (id)', false);
      execute_sql('create index flash_message_1 on flash_message(user_id)', false);
      execute_sql('create index flash_message_2 on flash_message(message_type)', false);
      execute_sql('create index flash_message_3 on flash_message(session_id)', false);
      execute_sql('alter table flash_message add constraint flash_message_fk_user_id foreign key (user_id) references saas_auth (user_id) on delete cascade', false);
   end if;
end;
/


-- uninstall: drop view user_flash_message;
create or replace view user_flash_message as (
    select * from flash_message
     where (user_id=saas_auth_pkg.get_user_id_from_user_name(v('APP_USER')) 
        or session_id=v('APP_SESSION'))
       and expires_at<=sysdate);