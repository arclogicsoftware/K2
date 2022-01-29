
-- uninstall: exec drop_package('saas_app_admin');
create or replace package saas_app_admin as 
    procedure run_these_admin_tasks_every_15_minutes;
end;
/
