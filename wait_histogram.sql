-- File name:   wait_histogram.sql
-- Purpose:     Display Wait counts, Wait time milli second bucket and absolute and rolling percentage
--
-- Author:      Vishal Desai
-- Copyright:   TBD
--      
-- Pre req:     NA  
-- Run as:	    dba/sysdba    
-- Usage:       @wait_histogram.sql direct%path%read
-- 				Enter value for event_name:direct%path%read

set linesize 200
set pages 200
set verify off
column event format a35
column wait_time_milli_range format a30

--break on report
--compute sum of perct_wc on report
--compute sum of perct_tim on report
/*
select event,  nvl(lag(wait_time_milli) over (order by wait_time_milli),0) ||'-'|| wait_time_milli as wait_time_milli_range,
               wait_count,
               round(wait_count * 100 / (sum(wait_count) over())) as Perct_wc,
               round(wait_time_milli * wait_count * 100 / (sum(wait_time_milli * wait_count) over())) as perct_tim
from v$event_histogram where event like '%&&event_name' 
order by wait_time_milli desc;

clear computes
*/

col pctwaitcount heading "% Wait|Count" format 9999999
col rolpctwaitcount heading "Roll % Wait|Count" format 9999999
col pctwaittim heading "% Wait|Time" format 9999999
col rolpctwaittim heading "Roll % Wait|Time" format 9999999


select event,
       nvl(lag(wait_time_milli) over (order by wait_time_milli),0) ||'-'|| wait_time_milli as wait_time_milli_range,
       wait_count,
       perct_wc as "pctwaitcount",
       sum(perct_wc) over(order by wait_time_milli desc rows unbounded preceding) as "rolpctwaitcount",
       perct_tim as "pctwaittim",
       round(sum(perct_tim) over(order by wait_time_milli desc rows unbounded preceding)) as "rolpctwaittim",
       last_update_time
  from (select event,
               wait_time_milli,
               wait_count,
               round(wait_count * 100 / (sum(wait_count) over())) as Perct_wc,
               round(wait_time_milli * wait_count * 100 / (sum(wait_time_milli * wait_count) over())) as perct_tim,
               last_update_time
          from v$event_histogram
         where (event like '%&1' )
         order by wait_time_milli desc)
		 order by wait_time_milli desc;

		 /*
select totwaittim/totwait as "Max wait time ms" from 
(select event,sum(wait_count) as totwait,sum (wait_time_milli*wait_count) as totwaittim from v$event_histogram where
event like '%&&event_name' group by event);
*/

select totwaittim/totwait as "Avg wait time ms" from (
select event,sum(wait_count) as totwait,sum(totwaittim1*wait_count) as totwaittim from(
select event, wait_count , ((nvl(lag(wait_time_milli) over (order by wait_time_milli),0) + wait_time_milli)/2) as totwaittim1 from v$event_histogram where
event like '%&&1' )
group by event);


undefine event_name