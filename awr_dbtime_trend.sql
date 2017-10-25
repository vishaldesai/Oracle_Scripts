set ver off pages 50000 lines 140 tab off
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

set linesize 500
col inst for 9
col END_SNAP_TIME format a20
col wait_class format a20
col twm    format 9999999999999999999
col dbcpu  format 9999999999999999999
col usr_io format 9999999999999999999
col sys_io format 9999999999999999999
col sched  format 9999999999999999999
col other  format 9999999999999999999
col appl   format 9999999999999999999
col comm   format 9999999999999999999
col conc   format 9999999999999999999
col config format 9999999999999999999
col netw   format 9999999999999999999
col clu    format 9999999999999999999
col adm    format 9999999999999999999
col dbtim  format 9999999999999999999
BREAK ON instance_number SKIP 1

WITH
  inter AS
  (
    SELECT
      extract(DAY FROM 24*60*snap_interval) inter_val
    FROM
      dba_hist_wr_control where dbid in (select dbid from v$database)
  )
  ,
  snap AS
  (
    SELECT /*+ MATERIALIZE */
      INSTANCE_NUMBER,
      MIN(snap_id) SNAP_ID,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24 END_INTERVAL_TIME
    FROM
      dba_hist_snapshot
    WHERE
      begin_interval_time>=TRUNC(sysdate)- &days_history +1
    AND  instance_number = decode(&inst,0,instance_number,&inst)
    GROUP BY
      instance_number,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24
    ORDER BY
      3
  )
  ,
  base_line AS
  (
    SELECT /*+ MATERIALIZE */
      snp.instance_number,
      sst.snap_id,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
	  sst.event_id,
	  sst.wait_class,
	  sst.total_waits,
      sst.time_waited_micro_fg,
      sst.time_waited_micro
    FROM
      snap snp,
      DBA_HIST_SYSTEM_EVENT sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.wait_class   != 'Idle'
  )
  ,
  base_line_fg AS
  (
    SELECT /*+ MATERIALIZE */
      snp.instance_number,
      sst.snap_id,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
	  sst.event_id,
      sst.time_waited_micro
    FROM
      snap snp,
      DBA_HIST_BG_EVENT_SUMMARY sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
  )
  ,
  base_line_tm AS
  (
    SELECT /*+ MATERIALIZE */
      snp.instance_number,
	  sst.snap_id,
      sst.stat_name,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
	  sst.value
    FROM
      snap snp,
      DBA_HIST_SYS_TIME_MODEL sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
	AND stat_name in ('DB time','DB CPU')
  )
SELECT * FROM (
  SELECT 
    b2.instance_number
  , b2.end_time end_snap_time
  , b2.wait_class  wait_class
  , sum( b2.time_waited_micro - nvl(b1.time_waited_micro,0))
                        twm
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
	b2.snap_id         = b1.snap_id	+ &interval_minutes/inter.inter_val
AND b2.instance_number = b1.instance_number
AND b2.event_id        = b1.event_id
--AND b2.total_waits     > nvl(b1.total_waits,0)
group by b2.end_time, b2.wait_class, b2.instance_number
UNION
SELECT 
    b2.instance_number
  , b2.end_time end_snap_time
  , b2.stat_name
  , b2.value - b1.value twm
FROM
  base_line_tm b1,
  base_line_tm b2,
  inter
WHERE
    b2.stat_name = 'DB CPU'
AND b2.stat_name       = b1.stat_name
AND b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
UNION
SELECT 
    b2.instance_number
  , b2.end_time end_snap_time
  , b2.stat_name
  , b2.value - b1.value twm
FROM
  base_line_tm b1,
  base_line_tm b2,
  inter
WHERE
    b2.stat_name = 'DB time'
AND b2.stat_name       = b1.stat_name
AND b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
--ORDER BY 1,2,3
)
pivot (sum(twm) for wait_class in (
	    'DB CPU'                dbcpu
      , 'User I/O'             usr_io
      , 'System I/O'           sys_io
	  , 'Scheduler'             sched
      , 'Other'                 other
      , 'Application'            appl
      , 'Commit'                 comm
      , 'Concurrency'            conc
      , 'Configuration'        config
      , 'Network'                netw
      , 'Cluster'                 clu
	  , 'Administrative'          adm
	  , 'DB time'               dbtim))
ORDER BY 1,2	  ;
 
WITH
  inter AS
  (
    SELECT
      extract(DAY FROM 24*60*snap_interval) inter_val
    FROM
      dba_hist_wr_control
  )
  ,
  snap AS
  (
    SELECT /*+ MATERIALIZE */
      INSTANCE_NUMBER,
      MIN(snap_id) SNAP_ID,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24 END_INTERVAL_TIME
    FROM
      dba_hist_snapshot
    WHERE
      begin_interval_time>=TRUNC(sysdate)- &days_history +1
    AND  instance_number = decode(&inst,0,instance_number,&inst)
    GROUP BY
      instance_number,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24
    ORDER BY
      3
  )
  ,
  base_line AS
  (
    SELECT /*+ MATERIALIZE */
      snp.instance_number,
      sst.snap_id,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
	  sst.event_id,
	  sst.wait_class,
	  sst.total_waits,
      sst.time_waited_micro_fg,
      sst.time_waited_micro
    FROM
      snap snp,
      DBA_HIST_SYSTEM_EVENT sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.wait_class   != 'Idle'
  )
  ,
  base_line_fg AS
  (
    SELECT /*+ MATERIALIZE */
      snp.instance_number,
      sst.snap_id,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
	  sst.event_id,
      sst.time_waited_micro
    FROM
      snap snp,
      DBA_HIST_BG_EVENT_SUMMARY sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
  )
  ,
  base_line_tm AS
  (
    SELECT /*+ MATERIALIZE */
      snp.instance_number,
	  sst.snap_id,
      sst.stat_name,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
	  sst.value
    FROM
      snap snp,
      DBA_HIST_SYS_TIME_MODEL sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
	AND stat_name in ('DB time','DB CPU')
  )
SELECT instance_number,
       end_snap_time,
	   round(dbcpu*100/dbtim) dbcpu,
	   round(usr_io*100/dbtim) usr_io,
	   round(sys_io*100/dbtim) sys_io,
	   round(sched*100/dbtim) sched,
	   round(other*100/dbtim) other,
	   round(appl*100/dbtim) appl,
	   round(comm*100/dbtim) comm,
	   round(conc*100/dbtim) conc,
	   round(config*100/dbtim) config,
	   round(netw*100/dbtim) netw,
	   round(clu*100/dbtim) clu,
	   round(adm*100/dbtim) adm
 FROM (
  SELECT 
    b2.instance_number
  , b2.end_time end_snap_time
  , b2.wait_class  wait_class
  , sum( b2.time_waited_micro - nvl(b1.time_waited_micro,0))
                        twm
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
	b2.snap_id         = b1.snap_id	+ &interval_minutes/inter.inter_val
AND b2.instance_number = b1.instance_number
AND b2.event_id        = b1.event_id
--AND b2.total_waits     > nvl(b1.total_waits,0)
group by b2.end_time, b2.wait_class, b2.instance_number
UNION
SELECT 
    b2.instance_number
  , b2.end_time end_snap_time
  , b2.stat_name
  , b2.value - b1.value twm
FROM
  base_line_tm b1,
  base_line_tm b2,
  inter
WHERE
    b2.stat_name = 'DB CPU'
AND b2.stat_name       = b1.stat_name
AND b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
UNION
SELECT 
    b2.instance_number
  , b2.end_time end_snap_time
  , b2.stat_name
  , b2.value - b1.value twm
FROM
  base_line_tm b1,
  base_line_tm b2,
  inter
WHERE
    b2.stat_name = 'DB time'
AND b2.stat_name       = b1.stat_name
AND b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
--ORDER BY 1,2,3
)
pivot (sum(twm) for wait_class in (
	    'DB CPU'                dbcpu
      , 'User I/O'             usr_io
      , 'System I/O'           sys_io
	  , 'Scheduler'             sched
      , 'Other'                 other
      , 'Application'            appl
      , 'Commit'                 comm
      , 'Concurrency'            conc
      , 'Configuration'        config
      , 'Network'                netw
      , 'Cluster'                 clu
	  , 'Administrative'          adm
	  , 'DB time'               dbtim))
ORDER BY 1,2	  ;
  
undef inst
undef event_name
undef days_history
undef interval_minutes
