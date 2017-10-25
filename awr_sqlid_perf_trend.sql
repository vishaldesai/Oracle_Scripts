set ver off pages 50000 lines 700 tab off
set linesize 700
undef sql_id
undef days_history
undef interval_hours
def sql_id="&1"
def days_history="&2"
def interval_hours="&3"
col inst for 9999
col time for a19
col executions for 9999999999
col end_time for a20
col rows_processed_1exec for 9999999.999
col elapsed_time_s_1exec for 9999999.999
col cpu_time_s_1exec for 9999999.999
col iowait_s_1exec for 9999999.999
col clwait_s_1exec for 9999999.999
col apwait_s_1exec for 9999999.999
col ccwait_s_1exec for 9999999.999
col plsexec_time_s_1exec for 9999999.999
col javexec_time_s_1exec for 9999999.999
col buffer_gets_1exec for 999999999999.999
col disk_reads_1exec for 999999999999.999
col direct_writes_1exec for 999999999999.999
BREAK ON inst SKIP 1


select hss.instance_number inst,
    hss.plan_hash_value,
    to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'dd.mm.yyyy hh24:mi:ss') end_time,
    sum(hss.executions_delta) executions,
        round(sum(hss.rows_processed_delta)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) rows_processed_1exec,
    round(sum(hss.elapsed_time_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3) elapsed_time_s_1exec,
    round(sum(hss.cpu_time_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3) cpu_time_s_1exec,
    round(sum(hss.iowait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3) iowait_s_1exec,
    round(sum(hss.clwait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3) clwait_s_1exec,
    round(sum(hss.apwait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3) apwait_s_1exec,
    round(sum(hss.ccwait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3) ccwait_s_1exec,
    round(sum(hss.plsexec_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) plsexec_time_s_1exec,
    round(sum(hss.javexec_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) javexec_time_s_1exec,
    round(sum(hss.buffer_gets_delta)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) buffer_gets_1exec,
    round(sum(hss.disk_reads_delta)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) disk_reads_1exec,
    round(sum(hss.direct_writes_delta)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) direct_writes_1exec,
    round(sum(hss.FETCHES_DELTA)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) fetches_1exec,
    round(sum(hss.PX_SERVERS_EXECS_DELTA)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) PX_1exec,
    round(sum(hss.PHYSICAL_READ_REQUESTS_DELTA)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) physical_reads_1exec,
    round(sum(hss.PHYSICAL_WRITE_REQUESTS_DELTA)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) physical_writes_1exec,
    round(sum(hss.PHYSICAL_READ_BYTES_DELTA/1024/1024)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) physical_reads_Mbytes_1exec,
    round(sum(hss.PHYSICAL_WRITE_BYTES_DELTA/1024/1024)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) physical_writes_Mbytes_1exec,
    round(sum(hss.IO_OFFLOAD_ELIG_BYTES_DELTA/1024/1024)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) IO_OFFLOAD_ELIG_MBYTES_1exec,
    round(sum(hss.IO_INTERCONNECT_BYTES_DELTA/1024/1024)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) IO_INTERCONNECT_MBYTES_1exec,
    round(sum(hss.OPTIMIZED_PHYSICAL_READS_DELTA)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) OPTIMIZED_PHYSICAL_READS_1exec,
    round(sum(hss.CELL_UNCOMPRESSED_BYTES_DELTA/1024/1024)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) CELL_UNCOMPRESSED_MBYTES_1exec,
    round(sum(hss.IO_OFFLOAD_RETURN_BYTES_DELTA/1024/1024)/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),0) IO_OFFLOAD_RETURN_Mbytes_1exec
from dba_hist_sqlstat hss, dba_hist_snapshot hs
where hss.sql_id in ('&sql_id')
    and hss.snap_id=hs.snap_id
    and hss.instance_number=hs.instance_number
    and hs.end_interval_time>=trunc(sysdate)-&days_history+1
group by hss.instance_number,hss.plan_hash_value, trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24
order by hss.instance_number,hss.plan_hash_value, trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24;


undef sql_id
undef days_history
undef interval_hours
undef 1
undef 2
undef 3
