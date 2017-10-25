set linesize 200
set pages 200
set verify off
column event_name format a40
column "Tot CPU_TIME_DELTA" format 9999999999999999
column "Tot ELAPSED_TIME_DELTA" format 9999999999999999
column "Tot IOWAIT_DELTA" format 9999999999999999
column "Tot BUFFER_GETS_DELTA" format 9999999999999999
column "Tot DISK_READS_DELTA" format 9999999999999999
column "Tot CLWAIT_DELTA" format 9999999999999999
column "Tot CCWAIT_DELTA" format 9999999999999999
column "Tot SORTS_DELTA" format 9999999999999999
column "Tot DIRECT_WRITES_DELTA" format 9999999999999999
column "Tot PHYSICAL_READ_REQUESTS_DELTA" format 9999999999999999
column "Tot PHYSICAL_READ_BYTES_DELTA" format 9999999999999999
column "Tot PHYSICAL_WRITE_REQUESTS_DELTA" format 9999999999999999
column dt heading 'Date/Hour' format a11

--accept p_inst number default 1 prompt 'Instance Number (default 1)     : '
accept p_days number default 7 prompt 'Report Interval (default 7 days): '


set linesize 500
set pages 9999	 
select * from (
select min(snap_id) as snap_id,  
		     to_char(start_time,'MM/DD/YY') as dt, to_char(start_time,'HH24') as hr
	from (
	select snap_id, s.instance_number, begin_interval_time start_time, 
		   end_interval_time end_time, snap_level, flush_elapsed,
		   lag(s.startup_time) over (partition by s.dbid, s.instance_number 
		   					   order by s.snap_id) prev_startup_time,
		   s.startup_time
	from  dba_hist_snapshot s, gv$instance i
	where begin_interval_time between trunc(sysdate)-&p_days and sysdate 
	and   s.instance_number = i.instance_number
--	and   s.instance_number = &p_inst
	order by snap_id
	)
	group by to_char(start_time,'MM/DD/YY') , to_char(start_time,'HH24') 
	order by snap_id, start_time )
	pivot
	(sum(snap_id)
	 for hr in ('00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23')
	 )
	 order by dt;

accept ssnap      prompt 'Enter value for start snap_id   :'
accept esnap      prompt 'Enter value for end snap_id     :'
select 'CPU_TIME_DELTA' as metric_name from dual
union all
select 'ELAPSED_TIME_DELTA' as metric_name from dual
union all
select 'IOWAIT_DELTA' as metric_name from dual
union all
select 'BUFFER_GETS_DELTA' as metric_name  from dual
union all
select 'DISK_READS_DELTA' as metric_name from dual
union all
select 'CLWAIT_DELTA' as metric_name from dual
union all
select 'CCWAIT_DELTA' as metric_name from dual
union all
select 'SORTS_DELTA' as metric_name from dual
union all
select 'DIRECT_WRITES_DELTA' as metric_name from dual
union all
select 'PHYSICAL_READ_REQUESTS_DELTA' as metric_name from dual
union all
select 'PHYSICAL_READ_BYTES_DELTA' as metric_name from dual
union all
select 'PHYSICAL_WRITE_REQUESTS_DELTA' as metric_name from dual;


accept  metric     prompt 'Enter metric name from above		:'
accept  topn       prompt 'Enter top n=	:'
--accept  inst_no    prompt 'Enter instance number:'

set head off
SELECT '----------SORTED by sum of metric----------------------------------------------------------' from dual;
set head on

SELECT sql_id, round(&metric/executions_delta,0) as "&metric/exec", &metric as "Tot &metric", executions_delta as "Tot executions"
FROM
  (SELECT sql.sql_id ,
          sum(sql.executions_delta) as executions_delta,
          sum(&metric) as &metric
  FROM dba_hist_sqlstat SQL,
    dba_hist_snapshot s
  WHERE s.snap_id = sql.snap_id
  AND   s.instance_number = sql.instance_number
--  AND s.instance_number = &p_inst
  AND s.snap_id   >= &ssnap
  AND s.snap_id   <= &esnap
  AND sql.parsing_schema_name not in ('SYS','SYSTEM','SYSTEM2','DBSNMP')
  group by sql.sql_id
  ORDER BY 3 DESC
  )
WHERE rownum <= &topn;

set head off
SELECT '----------SORTED by sum of metric/exec-----------------------------------------------------' from dual;
set head on

select sql_id, me as "&metric/exec", metric as "Tot &metric", executions_delta as "Tot executions"
from
(SELECT sql_id, round(metric/executions_delta,0) as me, metric , executions_delta 
FROM
  (SELECT sql.sql_id ,
          sum(sql.executions_delta) as executions_delta,
          sum(&metric) as metric,
          sum(&metric)/sum(sql.executions_delta) as mpe
  FROM dba_hist_sqlstat SQL,
    dba_hist_snapshot s
  WHERE s.snap_id = sql.snap_id
  AND   s.instance_number = sql.instance_number
  --AND s.instance_number = &p_inst
  AND s.snap_id   >= &ssnap
  AND s.snap_id   <= &esnap
  AND sql.parsing_schema_name not in ('SYS','SYSTEM','SYSTEM2','DBSNMP')
  group by sql.sql_id
  --having sum(sql.executions_delta)>0
   order by 4 desc
   )
)
WHERE rownum <= &topn;

clear columns
clear breaks
undef p_inst
undef p_days