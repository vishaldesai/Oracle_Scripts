set linesize 500
set pages 9999
set verify off

accept sql_id   prompt 'Enter sql_id          :'

DECLARE
  my_task_name VARCHAR2(30);
begin
my_task_name := DBMS_SQLTUNE.CREATE_TUNING_TASK(sql_id => '&sql_id',scope => 'COMPREHENSIVE',time_limit => 60,task_name => '&sql_id');
end;
/

EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => '&sql_id');

SET LONG 999999
SET PAGESIZE 1000
SET LINESIZE 500
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('&sql_id') from dual;

exec DBMS_SQLTUNE.DROP_TUNING_TASK('&sql_id');

undefine sql_id


