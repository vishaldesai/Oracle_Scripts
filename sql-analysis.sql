-- sql-analysis.sql
--
-- Used to extract execution data from AWR for a single SQL_ID
-- PHV (plan_hash_value is optional if only want to see data for single plan)
--

set long 32000 numwidth 15
set lines 4000
set pages 1000
set timing off
set head off
set feed off
set verify off

accept sql_id prompt 'Enter sql_id: '
accept phv    default null prompt 'Enter plan_hash_value (all if null): '
accept nodays default 7    prompt 'Enter # days to check (7 if null)  : '

col sql_text format a200 word_wrapped 

prompt
prompt ========================================================
prompt SQL Statement
prompt ========================================================
select sql_text from DBA_HIST_SQLTEXT where sql_id = '&sql_id';

set head on
column snap_id head 'Snap#' format 9999999
column instance_number head 'Inst#' format 99999

column sorts_total  head 'Sorts' format 99999
column executions_total  head 'Execs' format 99999
column disk_reads_total  head 'PIO'
column buffer_gets_total  head 'LIO'
column rows_processed_total  head 'Rows'
column cpu_time_total  head 'CPU'
column elapsed_time_total  head 'Elapsed'
column iowait_total  head 'IO Wait'
column clwait_total  head 'Cluster Wait'

column sorts_delta  head 'Sorts' format 99999
column executions_delta  head 'Execs' format 99999
column disk_reads_delta  head 'PIO' 
column buffer_gets_delta  head 'LIO' 
column rows_processed_delta  head 'Rows' 
column cpu_time_delta  head 'CPU' 
column elapsed_time_delta  head 'Elapsed' 
column iowait_delta  head 'IO Wait' 
column clwait_delta  head 'Cluster Wait' 

column snap_tm head 'Snap Time'
column plan_hash_value head 'Plan HV' format 999999999999
column phv head 'Plan HV' format 999999999999


prompt
prompt ========================================================
prompt Degraded plan info - Std Deviation (using averages)
prompt ========================================================

col execs for 999,999,999 heading 'Execs'
col min_etime for 999,999.99 heading 'Min'
col max_etime for 999,999.99 heading 'Max'
col avg_etime for 999,999.999 heading 'Elapsed'
col norm_stddev for 999,999.9999 heading 'Std Dev'

select instance_number, execs, max_etime, norm_stddev from (
  select sql_id, instance_number, sum(execs) execs, --min(avg_etime) min_etime, 
  		 max(avg_etime) max_etime, stddev_etime/min(avg_etime) norm_stddev
  from (
    select sql_id, snap_id, instance_number, execs, avg_etime, stddev(avg_etime) over (partition by sql_id) stddev_etime
    from (
      select sql_id, s.snap_id, s.instance_number, nvl(sum(executions_delta),0) execs,
             (sum(elapsed_time_delta)/decode(nvl(sum(executions_delta),0),0,1,sum(executions_delta))/1000000) avg_etime
      from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS, V$DATABASE V
      where ss.snap_id = s.snap_id
        and ss.instance_number = S.instance_number
        and ss.dbid = v.dbid
        and executions_delta > 0
        and elapsed_time_delta > 0
        and sql_id = '&sql_id'
      group by sql_id, s.snap_id, s.instance_number
      )
    )
  group by sql_id, instance_number, stddev_etime
  )
--where norm_stddev >= 1
--  and max_etime >=  .1
order by max_etime desc
;


prompt
prompt ========================================================
prompt Degraded plan info - Best and worst avg times per PHV
prompt ========================================================

col min_e for 999,999.99 heading 'Min'
col max_e for 999,999.99 heading 'Max'

select  phv, execs, min_e, max_e
from (
select plan_hash_value phv, sum(execs) execs, round(min(avg_elapsed),2) min_e, round(max(avg_elapsed),2) max_e
from (            
select s.plan_hash_value, s.snap_id, to_char(ss.begin_interval_time,'mm/dd/yyyy hh24:mi') snap_tm, 
		s.instance_number inst#, nvl(executions_delta,0) execs, elapsed_time_delta/1000000 tot_elapsed, 
		(elapsed_time_delta/1000000)/executions_delta avg_elapsed
      from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS, V$DATABASE V
      where ss.snap_id = s.snap_id
        and ss.instance_number = S.instance_number
        and ss.dbid = v.dbid
        and executions_delta > 0
        and elapsed_time_delta > 0
        and sql_id = '&sql_id'
)
group by plan_hash_value
)
order by max_e desc;


col execs for 999,999,999
col avg_etime for 999,999.999
col avg_pio heading 'Avg PIO'
col avg_lio heading 'Avg LIO'
col avg_rows heading 'Avg Rows'
col avg_time heading 'Avg Time'
col avg_cpu heading 'Avg CPU'
col avg_iowait heading 'Avg IO'
col avg_clwait heading 'Avg Clust'

prompt
prompt ========================================================
prompt AWR history details 
prompt ========================================================

select a.snap_id, to_char(b.begin_interval_time,'mm/dd/yyyy hh24:mi') snap_tm, a.instance_number, a.plan_hash_value, 
a.executions_delta execs,
round(a.disk_reads_delta/a.executions_delta,0) avg_pio,
round(a.buffer_gets_delta/a.executions_delta,0) avg_lio,
round(a.rows_processed_delta/a.executions_delta,0) avg_rows,
round((a.elapsed_time_delta/1000000)/a.executions_delta,0) avg_time,
round((a.cpu_time_delta/1000000)/a.executions_delta,0) avg_cpu,
round((a.iowait_delta/1000000)/a.executions_delta,0) avg_iowait,
round((a.clwait_delta/1000000)/a.executions_delta,0) avg_clwait 
from dba_hist_sqlstat a, dba_hist_snapshot b
where a.sql_id = '&sql_id'
and a.plan_hash_value = nvl(&phv,a.plan_hash_value)
and a.executions_delta > 0
and a.elapsed_time_delta > 0
and a.snap_id = b.snap_id
and a.instance_number = b.instance_number
and a.dbid = b.dbid
and b.snap_id in (select snap_id from dba_hist_snapshot where BEGIN_INTERVAL_TIME >= trunc(sysdate) - &nodays)
order by a.snap_id desc, a.instance_number, a.plan_hash_value ;


prompt
prompt ========================================================
prompt Detailed execution plans for best and worst
prompt 
prompt Get PHVs from Degraded plan info best/worst above
prompt ========================================================


accept best_phv default 0 prompt 'Enter the phv with the best elapsed time: '
accept worst_phv default 0 prompt 'Enter the phv with the worst elapsed time:'

prompt
prompt ******* B E S T   P L A N *******
prompt 
SELECT * FROM table(DBMS_XPLAN.DISPLAY_AWR('&sql_id',&best_phv,null,'ADVANCED -OUTLINE'));
prompt
prompt ******* W O R S T   P L A N *******
prompt 
SELECT * FROM table(DBMS_XPLAN.DISPLAY_AWR('&sql_id',&worst_phv,null,'ADVANCED -OUTLINE'));

set lines 2000
col hint format a150 word_wrapped
break on phv skip 1

prompt
prompt ========================================================
prompt Plan differences (from outline hints) for best and worst
prompt ========================================================

select &best_phv phv, extractvalue(value(tab),'/hint') hint
from table(select xmlsequence(extract(xmltype(other_xml),'/other_xml/outline_data/hint')) 
             from dba_hist_sql_plan p, v$database v
            where sql_id = '&sql_id' and p.dbid = v.dbid and plan_hash_value = &best_phv and other_xml is not null) tab
minus
select &best_phv phv, extractvalue(value(tab),'/hint')
from table(select xmlsequence(extract(xmltype(other_xml),'/other_xml/outline_data/hint')) 
             from dba_hist_sql_plan p, v$database v
            where sql_id = '&sql_id' and p.dbid = v.dbid and plan_hash_value = &worst_phv and other_xml is not null) tab
union
select &worst_phv phv, extractvalue(value(tab),'/hint')
from table(select xmlsequence(extract(xmltype(other_xml),'/other_xml/outline_data/hint')) 
             from dba_hist_sql_plan p, v$database v
            where sql_id = '&sql_id' and p.dbid = v.dbid and plan_hash_value = &worst_phv and other_xml is not null) tab
minus
select &worst_phv phv, extractvalue(value(tab),'/hint')
from table(select xmlsequence(extract(xmltype(other_xml),'/other_xml/outline_data/hint')) 
             from dba_hist_sql_plan p, v$database v
            where sql_id = '&sql_id' and p.dbid = v.dbid and plan_hash_value = &best_phv and other_xml is not null) tab
;

prompt
prompt ========================================================
prompt

undef sql_id
undef phv
undef nodays

clear breaks
clear columns

set head on
set timing on
set feed on
