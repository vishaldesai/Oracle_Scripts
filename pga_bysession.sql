column sid format 9999
colum usr format a12
column stat format a25
column val format 9999999999999
column bytes format 999999999999
set head on 
set linesize 150
set pages 200

select c.sid sid,c.username usr,a.name stat,b.value bytes from 
v$statname a, v$sesstat b, v$session c
where a.statistic# = b.statistic#
and b.sid = c.sid
and a.name like '%pga%'
and c.status='ACTIVE' and
c.username is not null
order by c.sid,usr;