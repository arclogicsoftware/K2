
## ETHAN'S ORACLE APEX APP DEVELOPMENT GUIDE

### Assumptions

You have admin access to an Oracle database and an Oracle APEX instance.

### Email

There are two methods for sending mail, Oracle APEX native email and SendGrid. Other options will work as well. To use these options, replace the body of the "send_email" procedure (part of ARCSQL below) to your email interface/procedure.

#### Oracle APEX Email (optional)

Use the following links to configure native Oracle APEX email. You will create an approved sender during this process. This sender will be used in the "From" address when sending mail. 

[Configure an SPF record](https://docs.oracle.com/en-us/iaas/Content/Email/Tasks/configurespf.htm) for the domain you will be using in the "From" address.

[Sending Email from your Oracle APEX App on Autonomous Database](https://blogs.oracle.com/apex/post/sending-email-from-your-oracle-apex-app-on-autonomous-database)

> I have set up an SPF record for arclogicsoftware.com. I have also added  foo@bar.com as an approved sender. The commands outlined in the article to register SMTP credentials with Oracle APEX have been run.

#### SendGrid Email (optional)

A alternative to Oracle APEX for email is [SendGrid](https://sendgrid.com/).  My SendGrid library is [here](https://github.com/ethanpost/sendgrid). Better instructions are a **TO DO**.

### Workspace/App User

Create a new workspace and associate a new user with the the workspace.
> I created a workspace called "ion" and a new user called "ion".  I also connected as the new user in SQL*Developer.

### Project Folder

Create the root folder for a project.
```
# For example (example project "ion"). 
# We will call this our project folder.
C:\temp\dev_root_project_ion
```

Clone the required repositories to your project folder.

#### ARCSQL

[ARCSQL](https://github.com/ethanpost/arcsql)
```
C:\temp\dev_root_project_ion\arcsql
```
Create a new branch of ARCSQL for your project. I will name mine "ion".
```
# Remove tracking for arcsql_user_setting.sql (optional).
# https://gist.github.com/tsrivishnu/a2f3adbbca9fcad5f3597af301ad1abb
git rm --cached arcsql_user_setting.sql
```
> Why? The arcsql_user_setting.sql file may contain data you need to keep secure. You will not want updates to this file synced to a public repository.

Follow [these instructions](https://e-t-h-a-n.com/how-to-install-arcsql) to install ARCSQL into the application user's schema. You will not need to create the user per the instructions since the user has already been created. You will just need to grant the required permissions.

#### SASS AUTH

[SASS AUTH](https://github.com/ethanpost/saas_auth)
```
C:\temp\dev_root_project_ion\saas_auth
```
Create a new branch of SAAS AUTH for your project. I named mine "ion".

Follow [these instructions](https://e-t-h-a-n.com/how-to-configure-apex-to-use-my-custom-login-page) to install SAAS AUTH into the application user schema.

#### SASS STARTER PACK

[SASS STARTER PACK](https://github.com/arclogicsoftware/saas_starter_pack)
```
C:\temp\dev_root_project_ion\saas_starter_pack
```
Rename the saas_starter_pack folder shown above. This folder will contain the bulk of the code for your application. This is referred to as the "application folder".
```
C:\temp\dev_root_project_ion\ion
```
Remove the .git folder and create a new Git repo from ```C:\temp\dev_root_project_ion \ion```. 
 

