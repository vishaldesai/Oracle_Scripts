set lines 500
set pages 1
col snap_id format 999999
col plan_hash_value format 999999999999999
col begin_interval_time for a18
col end_interval_time for a18
col sql_id format a13
col execs for 99999999999
col avg_etime_sec for 999999.9999
col avg_cpu for 999999.99
col avg_lio for 999999999
col avg_pio for 999999999
col avg_rows for 999999999999
col conc_wait format 999999999.99
col clus_wait format 999999999.99
col direct_read format 999999999
col direct_writes format 999999999
col iowait format 999999999
col PX format 999
col node for 99
set pages 9999
break on plan_hash_value on startup_time skip 1
undefine sql_id
--break on plan_hash_value

SELECT ss.snap_id,
  ss.instance_number node,
  to_char(begin_interval_time,'DD-MON-YY HH24:MI:SS') begin_interval_time,
  to_char(end_interval_time,'DD-MON-YY HH24:MI:SS') end_interval_time,
  plan_hash_value,
  NVL(executions_delta,0) execs,
  ROUND((elapsed_time_delta/DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,4) avg_etime_sec,
  ROUND((cpu_time_delta    /DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,2) avg_cpu
  --ROUND((buffer_gets_delta /DECODE(NVL(buffer_gets_delta,0),0,1,executions_delta))) avg_lio,
  --(disk_reads_delta        /DECODE(NVL(disk_reads_delta,0),0,1,executions_delta)) avg_pio,
  --(rows_processed_delta    /DECODE(NVL(rows_processed_delta,0),0,1,executions_delta)) avg_rows,
  --round((CCWAIT_DELTA			   /DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,2) conc_wait,
  --round((CLWAIT_DELTA			   /DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,2) clus_wait,
  --round((DISK_READS_DELTA        /DECODE(NVL(executions_delta,0),0,1,executions_delta)),0) direct_read,
  --round((DIRECT_WRITES_DELTA     /DECODE(NVL(executions_delta,0),0,1,executions_delta)),0) direct_writes,
  --round((iowait_delta /DECODE(NVL(executions_delta,0),0,1,executions_delta))/1000000,4) iowait,
  --round((PX_SERVERS_EXECS_DELTA /DECODE(NVL(executions_delta,0),0,1,executions_delta)),0) PX
FROM DBA_HIST_SQLSTAT S,
  DBA_HIST_SNAPSHOT SS
WHERE plan_hash_value           = NVL('&phv','')
AND ss.snap_id         = S.snap_id
AND ss.instance_number = S.instance_number
--AND executions_delta   > 0
AND ss.begin_interval_time>=sysdate-&n_days
ORDER BY 1,
  2,
  3 ;

undefine sql_id
