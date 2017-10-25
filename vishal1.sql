

set long 99999999



accept v_sql_id prompt "Enter the SQL_ID to look at :" 
accept v_sql_exec_id prompt "Enter the associated SQL_EXEC_ID to look at : "
accept v_sql_exec_start prompt "Enter the Execution Start Date (DD/MM/YYYY HH24:MI:SS) : "

col id format 999
column operation format a120
col object format a30
set colsep '|'
set lines 500
set linesize 500

select * from 
(select SQL_PLAN_LINE_ID,SQL_PLAN_OPERATION,sql_plan_options,seq#,event from 
v$active_session_history where sql_id='&&v_sql_id' order by sample_id desc)
where rownum <=5;

set head on
select p.id
    --,m.process_name
    ,rpad(' ',p.depth*2, ' ')||p.operation operation
    ,p.object_name object
    ,p.cardinality card
    ,p.cost cost
    ,substr(m.status,1,4) status
    ,sum(m.output_rows)
    ,sum(m.physical_read_requests)
    ,round(sum(m.physical_read_bytes)/1024/1024)
    ,sum(m.physical_write_requests)
    ,round(sum(m.physical_write_bytes)/1024/1024)
 from v$sql_plan p, v$sql_plan_monitor m
where p.sql_id=m.sql_id
 and p.child_address=m.sql_child_address
 and p.plan_hash_value=m.sql_plan_hash_value
 and p.id=m.plan_line_id
 and m.sql_id='&&v_sql_id'
 and m.sql_exec_id=&&v_sql_exec_id
 and m.sql_exec_start=to_date('&&v_sql_exec_start','MM/DD/YY HH24:MI:SS')
group by
  p.id
 --,m.process_name
 ,rpad(' ',p.depth*2, ' ')||p.operation
 ,p.object_name 
 ,p.cardinality 
 ,p.cost
 ,substr(m.status,1,4)
order by p.id
;

set colsep ' '

