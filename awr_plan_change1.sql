set lines 500
set pages 50
col execs for 999999999
col avg_etime for 999,999.999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_rows for 999,999,999,999
col plan_hash_value format a12
col begin_interval_time for a27
col end_interval_time for a27
col node for 99
break on plan_hash_value on startup_time skip 1
--break on plan_hash_value

SELECT ss.snap_id,
  ss.instance_number node,
  begin_interval_time,
  end_interval_time,
  sql_id,
  to_char(plan_hash_value) plan_hash_value,
  NVL(executions_delta,0) execs,
  --executions_delta execs,
  ROUND((cpu_time_delta    /DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,4) avg_cpu,
  ROUND((elapsed_time_delta/DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,4) avg_etime,
  ROUND((buffer_gets_delta /DECODE(NVL(buffer_gets_delta,0),0,1,executions_delta))) avg_lio,
  (disk_reads_delta        /DECODE(NVL(disk_reads_delta,0),0,1,executions_delta)) avg_pio,
  (rows_processed_delta    /DECODE(NVL(rows_processed_delta,0),0,1,executions_delta)) avg_rows
FROM DBA_HIST_SQLSTAT S,
  DBA_HIST_SNAPSHOT SS
WHERE sql_id           = NVL('&sql_id','4dqs2k5tynk61')
AND ss.snap_id         = S.snap_id
AND ss.instance_number = S.instance_number
--AND executions_delta   > 0
ORDER BY 1,
  2,
  3 ;
