------------------------------------------------------------------------------------------------------------------------
--
-- File name:   asqlmon.sql (v1.0)
--
-- Purpose:     Report SQL-monitoring-style drill-down into where in an execution plan the execution time is spent
--
-- Author:      Tanel Poder
--
-- Copyright:   (c) http://blog.tanelpoder.com - All rights reserved.
--
-- Disclaimer:  This script is provided "as is", no warranties nor guarantees are
--              made. Use at your own risk :)
--              
-- Usage:       @asqlmon <sqlid> <child#>
--
-- Notes:       This script runs on Oracle 11g+ and you should have the
--              Diagnostics and Tuning pack licenses for using it as it queries
--              some separately licensed views.
--
------------------------------------------------------------------------------------------------------------------------

COL asqlmon_operation FOR a100
COL asqlmon_predicates FOR a170 word_wrap
COL options   FOR a30
set linesize 6000
COL asqlmon_plan_hash_value HEAD PLAN_HASH_VALUE
COL asqlmon_sql_id          HEAD SQL_ID  NOPRINT
COL asqlmon_sql_child       HEAD CHILD#  NOPRINT
COL asqlmon_sample_time     HEAD SAMPLE_HOUR
COL projection FOR A550

COL pct_child HEAD "Activity %" FOR A8
COL pct_child_vis HEAD "Visual" FOR A12

COL asqlmon_id        HEAD "Line ID" FOR 9999
COL asqlmon_parent_id HEAD "Parent"  FOR 9999


BREAK ON asqlmon_plan_hash_value SKIP 1 ON asqlmon_sql_id SKIP 1 ON asqlmon_sql_child SKIP 1 ON asqlmon_sample_time SKIP 1 DUP ON asqlmon_operation

WITH  sample_times AS (
    select * from dual
), 
sq AS (
SELECT
  --  to_char(ash.sample_time, 'YYYY-MM-DD HH24') sample_time
    count(*) samples
  , ash.sql_id
  , ash.sql_child_number
  , ash.sql_plan_hash_value
  , ash.sql_plan_line_id
  , ash.sql_plan_operation
  , ash.sql_plan_options
  , ash.session_state
  , ash.event
  , AVG(ash.p3) avg_p3
FROM
    gv$active_session_history ash
WHERE
    1=1
--AND ash.session_id = 8 AND ash.session_serial# =     35019
AND ash.sql_id LIKE '&1'
AND ash.sql_child_number LIKE '%&2%'
GROUP BY
  --to_char(ash.sample_time, 'YYYY-MM-DD HH24')
    ash.sql_id
  , ash.sql_child_number
  , ash.sql_plan_hash_value
  , ash.sql_plan_line_id
  , ash.sql_plan_operation
  , ash.sql_plan_options
  , ash.session_state
  , ash.event
)
SELECT
    plan.sql_id            asqlmon_sql_id
  , plan.child_number      asqlmon_sql_child
--  , plan.plan_hash_value asqlmon_plan_hash_value
  , sq.samples seconds
  , LPAD(TO_CHAR(ROUND(RATIO_TO_REPORT(sq.samples) OVER (PARTITION BY sq.sql_id, sq.sql_plan_hash_value) * 100, 1), 999.9)||' %',8) pct_child
  , '|'||RPAD( NVL( LPAD('#', ROUND(RATIO_TO_REPORT(sq.samples) OVER (PARTITION BY sq.sql_id, sq.sql_plan_hash_value) * 10), '#'), ' '), 10,' ')||'|' pct_child_vis
  --, sq.sample_time         asqlmon_sample_time
  --, LPAD(plan.id,4)||CASE WHEN parent_id IS NULL THEN '    ' ELSE ' <- ' END||LPAD(plan.parent_id,4) asqlmon_plan_id
  , plan.id asqlmon_id
  , plan.parent_id asqlmon_parent_id
  , LPAD(' ', depth) || plan.operation ||' '|| plan.options || NVL2(plan.object_name, ' ['||plan.object_name ||']', null) asqlmon_operation
  , sq.session_state
  , sq.event
  , sq.avg_p3 
  , plan.object_alias || CASE WHEN plan.qblock_name IS NOT NULL THEN ' ['|| plan.qblock_name || ']' END obj_alias_qbc_name
  , CASE WHEN plan.access_predicates IS NOT NULL THEN '[A:] '|| plan.access_predicates END || CASE WHEN plan.filter_predicates IS NOT NULL THEN ' [F:]' || plan.filter_predicates END asqlmon_predicates
  , plan.projection
FROM
    v$sql_plan plan
  , sq
WHERE
    1=1
AND sq.sql_id(+) = plan.sql_id
AND sq.sql_child_number(+) = plan.child_number
AND sq.sql_plan_line_id(+) = plan.id
AND sq.sql_plan_hash_value(+) = plan.plan_hash_value
AND plan.sql_id LIKE '&1'
AND plan.child_number LIKE '%&2%'
ORDER BY
  --sq.sample_time
    plan.child_number
  , plan.plan_hash_value
  , plan.id
/

/*
http://blog.dbi-services.com/execution-plan-with-ash/

with
 "sql" as (select SQL_ID,CHILD_NUMBER,PLAN_HASH_VALUE,'' FORMAT from v$sql where sql_id='&1'),
 "ash" as (
          select sql_id,sql_plan_line_id,child_number,sql_plan_hash_value
          ,round(count(*)/"samples",2) load
          ,nvl(round(sum(case when session_state='ON CPU' then 1 end)/"samples",2),0) load_cpu
          ,nvl(round(sum(case when session_state='WAITING' and wait_class='User I/O' then 1 end)/"samples",2),0) load_io
          from "sql" join
          (
            select sql_id,sql_plan_line_id,sql_child_number child_number,sql_plan_hash_value,session_state,wait_class,count(*) over (partition by sql_id,sql_plan_hash_value) "samples"
            FROM V$ACTIVE_SESSION_HISTORY
          ) using(sql_id,child_number) group by sql_id,sql_plan_line_id,child_number,sql_plan_hash_value,"samples"
 ),
 "plan" as (
        -- get dbms_xplan result
        select
         sql_id,child_number,n,plan_table_output
         -- get plan line id from plan_table output
         ,case when regexp_like (plan_table_output,'^[|][*]? *([0-9]+) *[|].*[|]$') then
          regexp_replace(plan_table_output,'^[|][*]? *([0-9]+) *[|].*[|]$','\1')
          END SQL_PLAN_LINE_ID
         from (select rownum n,plan_table_output,SQL_ID,CHILD_NUMBER from "sql", table(dbms_xplan.display_cursor("sql".SQL_ID,"sql".CHILD_NUMBER,"sql".FORMAT)))
 )
select PLAN_TABLE_OUTPUT||CASE
       -- ASH load to be displayed
       WHEN LOAD >0 THEN TO_CHAR(100*LOAD,'999')||'% (' || TO_CHAR(100*LOAD_CPU,'999')||'% CPU'|| TO_CHAR(100*LOAD_IO,'999')||'% I/O)'
       -- header
       WHEN REGEXP_LIKE (PLAN_TABLE_OUTPUT,'^[|] *Id *[|]')  THEN ' %ASH SAMPLES'
       end plan_table_output
from "plan" left outer join "ash" using(sql_id,child_number,sql_plan_line_id) order by sql_id,child_number,n
*/
