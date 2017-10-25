set verify off
set linesize 500
set pages 1000
accept sql_id      prompt 'Please enter the sql_id                  :'
accept child_no    prompt 'Please enter the child_no		  	  :'
--SELECT * FROM TABLE(dbms_xplan.display_cursor('&sql_id',&child_no,'advanced'));
SELECT * FROM TABLE(dbms_xplan.display_cursor('&sql_id',&child_no,'ADVANCED'));

set feed off
set echo off
column sql_plan_opearation format a15
column sql_plan_options format a15
column event format a40
select * from 
(select SQL_PLAN_LINE_ID,SQL_PLAN_OPERATION,sql_plan_options,seq#,event from 
v$active_session_history where sql_id='&sql_id' order by sample_id desc)
where rownum <=5;

set head off
select 'allstats = iostats + memstats' from dual union all
select 'iostats - controls display of iostats' from dual union all
select 'last - per default cummulative stats are displayed, with this only last execution stats are shows' from dual union all
select 'memstats - display pga stats' from dual union all
select 'runstats_last - same as iostats last - 10gR1 only' from dual union all
select 'runstats_tot - same as iostats - 10gR1 only' from dual;

set heading on
set feed on
