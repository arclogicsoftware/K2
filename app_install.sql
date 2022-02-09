

/*
Pre-load all configs to resolve any dependency issues.
*/
@config/secret_arcsql_cfg.sql
@config/secret_apex_utl2_config.sql 
@config/secret_saas_auth_config.sql 
@config/secret_saas_app_config.sql


/*
Arcsql needs to be installed first. Make sure you have run the script
to make the grants from admin to the current user.
*/

@lib/arcsql/app_install.sql

/*
Install APEX_UTL2 which contain misc APEX related snippets.
*/

@lib/apex_utl2/app_install.sql

/*
Install SAAS_AUTH which handles users/roles/password reset. This library
is tied to a login page and a email verification page.
*/

@lib/saas_auth/app_install.sql 

/*
Install you application's code.
*/

@app/app_install.sql


/*
Advance the start value of any identity sequences if a conflict is anticipated.
*/

exec fix_identity_sequences;


commit;
