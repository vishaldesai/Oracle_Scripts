-- print history info from from ash for 11.2 
-- Luca March 2012
--
-- usage @ash_h <n#_sec>
--
set pages 9999
set linesize 400
col sample_id for 999999999
col sid_ser for a10
col username for a26
col sql_id for a13
col exec_plan_ln_obj for a100 trunc
col dT for 9999
col event for a40
col "DB,CPU" for a10 justify right
col "R,W_IOPS" for a10 justify right
col "R,W_MBPS" for a10 justify right
col "PGA,TEMP_MB" for a13 justify right

break on sample_id skip 1

select sample_id,session_id||' '||session_serial# sid_ser,
       (select us.name from sys.user$ us where us.user#=user_id)||case when regexp_substr(program,' \(...') <> ' (TNS' then regexp_substr(program,' \(.+') end username,
       sql_id, round((sysdate-sql_exec_start)*24*3600,1) dT,
       --blocking_session, wait_time,time_waited
       round(100*TM_DELTA_DB_TIME/TM_DELTA_TIME,0)||', '||round(100*TM_DELTA_CPU_TIME/TM_DELTA_TIME,0) "DB,CPU", 
       round (1000000*delta_read_io_requests/delta_time,0)||', '||round(1000000*delta_write_io_requests/delta_time,0) "R,W_IOPS", 
       round(delta_read_io_bytes/delta_time,0)||', '||round(delta_write_io_bytes/delta_time,0) "R,W_MBPS",
       round(pga_allocated/1000000,0)||', '||round(temp_space_allocated/1000000,0) "PGA,TEMP_MB",
       decode(session_state,'WAITING',event,'CPU') event,
       sql_opname||'-'||sql_plan_operation||'-'||sql_plan_options||','||sql_plan_line_id||','||nullif(current_obj#,-1) exec_plan_ln_obj
from v$active_session_history  
where sample_time>systimestamp-numtodsinterval(&1,'second');

 

