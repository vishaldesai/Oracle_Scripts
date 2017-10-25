COL sys_value HEAD "VALUE" FOR 9999999999999999999999999

COL name format a65
select inst_id,name, value sys_value from gv$sysstat where lower(name) like lower('%&1%')
order by 1,2;