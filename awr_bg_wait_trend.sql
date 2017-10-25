set ver off pages 50000 lines 140 tab off
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept event_name       prompt 'Enter background event_name			: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

col inst for 9
col snap_time for a19
col EVENT_NAME for a64
col total_waits for 99999999999999
col total_time_s for 9999999999999
col avg_time_ms for 99999.99
BREAK ON instance_number SKIP 1


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
    SELECT
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
    SELECT
      snp.instance_number,
      sst.snap_id,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
      sst.total_waits,
      sst.time_waited_micro
    FROM
      snap snp,
      DBA_HIST_BG_EVENT_SUMMARY sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.event_name    = '&event_name'
  )
SELECT
  b2.instance_number,
  b2.end_time end_snap_time,
  round(b2.total_waits        - b1.total_waits,0) total_waits,
  round((b2.time_waited_micro  - b1.time_waited_micro)/1000000,0) total_time_s,
  round((b2.time_waited_micro - b1.time_waited_micro)/decode((b2.total_waits - b1.total_waits),0,1,(b2.total_waits - b1.total_waits))/1000,2) avg_time_ms
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
     b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
ORDER BY
  1,2 ;
  
undef inst
undef event_name
undef days_history
undef interval_minutes

