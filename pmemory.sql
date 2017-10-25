select spid,program,pga_used_mem,pga_alloc_mem
from v$process   where spid=&&1
order by 4 desc;

select b.spid, a.category, a.allocated, a.used from
v$process_memory a, v$process b
where a.pid=b.pid
and b.spid=&&1
order by b.spid,a.category;

select b.spid,s.sid,s.username, a.category, a.allocated, a.used from
v$process_memory a, v$process b, v$session s
where a.pid=b.pid
and b.addr = s.paddr
order by 5;