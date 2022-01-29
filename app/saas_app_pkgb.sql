create or replace package body saas_app as 


procedure on_create_account (
   --
   --
   p_user_id in number) is 
begin 
   arcsql.log('saas_app.on_create_account: user_id='||p_user_id);
end;


procedure on_login (
   --
   --
   p_user_id in number) is 
begin 
   arcsql.log('saas_app.on_login: user_id='||p_user_id);
end;

end;
/
