undef days_history
undef interval_hours
def plan="&1"
def days_history="&2"
def interval_hours="&3"
def sort_col_nr="&4"
def top_n="&5"
col inst for 9999
col time for a19
col force_matching_signature for 99999999999999999999
col executions for 9999999999
col rows_processed for 9999999.999
col elapsed_time_s for 9999999.999
col cpu_time_s for 9999999.999
col iowait_s for 9999999.999
col clwait_s for 9999999.999
col apwait_s for 9999999.999
col ccwait_s for 9999999.999
col plsexec_time_s for 9999999.999
col javexec_time_s for 9999999.999
col buffer_gets for 999999999999.999
col disk_reads for 999999999999.999
col direct_writes for 999999999999.999
col sql_id for a13
col diff_plans for 9999999999
col force_matching_signature for 99999999999999999999

select * from (
select plan_hash_value,
    force_matching_signature,
    sql_id,
    sum(hss.executions_delta) executions,
    round(sum(hss.elapsed_time_delta)/1000000,3) elapsed_time,
    round(sum(hss.cpu_time_delta)/1000000,3) cpu_time,
    round(sum(hss.iowait_delta)/1000000,3) iowait_s,
    round(sum(hss.clwait_delta)/1000000,3) clwait_s,
    round(sum(hss.apwait_delta)/1000000,3) apwait_s,
    round(sum(hss.ccwait_delta)/1000000,3) ccwait_s,
    round(sum(hss.rows_processed_delta),3) rows_processed,
    round(sum(hss.buffer_gets_delta),3) buffer_gets,
    round(sum(hss.disk_reads_delta),3) disk_reads,
    round(sum(hss.direct_writes_delta),3) direct_writes
from dba_hist_sqlstat hss, dba_hist_snapshot hs
where hss.snap_id=hs.snap_id
    and hss.plan_hash_value like '&plan'
    and hs.begin_interval_time>=trunc(sysdate)-&days_history+1
    and hs.begin_interval_time<=trunc(sysdate)-&days_history+1+(&interval_hours/24)
group by plan_hash_value, force_matching_signature, sql_id
order by &sort_col_nr desc)
where rownum<=&top_n;