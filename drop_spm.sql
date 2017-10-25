set linesize 500
set pages 9999
set verify

accept sql_search  prompt 'Enter SQL search string :'

set long 9999999
SELECT sql_handle, plan_name, enabled, accepted ,sql_text
FROM   dba_sql_plan_baselines
WHERE  sql_text like '%&sql_search%';


accept sql_handle  prompt 'Enter sql_handle      :'
accept plan_name   prompt 'Enter plan_name       :'


SET SERVEROUTPUT ON
DECLARE
  l_plans_dropped  PLS_INTEGER;
BEGIN
  l_plans_dropped := DBMS_SPM.drop_sql_plan_baseline (
    sql_handle => '&sql_handle',
    plan_name  => '&plan_name');
    
  DBMS_OUTPUT.put_line(l_plans_dropped);
END;
/

undefine sql_search