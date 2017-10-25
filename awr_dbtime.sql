----------------------------------------------------------------------------------------
--
-- File name:   dbtime.sql
-- Purpose:     Find busiest time periods in AWR.
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for three values, all of which can be left blank.
--
--              instance_number: set to limit to a single instance in RAC environment
--
--              begin_snap_id: set it you want to limit to a specific range, defaults to 0
--
--              end_snap_id: set it you want to limit to a specific range, defaults to 99999999
--
--
---------------------------------------------------------------------------------------
/*

set lines 155
col dbtime for 999,999.99
col begin_timestamp for a40
select * from (
select begin_snap, end_snap, timestamp begin_timestamp, inst, a/1000000/60 DBtime from
(
select
 e.snap_id end_snap,
 lag(e.snap_id) over (order by e.snap_id) begin_snap,
 lag(s.end_interval_time) over (order by e.snap_id) timestamp,
 s.instance_number inst,
 e.value,
 nvl(value-lag(value) over (order by e.snap_id),0) a
from dba_hist_sys_time_model e, DBA_HIST_SNAPSHOT s
where s.snap_id = e.snap_id
 and e.instance_number = s.instance_number
 and to_char(e.instance_number) like nvl('&instance_number',to_char(e.instance_number))
 and stat_name             = 'DB time'
)
where  begin_snap between nvl('&begin_snap_id',0) and nvl('&end_snap_id',99999999)
and begin_snap=end_snap-1
order by dbtime desc
)
where rownum < 31
/

*/


set ver off pages 50000 lines 140 tab off
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
--accept stat_name        prompt 'Enter stat name				: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

col inst for 9
col snap_time for a19
col STAT_NAME for a35
col STAT_VALUE for 999999999999999
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
      sst.stat_name,
      sst.value
    FROM
      snap snp,
      DBA_HIST_SYS_TIME_MODEL sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.stat_name     = 'DB time'
  )
SELECT
  b2.instance_number,
  b2.end_time snap_time,
  b2.stat_name,
  round(b2.value - b1.value,0) STAT_VALUE
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
undef stat_name
undef days_history
undef interval_minutes