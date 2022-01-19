create or replace package apex_utl2 as

    function get_current_theme_id_for_app return number;
    function get_app_name return varchar2;
    function get_app_id return number;
    function get_app_alias return varchar2;
    procedure change_theme_for_user (p_theme_name in varchar2);

end;
/
