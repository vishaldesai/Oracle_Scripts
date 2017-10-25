set verify off
set linesize 500
set pages 1000
accept sql_handle      prompt 'Please enter the sql_handle                  :'
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE('&sql_handle'));