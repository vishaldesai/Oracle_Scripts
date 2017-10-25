-- List AWR snapshots for specified number of days by instance
--
set linesize 200
set pages 999
col start_time for a30
col end_time for a30
col duration format a50

accept p_inst number default 1 prompt 'Instance Number (default 1)     : '
accept p_days number default 7 prompt 'Report Interval (default 7 days): '

/*
	select snap_id,  
		   case when (startup_time = prev_startup_time) or rownum = 1 then '' 
			   else 'Database bounce' end as bounce,
		   start_time, replace(end_time-start_time,'+000000000 ','') duration, snap_level
	from (
	select snap_id, s.instance_number, begin_interval_time start_time, 
		   end_interval_time end_time, snap_level, flush_elapsed,
		   lag(s.startup_time) over (partition by s.dbid, s.instance_number 
		   					   order by s.snap_id) prev_startup_time,
		   s.startup_time
	from  dba_hist_snapshot s, gv$instance i
	where begin_interval_time between sysdate-&p_days and sysdate 
	and   s.instance_number = i.instance_number
	and   s.instance_number = &p_inst
	order by snap_id
	)
	order by snap_id, start_time ;
	
	*/
	
column dt heading 'Date/Hour' format a9
set linesize 500
set pages 9999
column hr format a5	
column snap_id format a5
column 'H00' format 99999 
column '01' format 99999
column '02' format 99999
column '03' format 99999
column '04' format 99999
column '05' format 99999
column '06' format 99999
column '07' format 99999
column '08' format 99999
column '09' format 99999
column '10' format 99999
column '11' format 99999
column '12' format 99999
column '13' format 99999
column '14' format 99999
column '15' format 99999
column '16' format 99999
column '17' format 99999
column '18' format 99999
column '19' format 99999
column '20' format 99999
column '21' format 99999
column '22' format 99999
column '23' format 99999
column '24' format 99999


select * from (select * from (
select min(snap_id) as snap_id,  
		     to_char(start_time,'MM/DD/YY') as dt, 'H' || to_char(start_time,'HH24') as hr
	from (
	select snap_id, s.instance_number, begin_interval_time start_time, 
		   end_interval_time end_time, snap_level, flush_elapsed,
		   lag(s.startup_time) over (partition by s.dbid, s.instance_number 
		   					   order by s.snap_id) prev_startup_time,
		   s.startup_time
	from  dba_hist_snapshot s, gv$instance i
	where begin_interval_time between trunc(sysdate)-&p_days and sysdate 
	and   s.instance_number = i.instance_number
	and   s.instance_number = &p_inst
	order by snap_id
	)
	group by to_char(start_time,'MM/DD/YY') , to_char(start_time,'HH24') 
	order by snap_id, start_time )
	pivot
	(sum(snap_id)
	 for hr in ('H00' as H00)
	 )
	 order by dt);


clear columns
clear breaks
undef p_inst
undef p_days

