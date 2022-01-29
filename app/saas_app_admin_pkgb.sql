

create or replace package body saas_app_admin as 


procedure run_these_admin_tasks_every_15_minutes is 
   -- Called every 15 minutes from an APEX automation.
   --
begin 
   arcsql.log('run_these_admin_tasks_every_15_minutes: ');
   -- Think a commit needs to be here since called from scheduled task.
   commit;
exception 
   when others then
      arcsql.log_err('run_these_admin_tasks_every_15_minutes: '||dbms_utility.format_error_stack);
      raise;
end;


end;
/
