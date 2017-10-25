accept days_history     prompt 'Enter number of days			: '

/*
SELECT * FROM
( 
  SELECT 
  s0.instance_number inst
  --, s0.snap_id id
  ,TO_CHAR(s1.END_INTERVAL_TIME,'MM/DD/YY HH24:MI') tm
  ,s1p1.value as cputhread
  ,round(s1p1.value*100/s3t1.value,2) || '%' as oraicpua
  ,round(((round(((s6t1.value - s6t0.value) / 1000000) + ((s7t1.value - s7t0.value) / 1000000),2)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100,2) as oracpupct
  ,round((((s1t1.value - s1t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100,2) as oscpupct
  ,round(s2t1.value,2) AS load
FROM dba_hist_snapshot s0,
  dba_hist_snapshot s1,
  dba_hist_osstat s1t0,         -- BUSY_TIME
  dba_hist_osstat s1t1,
  dba_hist_osstat s2t1,         -- osstat just get the end value for load average
  dba_hist_osstat s3t1,         -- osstat just get the end value
  dba_hist_sys_time_model s6t0,
  dba_hist_sys_time_model s6t1,
  dba_hist_sys_time_model s7t0,
  dba_hist_sys_time_model s7t1,
  dba_hist_parameter s1p1
WHERE  s1.dbid              = s0.dbid
AND s1t0.dbid            = s0.dbid
AND s1t1.dbid            = s0.dbid
AND s2t1.dbid            = s0.dbid
AND s3t1.dbid            = s0.dbid
AND s6t0.dbid            = s0.dbid
AND s6t1.dbid            = s0.dbid
AND s7t0.dbid            = s0.dbid
AND s7t1.dbid            = s0.dbid
AND s1p1.dbid            = s0.dbid
AND s1.instance_number   = s0.instance_number
AND s1t0.instance_number = s0.instance_number
AND s1t1.instance_number = s0.instance_number
AND s2t1.instance_number = s0.instance_number
AND s3t1.instance_number = s0.instance_number
AND s6t0.instance_number = s0.instance_number
AND s6t1.instance_number = s0.instance_number
AND s7t0.instance_number = s0.instance_number
AND s7t1.instance_number = s0.instance_number
AND s1p1.instance_number = s0.instance_number
AND s1.snap_id           = s0.snap_id + 1
AND s1t0.snap_id         = s0.snap_id
AND s1t1.snap_id         = s0.snap_id + 1
AND s2t1.snap_id         = s0.snap_id + 1
AND s3t1.snap_id         = s0.snap_id + 1
AND s6t0.snap_id         = s0.snap_id
AND s6t1.snap_id         = s0.snap_id + 1
AND s7t0.snap_id         = s0.snap_id
AND s7t1.snap_id         = s0.snap_id + 1
AND s1p1.snap_id		 = s0.snap_id + 1
AND s1t0.stat_name       = 'BUSY_TIME'
AND s1t1.stat_name       = s1t0.stat_name
AND s2t1.stat_name       = 'LOAD'
AND s1p1.parameter_name  = 'cpu_count'
AND s3t1.stat_name       = 'NUM_CPUS'
AND s6t0.stat_name       = 'DB CPU'
AND s6t1.stat_name       = s6t0.stat_name
AND s7t0.stat_name       = 'background cpu time'
AND s7t1.stat_name       = s7t0.stat_name
AND s0.END_INTERVAL_TIME >= TO_DATE('2015-jan-22 14:00:00','yyyy-mon-dd hh24:mi:ss')
AND s0.END_INTERVAL_TIME <= TO_DATE('2015-jan-22 17:00:00','yyyy-mon-dd hh24:mi:ss')
) ORDER BY 1,2 ASC;

*/

/*
How to interpret "% of total CPU for Instance" and "% of busy CPU for
Instance" under "Instance CPU" of Statspack Report.

SOLUTION

% of total CPU for Instance: ((:dbcpu+:bgcpu)/1000000)/(:ttics)
% of busy CPU for Instance: ((:dbcpu+:bgcpu)/1000000)/((:btic)/100)

dbcpu := 'DB CPU'
bgcpu := 'background cpu time'
btic := BUSY_TIME
ttics := (:btic + :itic)/100 (where btic---> Busy_Time and itic---> Idle_Time)
BUSY_TIME:
Number of hundredths of a second that a processor has been busy executing user or kernel code, totalled over all processors.


IDLE_TIME:
Number of hundredths of a second that a processor has been idle, totalled over all processors.

% of total CPU for Instance is the ratio of total of user process cpu plus the background process cpu to the total tics.
% of busy CPU for Instance is the ratio of total of user process cpu plus the background process cpu to the busy tics.

The BUSY CPU and the Total CPU % can be seen under "Instance CPU" section of Statspack Report.
*/

set echo off verify off
set pagesize 50000
set linesize 250
col inst        format 90               heading "Instance"
col tm          format a15				heading "End|Interval"
col oscpupct    format 990              heading "OS|CPU|%"
col oraicpua	format a10			    heading "Instance|CPU|Allocation"
col cputhread   justify right format a10   			heading "CPU|Allocated" 
-- karl arao way oracpupct
col oracpupct	format 99.99			heading "% of inst CPU|see comment" 
col oracpupct1  format 99.99            heading "% of tot CPU|for Instance"
col oracpupct2  format 99.99			heading "% of busy CPU|for Instance"
col dbtwfcpu    format 99.99			heading "DB Time% waiting for| CPU Res mgr"
col load        format 990.00           heading "OS|Load"
BREAK ON inst SKIP 1

SELECT * FROM
( 
  SELECT 
  s0.instance_number inst
  --, s0.snap_id id
  ,TO_CHAR(s1.END_INTERVAL_TIME,'MM/DD/YY HH24:MI') tm
  ,s1p1.value as cputhread
  ,round(s1p1.value*100/s3t1.value,2) || '%' as oraicpua
  ,round(((round(((s6t1.value - s6t0.value) / 1000000) + ((s7t1.value - s7t0.value) / 1000000),2)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100,2) as oracpupct
  ,round((((s6t1.value - s6t0.value) + (s7t1.value - s7t0.value))/1000000)*100/(((s1t1.value - s1t0.value) + (s0t1.value - s0t0.value))/100),1)  as oracpupct1
  ,round((((s6t1.value - s6t0.value) + (s7t1.value - s7t0.value))/1000000)*100/(( (s0t1.value - s0t0.value))/100),1)  as oracpupct2
  ,round((s8t1.time_waited_micro - s8t0.time_waited_micro)*100/(s9t1.value - s9t0.value),2) as dbtwfcpu
  ,round((((s0t1.value - s0t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100,2) as oscpupct
  ,round(s2t1.value,2) AS load
FROM dba_hist_snapshot s0,
  dba_hist_snapshot s1,
  dba_hist_osstat s0t0,			-- BUSY_TIME
  dba_hist_osstat s0t1,
  dba_hist_osstat s1t0,         -- IDLE_TIME
  dba_hist_osstat s1t1,
  dba_hist_osstat s2t1,         -- osstat just get the end value for load average
  dba_hist_osstat s3t1,         -- osstat just get the end value
  dba_hist_sys_time_model s6t0,
  dba_hist_sys_time_model s6t1,
  dba_hist_sys_time_model s7t0,
  dba_hist_sys_time_model s7t1,
  dba_hist_system_event   s8t0,
  dba_hist_system_event   s8t1,
  dba_hist_sys_time_model s9t0,
  dba_hist_sys_time_model s9t1,
  dba_hist_parameter s1p1
WHERE  s1.dbid           = s0.dbid
AND s0t0.dbid            = s0.dbid
AND s0t1.dbid            = s0.dbid
AND s1t0.dbid            = s0.dbid
AND s1t1.dbid            = s0.dbid
AND s2t1.dbid            = s0.dbid
AND s3t1.dbid            = s0.dbid
AND s6t0.dbid            = s0.dbid
AND s6t1.dbid            = s0.dbid
AND s7t0.dbid            = s0.dbid
AND s7t1.dbid            = s0.dbid
AND s8t0.dbid            = s0.dbid
AND s8t1.dbid            = s0.dbid
AND s9t0.dbid            = s0.dbid
AND s9t1.dbid            = s0.dbid
AND s1p1.dbid            = s0.dbid
AND s1.instance_number   = s0.instance_number
AND s0t0.instance_number = s0.instance_number
AND s0t1.instance_number = s0.instance_number
AND s1t0.instance_number = s0.instance_number
AND s1t1.instance_number = s0.instance_number
AND s2t1.instance_number = s0.instance_number
AND s3t1.instance_number = s0.instance_number
AND s6t0.instance_number = s0.instance_number
AND s6t1.instance_number = s0.instance_number
AND s7t0.instance_number = s0.instance_number
AND s7t1.instance_number = s0.instance_number
AND s8t0.instance_number = s0.instance_number
AND s8t1.instance_number = s0.instance_number
AND s9t0.instance_number = s0.instance_number
AND s9t1.instance_number = s0.instance_number
AND s1p1.instance_number = s0.instance_number
AND s1.snap_id           = s0.snap_id + 1
AND s0t0.snap_id         = s0.snap_id
AND s0t1.snap_id         = s0.snap_id + 1
AND s1t0.snap_id         = s0.snap_id
AND s1t1.snap_id         = s0.snap_id + 1
AND s2t1.snap_id         = s0.snap_id + 1
AND s3t1.snap_id         = s0.snap_id + 1
AND s6t0.snap_id         = s0.snap_id
AND s6t1.snap_id         = s0.snap_id + 1
AND s7t0.snap_id         = s0.snap_id
AND s7t1.snap_id         = s0.snap_id + 1
AND s8t0.snap_id         = s0.snap_id
AND s8t1.snap_id         = s0.snap_id + 1
AND s9t0.snap_id         = s0.snap_id
AND s9t1.snap_id         = s0.snap_id + 1
AND s1p1.snap_id		 = s0.snap_id + 1
AND s1t0.stat_name       = 'IDLE_TIME'
AND s1t1.stat_name       = s1t0.stat_name
AND s0t0.stat_name       = 'BUSY_TIME'
AND s0t1.stat_name       = s0t0.stat_name
AND s2t1.stat_name       = 'LOAD'
AND s1p1.parameter_name  = 'cpu_count'
AND s3t1.stat_name       = 'NUM_CPUS'
AND s6t0.stat_name       = 'DB CPU'
AND s6t1.stat_name       = s6t0.stat_name
AND s7t0.stat_name       = 'background cpu time'
AND s7t1.stat_name       = s7t0.stat_name
AND s8t0.event_name      = 'resmgr:cpu quantum'
AND s8t1.event_name      = s8t0.event_name
AND s9t0.stat_name       = 'DB time'
AND s9t1.stat_name       = s9t0.stat_name
AND s0.begin_interval_time>=TRUNC(sysdate)- &days_history +1
--AND s0.END_INTERVAL_TIME >= TO_DATE('2015-jan-22 01:00:00','yyyy-mon-dd hh24:mi:ss')
--AND s0.END_INTERVAL_TIME <= TO_DATE('2015-jan-23 05:00:00','yyyy-mon-dd hh24:mi:ss')
--AND s0.snap_id = 2089
--and s1.snap_id = 2093
) ORDER BY 1,2 ASC;