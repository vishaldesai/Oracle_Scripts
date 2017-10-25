set feed on
set head on
set echo on
select name,value from v$sysstat where name like 'Parallel operations%';