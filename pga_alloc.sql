column name format a30
column value format 999,999,999,999
column unit format a10
set linesize 150
set head on
select name,value,unit from v$pgastat where name in
('aggregate PGA target parameter','maximum PGA allocated');