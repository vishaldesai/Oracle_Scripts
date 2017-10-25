REM Name:    lst19-04-exastorind-awr.sql
REM Purpose: Display smart scan and storage index statistics from AWR snapshots
REM Usage: SQL> @lst19-04-exastorind-awr.sql

set lines 200
col stime format a15 head 'SnapStart'
col icgb format 999999999 head 'InterconnectGB'
col sigb format 999999999 head 'StorageIndexSavedGB'
col eliggb format 999999999 head 'SmartScanEligibleGB'
col ssgb format 999999999 head 'SmartScanReturnedBytes'
select stime,icgb,eliggb,ssgb,sigb from (
select  distinct 
  to_char(snap.begin_interval_time,'DD-MON-RR HH24:MI') stime,
  snaps.icbytes/1024/1024/1024 icgb,
  snaps.eligbytes/1024/1024/1024 eliggb, 
  snaps.ssbytes/1024/1024/1024 ssgb,
  snaps.sibytes/1024/1024/1024 sigb,
  myrank
from (
select ss1.snap_id,
       (sum(ss1.value) - lag(sum(ss1.value),1,0) over (order by ss1.snap_id)) icbytes,
       (sum(ss2.value) - lag(sum(ss2.value),1,0) over (order by ss2.snap_id)) eligbytes,
       (sum(ss3.value) - lag(sum(ss3.value),1,0) over (order by ss3.snap_id)) ssbytes,
       (sum(ss4.value) - lag(sum(ss4.value),1,0) over (order by ss4.snap_id)) sibytes,
	rank() over (order by ss1.snap_id) myrank
from
     dba_hist_sysstat ss1,
     dba_hist_sysstat ss2,
     dba_hist_sysstat ss3,
     dba_hist_sysstat ss4
where ss1.snap_id=ss2.snap_id
and ss2.snap_id=ss3.snap_id
and ss3.snap_id=ss4.snap_id
--and ss1.snap_id between &&snap_low-1 and &&snap_hi
and ss2.dbid=ss1.dbid
and ss3.dbid=ss2.dbid
and ss4.dbid=ss3.dbid
--represents the number of bytes transmitted over the stroage interconnect
and ss1.stat_name='cell physical IO interconnect bytes'
--number of bytes eligible for smart scan
and ss2.stat_name='cell physical IO bytes eligible for predicate offload'
--represents number of bytes returned by smart scan
and ss3.stat_name='cell physical IO interconnect bytes returned by smart scan'
and ss4.stat_name='cell physical IO bytes saved by storage index'
group by ss1.snap_id,ss2.snap_id,ss3.snap_id,ss4.snap_id
order by ss1.snap_id) ,
dba_hist_snapshot snap
where snap.snap_id=snaps.snap_id
and   snap.end_interval_time >=systimestamp -11
order by 1)
where myrank>1;
undefine snap_low
undefine snap_hi
