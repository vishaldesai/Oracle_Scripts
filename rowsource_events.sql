--------------------------------------------------------------------------------
--
-- File name:   rowsource_events.sql
-- Purpose:     Display top ASH time (count of ASH samples) grouped by 
--              exeution plan rowsource type and session serial/parallel
--              status.
--
--              This allows to find out if your parallel slaves are doing
--              buffered full table scan IOs.
--              
-- Author:      Tanel Poder
-- Copyright:   (c) http://blog.tanelpoder.com
--              
-- Usage:       
--     @rowsource_events.sql
--
-- Other:
--     Requires Oracle 11g+
--
--------------------------------------------------------------------------------
SELECT * FROM (
SELECT 
    sql_plan_operation||' '||sql_plan_options plan_line
  , CASE WHEN qc_session_id IS NULL THEN 'SERIAL' ELSE 'PARALLEL' END is_parallel
  , session_state
  , wait_class
  , event
  , COUNT(*) 
  , ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 1) pct
FROM 
    gv$active_session_history
WHERE
    sql_plan_operation LIKE '&1'
AND sql_plan_options   LIKE '&2'
GROUP BY
    sql_plan_operation||' '||sql_plan_options 
  , CASE WHEN qc_session_id IS NULL THEN 'SERIAL' ELSE 'PARALLEL' END
  , session_state
  , wait_class
  , event
ORDER BY COUNT(*) DESC
)
WHERE rownum <= 20
/
