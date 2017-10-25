set linesize 500
set pages 9999
set verify

accept sql_handle  prompt 'Enter sql_handle      :'
accept plan_name   prompt 'Enter plan_name       :'

select * from table(dbms_xplan.display_sql_plan_baseline(sql_handle=>'&sql_handle',plan_name=>'&plan_name', format=>'ADVANCED'));

undefine sql_handle
undefine plan_name