

/*
Arcsql needs to be installed first. Make sure you have run the script
to make the grants from admin to the current user.
*/

@lib/arcsql/arcsql_install.sql
@config/secret_arcsql_cfg.sql


/*
Install APEX_UTL2 which contain misc APEX related snippets.
*/

@lib/apex_utl2/apex_utl2_install.sql


/*
Install SAAS_AUTH which handles users/roles/password reset. This library
is tied to a login page and a email verification page.
*/

@lib/saas_auth/saas_auth_install.sql 


/*
Your SAAS_AUTH config settings.
*/

@config/secret_saas_auth_config.sql


/*
Your K2 app config settings.
*/

@config/secret_app_config.sql

/*
Install you application's code.
*/

@app/saas_app_install.sql


commit;
