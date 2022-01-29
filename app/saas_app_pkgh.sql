-- uninstall: exec drop_package('saas_app');
create or replace package saas_app as 

   procedure on_create_account (
      p_user_id in number);

   procedure on_login (
      p_user_id in number);

end;
/
