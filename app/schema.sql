
-- uninstall: exec drop_sequence('seq_example_id');
exec create_sequence('seq_example_id');

-- uninstall: exec drop_table('starter_pack_example');
begin
   if not does_table_exist('starter_pack_example') then 
      execute_sql('
      create table starter_pack_example (
      example_id number default seq_example_id.nextval not null
      )', false);
      execute_sql('alter table starter_pack_example add constraint pk_starter_pack_example primary key (example_id)', false);
   end if;
end;
/


-- uninstall: exec drop_view('starter_pack_example_v');
create or replace view starter_pack_example_v as (
select *
  from starter_pack_example);


