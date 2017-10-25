rem
rem     Script:       trend_awr_osstat.sql
rem     Author:       Jonathan Lewis
rem     Dated:        Sep 2006
rem     Purpose:
rem
rem     Last tested
rem             10.2.0.3
rem     Not Tested
rem             11.2.0.1
rem             11.1.0.7
rem     Not relevant
rem              9.2.0.8
rem              8.1.7.4
rem
rem     Warning:
rem     Requires licence for Diagnostic Pack.
rem
rem     Notes:
rem     Trendline through AWR OS stats
rem
rem     Accesses data for current instance and DBID
rem
rem     Hard coded to go 30 days back in history
rem     Ignores database restarts
rem
rem     Reports a timestamp at the start of an interval
rem     with the activity that happened in that interval
rem
rem     The join on snap_id + 1 is valid for AWR because
rem     of the way AWR generates snapshot ids. (This is
rem     not safe for statspack unless you set the sequence
rem     to nocache).
rem
rem     Change the following define to pick a different statistic
rem     The available OS stats are platform dependent
rem
 
define m_stat_name = 'BUSY_TIME'
 
set timing off
set linesize 132
set pagesize 60
set trimspool on
 
column  instance_number   new_value m_instance  noprint
column  dbid              new_value m_dbid      noprint
 
select
        ins.instance_number,
        db.dbid
from
        v$instance        ins,
        v$database        db
;
 
column        value      format        999,999,999,999
column        curr_value format        999,999,999,999
column        prev_value format        999,999,999,999
 
spool trend_awr_osstat
 
with base_line as (
        select
                /*+ materialize */
                snp.snap_id,
                to_char(snp.end_interval_time,'Mon-dd hh24:mi:ss')     end_time,
                ost.value
        from
                dba_hist_snapshot       snp,
                dba_hist_osstat         ost
        where
                snp.dbid            = &m_dbid
        and     snp.instance_number = &m_instance
        and     end_interval_time   between sysdate - 30 and sysdate
        /*                                                        */
        and     ost.dbid            = snp.dbid
        and     ost.instance_number = snp.instance_number
        and     ost.snap_id         = snp.snap_id
        and     ost.stat_name       = '&m_stat_name'
        /*                                                        */
)
select
        b1.end_time           start_of_delta,
        b1.value              prev_value,
        b2.value              curr_value,
        b2.value - b1.value   value
from
        base_line        b1,
        base_line        b2
where
        b2.snap_id = b1.snap_id + 1
order by
        b1.snap_id
;
 
spool off