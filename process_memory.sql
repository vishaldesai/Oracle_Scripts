rem
rem     Simple script to check memory usage for a given SID
rem     Last tested
rem             10.2.0.3
rem
 
define m_sid = &1
 
column name format a40
 
column  value       format  999,999,999,999
 
column  category    format  a10
column  allocated   format  999,999,999,999
column  used        format  999,999,999,999
column  max_allocated   format  999,999,999,999
 
column  pga_used_mem        format  999,999,999,999
column  pga_alloc_mem       format  999,999,999,999
column  pga_freeable_mem    format  999,999,999,999
column  pga_max_mem     format  999,999,999,999
 
select
    name, value
from
    v$sesstat ss,
    v$statname sn
where
    sn.name like '%ga memory%'
and ss.statistic# = sn.statistic#
and ss.sid = &m_sid
;
 
select
    category,
    allocated,
    used,
    max_allocated
from
    v$process_memory
where
    pid = (
        select  pid
        from    v$process
        where
            addr = (
                select  paddr
                from    V$session
                where   sid = &m_sid
            )
        )
;
 
select
    pga_used_mem,
    pga_alloc_mem,
    pga_freeable_mem,
    pga_max_mem
from
    v$process
where
    addr = (
        select  paddr
        from    V$session
        where   sid = &m_sid
    )
;