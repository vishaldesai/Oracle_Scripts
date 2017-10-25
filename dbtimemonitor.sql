set head off
set feed off
set linesize 200
set pages 9999
set feedback off
set verify off
set pagesize 0

--accept usr      prompt 'Enter user     :'
--accept pwd      prompt 'Enter password :' HIDE

set term off

spool C:\Users\U267399\Desktop\Tools\dominicgiles\dbtimemonitorOct012012\dbtimemonitor\bin\databases.xml

select '<?xml version = ' || '''' || '1.0' || '''' || ' encoding = ' || '''' || 'UTF-8' || '''' || '?>'  from dual
union all
select '<WaitMonitor Title="Monitored Databases" xmlns="http://www.dominicgiles.com/waitmonitor">' from dual
union all
select  '<MonitoredDatabase><ConnectString>//' || a.host_name || 'v.wellsfargo.com:3202/' || b.name || '</ConnectString><Comment></Comment><Username>' || '&1' || '</Username><Password>' || '&2' || '</Password></MonitoredDatabase>'  from gv$instance a, v$database b
union all
select '</WaitMonitor>' from dual;

spool off
set term on
exit




