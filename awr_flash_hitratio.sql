/*
set arraysize 5000
set termout on
set echo off verify off
set lines 290
set pages 900
col id format 99999 head 'SnapID'
col tm format a15 head 'SnapStart'
col instances format 999 head 'Nodes'
col dur format 999.99 head 'Mins'
col fcrh 	format 999990.00 	head 'FlashCacheHits'
col prtb 	format 999990.00 	head 'PhysReadMB'
col prtbo 	format 999990.00 	head 'PhyReadMBOpt'
col priops 	format 999990.00 	head 'PhysReadIOPs'
col priopso 	format 999990.00 	head 'PhysReadIOPsOpt'
col iopshr format 999.90 head "%IOPs"
col byteshr format 999.90 head "%MB"
set echo on
select id,tm,dur,prtb,prtbo,
  100*(prtbo/prtb) byteshr,
  priops,priopso,
  100*(priopso/priops) iopshr
from (
 select  snaps.id, snaps.tm,snaps.dur,snaps.instances,
        ((sysstat.fcrh - 
		lag (sysstat.fcrh,1) over (order by snaps.id)))/dur/60  fcrh,
        ((sysstat.prtb - 
		lag (sysstat.prtb,1) over (order by snaps.id)))/dur/60/1024/1024  prtb,
        ((sysstat.prtbo - 
		lag (sysstat.prtbo,1) over (order by snaps.id)))/dur/60/1024/1024  prtbo,
        ((sysstat.priops - 
		lag (sysstat.priops,1) over (order by snaps.id)))/dur/60  priops,
        ((sysstat.priopso- 
		lag (sysstat.priopso,1) over (order by snaps.id)))/dur/60  priopso
 from
 ( 
 select distinct id,dbid,tm,instances,max(dur) over (partition by id) dur from (
 select distinct s.snap_id id, s.dbid,
    to_char(s.end_interval_time,'DD-MON-RR HH24:MI') tm,
    count(s.instance_number) over (partition by snap_id) instances,
    1440*((cast(s.end_interval_time as date) - lag(cast(s.end_interval_time as date),1) over (order by s.snap_id))) dur
 from   dba_hist_snapshot s where  s.end_interval_time >=systimestamp -11)  
 ) snaps,
  ( 
    select * from
        (select snap_id, dbid, stat_name, value from
        dba_hist_sysstat
    ) pivot
    (sum(value) for (stat_name) in
        (
         'cell flash cache read hits' as fcrh, 'physical read total bytes' as prtb,
	'physical read total bytes optimized' as prtbo,
	'physical read total IO requests' as priops,
	'physical read requests optimized' as priopso))
  ) sysstat
 where dur > 0 
 and snaps.id=sysstat.snap_id
 and snaps.dbid=sysstat.dbid)
 where  prtb>0 
 and priops>0
order by id asc
/

*/


set ver off pages 50000 lines 140 tab off
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

set arraysize 5000
set termout on
set echo off verify off
set lines 290
set pages 900

col fcrh 	format 999990.00 	head 'FlashCacheHits'
col prtb 	format 999999999999 	head 'PhysReadGB'
col prtbo 	format 999990.00 	head 'PhyReadGBOpt'
col priops 	format 999990.00 	head 'PhysReadIOPs'
col priopso 	format 999990.00 	head 'PhysReadIOPsOpt'
col iopshr format 999.90 head "%IOPsOpt"
col byteshr format 999.90 head "%MBOpt"
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
	select * from
        (select snp.instance_number, sst.snap_id, to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time, sst.stat_name, sst.value from
        snap snp, dba_hist_sysstat sst
		where sst.instance_number = snp.instance_number
        AND sst.snap_id       = snp.snap_id
    ) pivot
    (sum(value) for (stat_name) in
        (
         'cell flash cache read hits' as fcrh, 'physical read total bytes' as prtb,
	'physical read total bytes optimized' as prtbo,
	'physical read total IO requests' as priops,
	'physical read requests optimized' as priopso))
  )
select instance_number
     ,end_snap_time
--     ,round(prtb/1024)           prtb
--     ,round(prtbo/1024)         prtbo
--     ,100*(prtbo/prtb)        byteshr
--     ,round(priops)            priops
--     ,round(priopso)          priopso
     ,100*(priopso/priops)     iopshr
from (
SELECT
  b2.instance_number,
  b2.end_time end_snap_time,
  (b2.fcrh - b1.fcrh)/60/inter.inter_val  fcrh,
  (b2.prtb - b1.prtb)/60/inter.inter_val  prtb,
  (b2.prtbo - b1.prtbo)/60/inter.inter_val  prtbo,
  (b2.priops - b1.priops)/60/inter.inter_val  priops,
  (b2.priopso - b1.priopso)/60/inter.inter_val  priopso
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
     b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
)
ORDER BY 1,2 ;
  
undef inst
undef event_name
undef days_history
undef interval_minutes

