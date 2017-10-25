REM --------------------------------------------------------------------------------------------------
REM Author: Riyaj Shamsudeen @OraInternals, LLC
REM         www.orainternals.com
REM
REM Functionality: This script is to print redo size rates in a RAC claster
REM **************
REM
REM Source  : AWR tables
REM
REM Exectution type: Execute from sqlplus or any other tool.
REM
REM Parameters: No parameters. Uses Last snapshot and the one prior snap
REM No implied or explicit warranty
REM
REM Please send me an email to rshamsud@orainternals.com, if you enhance this script :-)
REM  This is a open Source code and it is free to use and modify.
REM Version 1.20
REM --------------------------------------------------------------------------------------------------
set colsep '|'
set lines 220
alter session set nls_date_format='DD-MON-YYYY HH24:MI';
set pagesize 10000
with redo_data as (
SELECT instance_number,
       to_date(to_char(redo_date,'DD-MON-YY-HH24:MI'), 'DD-MON-YY-HH24:MI') redo_dt,
       trunc(redo_size/(1024 * 1024),2) redo_size_mb
 FROM  (
  SELECT dbid, instance_number, redo_date, redo_size , startup_time  FROM  (
    SELECT  sysst.dbid,sysst.instance_number, begin_interval_time redo_date, startup_time,
  VALUE -
    lag (VALUE) OVER
    ( PARTITION BY  sysst.dbid, sysst.instance_number, startup_time
      ORDER BY begin_interval_time ,sysst.instance_number
     ) redo_size
  FROM sys.wrh$_sysstat sysst , DBA_HIST_SNAPSHOT snaps
WHERE sysst.stat_id =
       ( SELECT stat_id FROM sys.wrh$_stat_name WHERE  stat_name='redo size' )
  AND snaps.snap_id = sysst.snap_id
  AND snaps.dbid =sysst.dbid
  AND sysst.instance_number  = snaps.instance_number
  AND snaps.begin_interval_time> sysdate-30
   ORDER BY snaps.snap_id )
  )
)
select  instance_number,  redo_dt, redo_size_mb,
    sum (redo_size_mb) over (partition by  trunc(redo_dt)) total_daily,
    trunc(sum (redo_size_mb) over (partition by  trunc(redo_dt))/24,2) hourly_rate
   from redo_Data
order by redo_dt, instance_number
/

