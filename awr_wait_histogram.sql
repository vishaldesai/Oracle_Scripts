
set linesize 200
set pages 200
set verify off
column event_name format a40

column dt heading 'Date/Hour' format a11
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
	and   s.instance_number = &p_inst
	order by snap_id
	)
	group by to_char(start_time,'MM/DD/YY') , to_char(start_time,'HH24') 
	order by snap_id, start_time )
	pivot
	(sum(snap_id)
	 for hr in ('00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23')
	 )
	 order by dt;



break on report
compute sum of perct_wc on report
compute sum of perct_tim on report

accept ssnap      prompt 'Enter value for start snap_id   :'
accept esnap      prompt 'Enter value for end snap_id     :'
accept pinst_no	  prompt 'Enter value for instance number :'

select event_name,
               wait_time_milli,
               wait_count,
               round(wait_count * 100 / (sum(wait_count) over())) as Perct_wc,
               round(wait_time_milli * wait_count * 100 / (sum(wait_time_milli * wait_count) over())) as perct_tim
from (
SELECT old.event_name,
  old.wait_time_milli,
  (new.wait_count - old.wait_count) as wait_count
FROM dba_hist_event_histogram old,
     dba_hist_event_histogram new
WHERE old.wait_time_milli = new.wait_time_milli
AND old.snap_id         =&&ssnap
AND new.snap_id         =&&esnap
AND old.event_name      like '%&&event_name'
AND new.event_name      like '%&&event_name'
AND old.instance_number =&&pinst_no
AND new.instance_number =&&pinst_no
ORDER BY wait_time_milli DESC)
order by wait_time_milli desc;

clear computes

col pctwaitcount heading "% Wait|Count"
col rolpctwaitcount heading "Roll % Wait|Count"
col pctwaittim heading "% Wait|Time"
col rolpctwaittim heading "Roll % Wait|Time"


select event_name,
       wait_time_milli,
       wait_count,
       perct_wc as "pctwaitcount",
       sum(perct_wc) over(order by wait_time_milli desc rows unbounded preceding) as "rolpctwaitcount",
       perct_tim as "pctwaittim",
       round(sum(perct_tim)
             over(order by wait_time_milli desc rows unbounded preceding)) as "rolpctwaittim"
  from (select event_name,
               wait_time_milli,
               wait_count,
               round(wait_count * 100 / (sum(wait_count) over())) as Perct_wc,
               round(wait_time_milli * wait_count * 100 /
                     (sum(wait_time_milli * wait_count) over())) as perct_tim
          from (SELECT old.event_name,
  old.wait_time_milli,
  (new.wait_count - old.wait_count) as wait_count
FROM dba_hist_event_histogram old,
     dba_hist_event_histogram new
WHERE old.wait_time_milli = new.wait_time_milli
AND old.snap_id         =&&ssnap
AND new.snap_id         =&&esnap
AND old.event_name      like '%&&event_name'
AND new.event_name      like '%&&event_name'
AND old.instance_number =&&pinst_no
AND new.instance_number =&&pinst_no)
         order by wait_time_milli desc);


select sum(wait_time_milli*totwait)/sum(totwait) as "Average wait time ms" from 
(SELECT old.event_name,
  old.wait_time_milli,
  (new.wait_count - old.wait_count)                   AS totwait
FROM dba_hist_event_histogram old,
     dba_hist_event_histogram new
WHERE old.wait_time_milli = new.wait_time_milli
AND old.snap_id         =&&ssnap
AND new.snap_id         =&&esnap
AND old.event_name      like '%&&event_name'
AND new.event_name      like '%&&event_name'
AND old.instance_number =&&pinst_no
AND new.instance_number =&&pinst_no)
where totwait>0
;

undefine event_name
undefine ssnap
undefine esnap
clear columns
clear breaks
undef p_inst
undef p_days