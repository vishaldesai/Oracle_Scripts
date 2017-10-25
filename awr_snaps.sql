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


column	HH00	format	999999
column	HH01	format	999999
column	HH02	format	999999
column	HH03	format	999999
column	HH04	format	999999
column	HH05	format	999999
column	HH06	format	999999
column	HH07	format	999999
column	HH08	format	999999
column	HH09	format	999999
column	HH10	format	999999
column	HH11	format	999999
column	HH12	format	999999
column	HH13	format	999999
column	HH14	format	999999
column	HH15	format	999999
column	HH16	format	999999
column	HH17	format	999999
column	HH18	format	999999
column	HH19	format	999999
column	HH20	format	999999
column	HH21	format	999999
column	HH22	format	999999
column	HH23	format	999999
column	HH24	format	999999



select * from (select * from (
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
	and   s.instance_number = &p_inst
	order by snap_id
	)
	group by to_char(start_time,'MM/DD/YY') , to_char(start_time,'HH24') 
	order by snap_id, start_time )
	pivot
	(sum(snap_id)
	 for hr in ('00' as HH00,
	            '01' as HH01,
	            '02' as HH02,
	            '03' as HH03,
	            '04' as HH04,
	            '05' as HH05,
	            '06' as HH06,
	            '07' as HH07,
	            '08' as HH08,
	            '09' as HH09,
	            '10' as HH10,
	            '11' as HH11,
	            '12' as HH12,
	            '13' as HH13,
	            '14' as HH14,
	            '15' as HH15,
	            '16' as HH16,
	            '17' as HH17,
	            '18' as HH18,
	            '19' as HH19,
	            '20' as HH20,
	            '21' as HH21,
	            '22' as HH22,
	            '23' as HH23)
	 )
	 order by dt);


clear columns
clear breaks
undef p_inst
undef p_days

