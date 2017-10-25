set echo off
column sid format 99999
col osuser format a10
col machine format a10
col module format a35
column username format a15
column event format a30
set pages 1000


set pages 400
select machine,s.username username,s.sid,sql_hash_value sql_hash_value,
w.event event,w.seconds_in_wait sec,sql_id,module,io.block_gets+io.consistent_gets gets
from v$session_wait w,
     v$sess_io     io,
     v$session      s
        where  s.sid = w.sid and io.sid=w.sid and
        s.status='ACTIVE'
        and  w.event not in ('rdbms ipc message', 'pmon timer', 'smon timer')
        order by event
/
