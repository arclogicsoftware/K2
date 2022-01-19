
-- uninstall: drop package saas_auth_pkg;
create or replace package saas_auth_pkg as

   procedure delete_user(
      p_user_name in varchar2);

   function is_email_verification_required (
      p_email in varchar2) return boolean;

   procedure send_email_verification_code_to (
      p_user_name in varchar2);

   procedure verify_email_using_token (
      p_email in varchar2,
      p_auth_token in varchar2);
  
   -- Add this to your authentication scheme. Calls all packaged procedures with name 'post_auth'.
   procedure post_auth;

   procedure set_timezone_name(
      p_user_name in varchar2,
      p_timezone_name in varchar2);

   procedure add_user (
      p_user_name in varchar2,
      p_email in varchar2,
      p_password in varchar2,
      p_is_test_user in boolean default false);
      
   procedure add_test_user (
      p_user_name in varchar2,
      p_email in varchar2 default null);

   procedure create_account (
      p_user_name in varchar2,
      p_email in varchar2,
      p_password in varchar2,
      p_confirm in varchar2);

   function custom_auth (
      p_username in varchar2,
      p_password in varchar2) return boolean;

   procedure send_reset_pass_token (
      p_email in varchar2);

   procedure reset_password (
      p_token in varchar2,
      p_password in varchar2,
      p_confirm in varchar2);

   procedure set_password (
      p_user_name in varchar2,
      p_password in varchar2);
      
   function does_email_already_exist (
      p_email in varchar2) return boolean;

   -- This is set up in APEX as a custom authorization.
   function is_signed_in return boolean;
   
   -- This is set up in APEX as a custom authorization.
   function is_not_signed_in return boolean;

   function is_admin (
      p_user_id in number) return boolean;

   procedure login_with_new_demo_account;

   function get_user_id_from_user_name (
      p_user_name in varchar2 default v('APP_USER')) return number;

   function get_user_id_from_email (
      p_email in varchar2) return number;

   function get_user_name (p_user_id in number) return varchar2;

   function ui_branch_to_main_after_auth (
      p_email in varchar2) return boolean;

   /* 
    -----------------------------------------------------------------------------------
    FLASH MESSAGES
    -----------------------------------------------------------------------------------
    */

    procedure add_flash_message (
        p_message in varchar2,
        p_message_type in varchar2 default 'notice',
        p_user_name in varchar2 default null,
        p_expires_at in date default null);

    function get_flash_message (
        p_message_type in varchar2 default 'notice',
        p_delete in boolean default false) return varchar2;

    function get_flash_messages (
        p_message_type in varchar2 default 'notice',
        p_delete in boolean default false) return varchar2;

    function flash_message_count (
        p_message_type in varchar2 default 'notice') return number;

end;
/



