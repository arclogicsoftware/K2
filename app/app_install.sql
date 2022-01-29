
/*

Contains configuration for the app.

*/

@../config/secret_saas_app_config.sql 

/*
schema.sql - Contains most of the DDL for you application. 

This file should be idempotent! It should always produce the correct
schema regardless of the state of the schema it is running against.
*/

@schema.sql

/*
SAAS_APP - This package contains application code.

Of course you can create any and all packages you want here. You are in 
control of this file.
*/

@saas_app_pkgh.sql
@saas_app_pkgb.sql

/*
SAAS_APP_ADMIN - Contains administrative procededures.

I recommend using a package like this to contain adminstrative procedures.
Later you can hook these into the UI.
*/

@saas_app_admin_pkgh.sql 
@saas_app_admin_pkgb.sql

/*
saas_auth_events.sql - Override default procedures in SAAS_AUTH with your custom code.

These events allow you to tie in things like a LOGIN to your application's code.
*/

@saas_auth_events.sql

/*
user.sql - This is meant to contain any users you generate by default.
*/

@users.sql

/*
send_email.sql - Override the default send_email procedure with your code.

This enables you to hook email send code to the email service provider you are using.
*/

@send_email.sql

/*

Anything you want to run at the end of the install/upgrade. Can be patching code.

*/

@saas_app_post_install.sql

/*
Create the contact groups for this application.
*/

@arcsql_contact_groups.sql

commit;
