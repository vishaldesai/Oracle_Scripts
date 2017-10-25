--------------------------------------------------------------------------------
--
-- File name:   ash_sql_timings.sql
-- Purpose:     Display sqlid,max,min and avg timings
--
-- Author:      Kyle
-- Copyright:   
--              
-- Usage:       @ash_sql_timings <sid>

--------------------------------------------------------------------------------


col 1 for 99999
col 2 for 99999
col 3 for 9999
col 4 for 999
col 5 for 99
col av for 99999.9
col ct for 99999
col mn for 99999
col av for 99999.9
col MAX_RUN_TIME for a25
set linesize 200
set pages 999

accept sqlid			prompt 'Enter sqlid  :'
accept ndays      prompt 'Enter n days : '

with pivot_data as (
select
      sql_id,
      ct,
      mxdelta mx,
      mndelta mn,
      avdelta av,
      width_bucket(delta,0,mxdelta+.1,5) as bucket  ,
      substr(times,12) max_run_time
from (
select
   sql_id,
   delta,
   count(*) OVER (PARTITION BY sql_id) ct,
   max(delta) OVER (PARTITION BY sql_id) mxdelta,
   min(delta) OVER (PARTITION BY sql_id) mndelta,
   avg(delta) OVER (PARTITION BY sql_id) avdelta,
   max(times) OVER (PARTITION BY sql_id) times
from (
   select
        sql_id,
        sql_exec_id,
        max(delta) delta ,
        lpad(round(max(delta),0),10) || ' ' ||
        to_char(max(start_time),'YY-MM-DD HH24:MI:SS')  || ' ' ||
        to_char(min(end_time),'YY-MM-DD HH24:MI:SS')  times
   from ( select
                                            sql_id,
                                            sql_exec_id,
              cast(sample_time as date)     end_time,
              cast(sql_exec_start as date)  start_time,
              ((cast(sample_time    as date)) -
               (cast(sql_exec_start as date))) * (3600*24) delta
           from
              dba_hist_active_sess_history
           where sql_exec_id is not null
             and sql_id = '&sqlid'
             and sample_time >= sysdate-&ndays
        )
   group by sql_id,sql_exec_id
)
)
where ct > 1
)
select * from pivot_data
PIVOT ( count(*) FOR bucket IN (1,2,3,4,5))
order by mx,av
/

SELECT
      sql_id
     ,sql_exec_id
     ,start_time
     ,end_time
     ,(end_time-start_time)* (3600*24) elapsec
     ,parallel_dop
FROM
       (
              SELECT
                     sql_id
                   ,sql_exec_id
                   ,end_time
                   ,parallel_dop
                   ,MIN(start_time) start_time
              FROM
                     (
                            SELECT
                                   sql_id
                                 , sql_exec_id
                                 , MAX(CAST(sample_time AS DATE)) end_time
                                 , CAST(sql_exec_start AS DATE) start_time
                                 , COUNT (distinct session_id) parallel_dop
                            FROM
                                   dba_hist_active_sess_history
                            WHERE
                                   sql_exec_id IS NOT NULL
                               AND sql_id       = '&sqlid'
                               AND sample_time >= sysdate-&ndays
                            GROUP BY
                                   sql_id
                                 , sql_exec_id
                                 , sql_exec_start
                     )
              GROUP BY
                     sql_id
                   ,sql_exec_id
                   ,end_time
                   ,parallel_dop
       )
ORDER BY
       start_time;
