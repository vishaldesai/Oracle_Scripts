select name,value from v$sysstat
where name like '%&name%'
/