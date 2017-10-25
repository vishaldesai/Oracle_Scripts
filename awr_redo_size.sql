-------------------------------------------------------------------------------------------------
--  Script : awr_redo_size.sql
-------------------------------------------------------------------------------------------------
-- Changed this from Riyaz style to Jonathan style. :)

set pages 40
set lines 160
set serveroutput on size 1000000
column "redo_size (MB)" format 999,999,999,999.99
set verify off
accept history_days prompt 'Enter past number of days to search for (Null=30):'

with base_line as (
        select
                /*+ materialize */
                snp.snap_id,
                trunc(snp.end_interval_time)     end_time,
                snp.instance_number,
                sst.value
        from
                dba_hist_snapshot       snp,
                dba_hist_sysstat        sst
        where   snp.instance_number = sst.instance_number
        and     end_interval_time   >= to_date(trunc(sysdate-nvl('&&history_days',30)))
        and     sst.dbid            = snp.dbid
        and     sst.instance_number = snp.instance_number
        and     sst.snap_id         = snp.snap_id
        and     sst.stat_name       = 'redo size'
)
select
        b1.end_time     as snap_time        ,
        b1.instance_number as instance_number,
        sum(b2.value - b1.value)/1024/1024    "redo_size (MB)"
from
        base_line        b1,
        base_line        b2
where
        b2.snap_id = b1.snap_id + 1
and     b2.instance_number = b1.instance_number
group by
		b1.end_time, b1.instance_number
order by
		b1.end_time, b1.instance_number
;

set verify on