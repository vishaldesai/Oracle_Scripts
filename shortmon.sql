-- arguments event systimestamp - interval '15' systimestamp
COL wait_class FOR a15
COL event FOR a35
COL time_range  HEAD "WAIT_TIM_BUCKET_US+" FOR A26 JUST RIGHT
COL avg_wait_us HEAD "AVG_WAIT_IN_BKT_US" FOR 9,999,999,999
COL pct_event FOR a9
COL pct_total FOR a9

BREAK ON event SKIP 1 DUPLICATES

-- TODO: ignore latest sample (0 waits)

SELECT /* (hint disabled) LEADING(@"SEL$4" "S"@"SEL$4" "A"@"SEL$4") USE_HASH(@"SEL$4" "A"@"SEL$4") */
    session_state state
  , wait_class
  , event
  , ROUND(AVG(time_waited)) avg_wait_us
  , LPAD(REPLACE(TO_CHAR(POWER(2,TRUNC(LOG(2,CASE WHEN time_waited < 1 THEN NULL ELSE time_waited END))),'9,999,999,999')||' ..'||TO_CHAR(POWER(2,TRUNC(LOG(2,CASE WHEN time_waited < 1 THEN NULL ELSE time_waited END)))*2, '9,999,999,999'), ' ',''), 26) time_range
  , COUNT(*) samples
  , LPAD(TO_CHAR(TO_NUMBER(ROUND(RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY session_state, wait_class, event) * 100, 1), 999.9))||' %',8) pct_event
  , '|'||RPAD( NVL( LPAD('#', ROUND(RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY session_state, wait_class, event) * 10), '#'), ' '), 10,' ')||'|' pct_event_vis
  , LPAD(TO_CHAR(TO_NUMBER(ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100, 1), 999.9))||' %',8) pct_total 
  , '|'||RPAD( NVL( LPAD('#', ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 10), '#'), ' '), 10,' ')||'|' pct_total_vis
FROM
    gv$active_session_history
WHERE
    1=1
AND inst_id = &1
AND sample_time BETWEEN &2 AND &3
--AND sample_time BETWEEN TIMESTAMP'2012-04-29 19:30:00' AND TIMESTAMP'2012-04-29 19:30:59'
AND (REGEXP_LIKE(wait_class, '&&4') OR REGEXP_LIKE(event, '&&4'))
GROUP BY
    session_state
  , wait_class
  , event
  , POWER(2,TRUNC(LOG(2,CASE WHEN time_waited < 1 THEN NULL ELSE time_waited END)))
ORDER BY
    session_state
  , wait_class
  , event
  , time_range NULLS FIRST
  , samples DESC
/

