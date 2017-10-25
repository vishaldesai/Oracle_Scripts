set linesize 500
set pages 9999
set verify off

accept bsnap prompt 'Enter begin snap :'
accept esnap prompt 'Enter end snap   :'
accept sql_id   prompt 'Enter sql_id          :'

DECLARE
l_sql_tune_task_id  VARCHAR2(100);
BEGIN
l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
begin_snap  => &bsnap,
end_snap    => &esnap,
sql_id      => '&sql_id',
scope       => DBMS_SQLTUNE.scope_comprehensive,
time_limit  => 60,
task_name   => '&sql_id',
description => 'Tuning task for statement in AWR.');
DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/

EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => '&sql_id');

SET LONG 999999
SET PAGESIZE 1000
SET LINESIZE 500
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('&sql_id') from dual;

exec DBMS_SQLTUNE.DROP_TUNING_TASK('&sql_id');

undefine sql_id
undefine bsnap
undefine esnap



