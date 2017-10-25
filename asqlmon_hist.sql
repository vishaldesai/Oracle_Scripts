------------------------------------------------------------------------------------------------------------------------
--
-- File name:   asqlmon_hist.sql (v1.0)
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
-- Usage:       @asqlmon_hist <sqlid> <phv> <Begin snap> <End snap>
--
-- Notes:       This script runs on Oracle 11g+ and you should have the
--              Diagnostics and Tuning pack licenses for using it as it queries
--              some separately licensed views.
--
------------------------------------------------------------------------------------------------------------------------
set linesize 500
set pages 9999
set verify off
COL asqlmon_operation FOR a100
COL session_state FOR a15
COL EVENT FOR a30
COL AVG_P3 FOR 999999999.99
COL asqlmon_predicates FOR a100 word_wrap
COL options   FOR a30

COL asqlmon_plan_hash_value HEAD PLAN_HASH_VALUE
COL asqlmon_sql_id          HEAD SQL_ID  NOPRINT
COL asqlmon_sql_child       HEAD CHILD#  NOPRINT
COL asqlmon_sample_time     HEAD SAMPLE_HOUR
COL projection FOR A520

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
  , sum(ash.time_waited) sum_time_waited
FROM
    dba_hist_active_sess_history ash
WHERE
    1=1
--AND ash.session_id = 8 AND ash.session_serial# =     35019
AND ash.sql_id = '&1'
AND ash.sql_plan_hash_value = &2
AND ash.snap_id >= &3 and ash.snap_id<=&4
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
--  , plan.plan_hash_value asqlmon_plan_hash_value
  , sq.samples seconds
  , LPAD(TO_CHAR(ROUND(RATIO_TO_REPORT(sq.samples) OVER (PARTITION BY sq.sql_id, sq.sql_plan_hash_value) * 100, 1), 999.9)||' %',8) pct_child
  , '|'||RPAD( NVL( LPAD('#', ROUND(RATIO_TO_REPORT(sq.samples) OVER (PARTITION BY sq.sql_id, sq.sql_plan_hash_value) * 10), '#'), ' '), 10,' ')||'|' pct_child_vis
    , sq.session_state
  , sq.event
  , sq.sum_time_waited
  --, sq.avg_p3 
  --, sq.sample_time         asqlmon_sample_time
  --, LPAD(plan.id,4)||CASE WHEN parent_id IS NULL THEN '    ' ELSE ' <- ' END||LPAD(plan.parent_id,4) asqlmon_plan_id
  , plan.id asqlmon_id
  , nvl(plan.parent_id,'-1') asqlmon_parent_id
  , LPAD(' ', depth) || plan.operation ||' '|| plan.options || NVL2(plan.object_name, ' ['||plan.object_name ||']', null) asqlmon_operation
  , plan.object_alias || CASE WHEN plan.qblock_name IS NOT NULL THEN ' ['|| plan.qblock_name || ']' END obj_alias_qbc_name
FROM
    dba_hist_sql_plan plan
  , sq
WHERE
    1=1
AND sq.sql_id(+) = plan.sql_id
AND sq.sql_plan_line_id(+) = plan.id
AND sq.sql_plan_hash_value(+) = plan.plan_hash_value
AND plan.sql_id = '&1'
ORDER BY
    plan.plan_hash_value
  , plan.id
/
