create or replace package apex_utl2 as

    function get_link_to_page_alias (
        p_page_alias in varchar2,
        p_relative_link boolean default true) return varchar2;

    function get_current_theme_id_for_app return number;
    function get_app_name return varchar2;
    function get_app_id return number;
    function get_app_alias return varchar2;
    procedure change_theme_for_user (p_theme_name in varchar2);
    function get_ip return varchar2;
    function get_query_string return varchar2;

end;
/
