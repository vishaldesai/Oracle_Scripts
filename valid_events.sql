select KSLEDNAM event from  x$ksled
where KSLEDNAM like nvl('&event_name',KSLEDNAM)
order by 1
/


select name from v$event_name
where name like nvl('&event_name',name)
order by 1
/