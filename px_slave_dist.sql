set head on
-- only valid for current sql statement
select dfo_number, tq_id,server_type, process, num_rows,bytes from v$pq_tqstat
order by dfo_number,tq_id,server_type desc, process;
