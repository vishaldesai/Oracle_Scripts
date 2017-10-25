accept sql_id prompt 'Enter sql_id: '
set termout off heading off

SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET LINESIZE 1000
SET PAGESIZE 0
SET TRIM ON
SET TRIMSPOOL ON
SET ECHO OFF
SET FEEDBACK OFF
set feed off
set prompt off
set termout off heading off
set verify off

spool tmp\xprof_i_inst1.html

select dbms_sqltune.report_sql_detail('&sql_id') from dual;
/

SET HEADING ON
spool off

host start tmp\xprof_i_inst1.html
set termout on heading on