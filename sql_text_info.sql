accept sql_text prompt "Please enter sql text: "
 
set pagesize 999
set lines 200
col sql_text format a36 trunc
col inst for 99
col total_row for 99999999
col execs for 9,999,999
col avg_etime for 99,999.999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col begin_interval_time for a30
col hash_value for 9999999999
col "interval time" for a20
break on hash_value on startup_time skip 1
 
select to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss') "interval time", ss.instance_number inst, s.sql_id, plan_hash_value hash_value,
nvl(executions_delta,0) execs,
elapsed_time_delta/1000000 etime,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
buffer_gets_delta lio,
(buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta)) avg_lio,
trim(replace(dbms_lob.substr(sql_text,36, 1),chr(9),'')) sql_text
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS, DBA_HIST_SQLTEXT ST
where
dbms_lob.substr(sql_text,3999,1) like  '&sql_text'
and ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
and s.sql_id = st.sql_id
and executions_delta > 0
and ss.snap_id >= 282463
and ss.snap_id<=282506
and s.sql_id = st.sql_id
order by begin_interval_time desc
;
undef sql_text