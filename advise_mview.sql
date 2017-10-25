accept user_name      prompt 'Please enter parsing username  :'
accept sql_text       prompt 'Please enter sql_text ('''' for literals) :'

exec dbms_advisor.delete_task('DemoTask1');
exec dbms_advisor.delete_sqlwkld('DemoWorkload1');

declare
  v_workload varchar2(100) := 'DemoWorkload1';
  v_task     varchar2(100) := 'DemoTask1';
begin

  dbms_advisor.create_task(dbms_advisor.SQLACCESS_ADVISOR,'DemoTask1',v_task);

  dbms_advisor.set_task_parameter('DemoTask1', 'ANALYSIS_SCOPE', 'ALL');
  dbms_advisor.set_task_parameter('DemoTask1', 'MODE', 'COMPREHENSIVE');

  DBMS_ADVISOR.CREATE_SQLWKLD(v_workload, 'Demo Workload');
  dbms_advisor.add_sqlwkld_statement(v_workload,NULL,NULL,username   => '&user_name',sql_text   => '&sql_text');
  dbms_advisor.add_sqlwkld_ref('DemoTask1', 'DemoWorkload1');
  dbms_advisor.execute_task('DemoTask1');
end;
/

SET LONG 100000
SET PAGESIZE 50000
SELECT DBMS_ADVISOR.get_task_script('DemoTask1') AS script
FROM   dual;
SET PAGESIZE 24
