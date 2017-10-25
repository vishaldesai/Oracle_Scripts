--prompt eXplain with Profile: Running DBMS_SQLTUNE.REPORT_SQL_MONITOR for SID .... (11.2+)
accept sid prompt 'Enter sid: '
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

spool tmp\xprof_i_inst.html
SELECT
	DBMS_SQLTUNE.REPORT_SQL_MONITOR(   
	   session_id=>'&sid',  
	   report_level=>'ALL',
	   type => 'ACTIVE') as report   
FROM dual
/

SET HEADING ON
spool off

host start tmp\xprof_i_inst.html
set termout on heading on

