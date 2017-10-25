set echo off
column sid format 99999
col osuser format a10
col machine format a14
col module format a35
column username format a15
column event format a30
set pages 1000


set pages 400
set linesize 400
select s.inst_id,machine,s.username username,s.sid,sql_hash_value sql_hash_value,
w.event event,w.seconds_in_wait sec,sql_id,module,io.block_gets+io.consistent_gets gets
from gv$session_wait w,
     gv$sess_io     io,
     gv$session      s
        where  s.sid = w.sid and io.sid=w.sid and
        w.inst_id=io.inst_id and io.inst_id=s.inst_id and
        s.status='ACTIVE'
        and  w.event not in ('rdbms ipc message', 'pmon timer', 'smon timer')
        and w.inst_id=1 and io.inst_id=1 and s.inst_id=1
        order by s.inst_id,event
/
