col 1 FOR 99999 
col 2 FOR 99999 
col 3 FOR 9999 
col 4 FOR 999 
col 5 FOR 99 
col av FOR 99999 
col ct FOR 99999 
col mn FOR 999 
col av FOR 99999.9 
col MAX_RUN_TIME FOR a32 
col longest_sql_exec_id FOR A20
set linesize 500
set pages 9999

WITH pivot_data AS
  (SELECT sql_id,
    ct,
    mxdelta mx,
    mndelta mn,
    ROUND(avdelta) av,
    WIDTH_BUCKET(delta_in_seconds,mndelta,mxdelta+.1,5) AS bucket ,
    SUBSTR(times,12) max_run_time,
    SUBSTR(longest_sql_exec_id, 12) longest_sql_exec_id
  FROM
    (SELECT sql_id,
      delta_in_seconds,
      COUNT(*) OVER (PARTITION BY sql_id) ct,
      MAX(delta_in_seconds) OVER (PARTITION BY sql_id) mxdelta,
      MIN(delta_in_seconds) OVER (PARTITION BY sql_id) mndelta,
      AVG(delta_in_seconds) OVER (PARTITION BY sql_id) avdelta,
      MAX(times) OVER (PARTITION BY sql_id) times,
      MAX(longest_sql_exec_id) OVER (PARTITION BY sql_id) longest_sql_exec_id
    FROM
      (SELECT sql_id,
        sql_exec_id,
        MAX(delta_in_seconds) delta_in_seconds ,
        LPAD(ROUND(MAX(delta_in_seconds),0),10)
        || ' '
        || TO_CHAR(MIN(start_time),'YY-MM-DD HH24:MI:SS')
        || ' '
        || TO_CHAR(MAX(end_time),'YY-MM-DD HH24:MI:SS') times,
        LPAD(ROUND(MAX(delta_in_seconds),0),10)
        || ' '
        || TO_CHAR(MAX(sql_exec_id)) longest_sql_exec_id
      FROM
        ( SELECT sql_id, TO_CHAR(sql_exec_id)||'_'||to_char(sql_exec_start,'J') sql_exec_id,
        CAST(sample_time AS    DATE) end_time,
        CAST(sql_exec_start AS DATE) start_time,
        ((CAST(sample_time AS DATE)) - (CAST(sql_exec_start AS DATE))) * (3600*24) delta_in_seconds
      FROM dba_hist_active_sess_history
      WHERE sql_exec_id IS NOT NULL
      AND sql_id='cz14u3877qjbr'
      )
    GROUP BY sql_id,
      sql_exec_id
    )
  )
WHERE ct >
  &min_repeat_executions_filter
AND mxdelta >
  &min_elapsed_time )
SELECT                        *
FROM pivot_data PIVOT ( COUNT(*) FOR bucket IN (1,2,3,4,5))
ORDER BY mx DESC,
  av DESC ;