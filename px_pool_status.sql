set feed on
set head on
set echo on

select * from v$px_process_sysstat
where statistic like 'Servers%';