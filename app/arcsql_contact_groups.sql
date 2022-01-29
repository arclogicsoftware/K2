

begin 
   arcsql.create_contact_group('app_admins');
   arcsql.add_contact_to_contact_group(
      p_group_name=>'app_admins',
      p_email_address => '----',
      p_sms_address => '----');
end;
/
