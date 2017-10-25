select pool,name,bytes/1024/1024 MB from v$sgastat 
where lower(name) like lower('%&1%') 
or    loweR(pool) like lower('%&1%')
order by name

/
