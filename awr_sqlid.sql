set ver off pages 50000 lines 260 
undef sql_id
undef days_history
undef interval_hours
def sql_id="&1"
def days_history="&2"
def interval_hours="&3"
col inst for 9999
col time for a19
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

select hss.instance_number inst,
    to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'dd.mm.yyyy hh24:mi:ss') time,
    hss.sql_id,
    sum(hss.executions_delta) executions,
    round(sum(hss.elapsed_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) elapsed_time_s_1exec,
    round(sum(hss.cpu_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) cpu_time_s_1exec,
    round(sum(hss.iowait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) iowait_s_1exec,
    round(sum(hss.clwait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) clwait_s_1exec,
    round(sum(hss.apwait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) apwait_s_1exec,
    round(sum(hss.ccwait_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) ccwait_s_1exec,
    --round(sum(hss.plsexec_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) plsexec_time_s_1exec,
    --round(sum(hss.javexec_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) javexec_time_s_1exec,
    round(sum(hss.rows_processed_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) rows_processed_1exec,
    round(sum(hss.buffer_gets_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) buffer_gets_1exec,
    round(sum(hss.disk_reads_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) disk_reads_1exec,
    round(sum(hss.direct_writes_delta)/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) direct_writes_1exec
from dba_hist_sqlstat hss, dba_hist_snapshot hs
where hss.sql_id in ('1s084au01f65z','5fg9pd2tcfkdh','6rw9r5prfqcp8')
    and hss.snap_id=hs.snap_id
    and hss.instance_number=hs.instance_number
    and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
group by hss.instance_number, trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,hss.sql_id
order by hss.sql_id,trunc(sysdate-&days_history+1)+trunc((cast(hs.begin_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24;

undefine 1
undefine sql_id
undefine days_history
undefine interval_hours