col module format a15
col username format a15
col tablespace format a15
col size format 999,999,999,999
SELECT s.inst_id,s.sid,s.username,s.module,u.contents,segtype,TABLESPACE, sum((u.blocks * (
select value from v$parameter where name='db_block_size'))) "size"
FROM gv$session s, gv$sort_usage u
WHERE s.saddr=u.session_addr
and s.inst_id=u.inst_id
and u.extents > 10
group by s.inst_id,s.sid,s.username,s.module,u.contents,segtype,tablespace 
order by 1,5;

