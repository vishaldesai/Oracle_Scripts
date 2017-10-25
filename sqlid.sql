set linesize 500
col sql_sql_text head SQL_TEXT format a200 word_wrap
col sql_child_number head CH# for 999
col rows_per_fetch format 99999999999
col rows_processed format 99999999999
col SQL_PROFILE format a20
col	SQL_PATCH format a20
col SQL_PLAN_BASELINE format a20
col rows_per_fetch format 9999999999999
col cpu_sec format 999999999
col cpu_sec_exec format 9999999999
col ela_sec format 999999999999
col last_active_dt format a20


prompt Show SQL text, child cursors and execution stats for SQLID &1 child  from gv$sql

select 
  inst_id,
	hash_value,
	plan_hash_value,
	child_number	sql_child_number,
	sql_text sql_sql_text
from 
	gv$sql 
where 
	sql_id = ('&1')
--and child_number in ( )
order by
	sql_id,
	hash_value,
	child_number
/

select 
  inst_id,
	child_number	sql_child_number,
	--address		parent_handle,
	child_address   object_handle,
	plan_hash_value plan_hash,
	parse_calls parses,
	loads h_parses,
	executions,
	fetches,
	rows_processed,
  round(rows_processed/nullif(fetches,0)) rows_per_fetch,
	--round(cpu_time/1000000) cpu_sec,
	--cpu_time,
	--round(cpu_time/NULLIF(executions,0)/1000000) cpu_sec_exec,
	--round(elapsed_time/1000000) ela_sec,
	elapsed_time,
	elapsed_time/executions,
	buffer_gets LIOS,
	disk_reads PIOS,
	sorts
--	address,
--	sharable_mem,
--	persistent_mem,
--	runtime_mem,
--   , PHYSICAL_READ_REQUESTS         
--   , PHYSICAL_READ_BYTES            
--   , PHYSICAL_WRITE_REQUESTS        
--   , PHYSICAL_WRITE_BYTES           
--   , IO_CELL_OFFLOAD_ELIGIBLE_BYTES 
--   , IO_INTERCONNECT_BYTES          
--   , IO_CELL_UNCOMPRESSED_BYTES     
--   , IO_CELL_OFFLOAD_RETURNED_BYTES 
  ,	users_executing
  , to_char(last_active_time,'MM/DD/YY HH24:MI') last_active_dt
  ,	SQL_PROFILE
	, SQL_PATCH
	, SQL_PLAN_BASELINE
from 
	gv$sql
where 
	sql_id = ('&1')
--and child_number in ()
order by
	sql_id,
	hash_value,
	child_number
/





