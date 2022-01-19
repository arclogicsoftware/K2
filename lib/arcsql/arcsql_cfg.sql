
create or replace package arcsql_cfg as 
   email_from_address varchar2(120) := 'foo@bar.com';
   disable_email boolean := false;
end;
/
