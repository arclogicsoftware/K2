-- uninstall: drop view user_flash_message;
create or replace view user_flash_message as (
    select * from flash_message
     where (user_id=saas_auth_pkg.get_user_id_from_user_name(v('APP_USER')) 
        or session_id=v('APP_SESSION'))
       and expires_at<=sysdate);