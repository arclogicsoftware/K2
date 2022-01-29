-- uninstall: drop package apex_utl2;
create or replace package body apex_utl2 as


function get_link_to_page_alias (
    p_page_alias in varchar2,
    p_relative_link boolean default true) return varchar2 is 
begin 

    return '/ords/f?p='||get_app_id||':'||p_page_alias;
    -- '||v_protocol||'://'||v_domain||'/ords/f?p='||v_app_id||':verify:::::SAAS_AUTH_EMAIL,SAAS_AUTH_TOKEN:'||lower(v_saas_auth.email)||','||t||'

end;


function get_app_name return varchar2 is 
    -- Return the name of the current application.
    --
begin 
    -- https://jeffkemponoracle.com/tag/apex_application/
    return trim(apex_application.g_flow_name);
end;


function get_app_id return number is 
    --
    --
begin 
    return apex_application.g_flow_id;
end;


function get_app_alias return varchar2 is 
    -- Return application alias.
    --
begin 
    return trim(apex_application.g_flow_alias);
end;


function get_current_theme_id_for_app return number is 
    -- Return the id for the calling app's 
    --
begin 
    return to_number(trim(apex_application.g_flow_theme_id));
end;


function get_style_id_for_theme_name (
    -- Returns numeric style id for a specifc theme name.
    --
    p_theme_name in varchar2) return number is 
    n number;
begin 
    select theme_style_id into n 
      from apex_application_theme_styles 
     where application_name=apex_utl2.get_app_name 
       and name=p_theme_name;
    return n;
end;


procedure change_theme_for_user (
    -- Changes the theme of APP_USER.
    --
    p_theme_name in varchar2) is 
begin
    arcsql.debug('change_theme_for_user: user='||v('APP_USER')||', theme='||p_theme_name||', app_id='||get_app_id);
    apex_theme.set_session_style (
        p_theme_number => get_current_theme_id_for_app,
        p_name => p_theme_name
        );
    apex_theme.set_user_style (
        p_application_id => get_app_id,
        p_user           => v('APP_USER'),
        p_theme_number   => get_current_theme_id_for_app,
        p_id             => get_style_id_for_theme_name(p_theme_name)
        );
exception 
    when others then
        arcsql.log_err('change_theme_for_user: '||dbms_utility.format_error_stack);
        raise;
end;


function get_ip return varchar2 is 
begin 
    return owa_util.get_cgi_env('REMOTE_ADDR');
end;


function get_query_string return varchar2 is 
begin 
    -- https://www.oracle-and-apex.com/authenticate-apex-via-token/
    return owa_util.get_cgi_env('QUERY_STRING');
end;


end;
/
