set head off
set feed off
set linesize 200
set pages 9999
set feedback off
set verify off
set pagesize 0

accept usr      prompt 'Enter user     :'
accept pwd      prompt 'Enter password :' HIDE

set term off

spool C:\Users\U267399\Desktop\Tools\dominicgiles\cpumonitor02092\cpumonitor\bin\cpu.xml

select '<?xml version = ' || '''' || '1.0' || '''' || ' encoding = ' || '''' || 'UTF-8' || '''' || '?>'  from dual
union all
select '<CPUMonitor Title="Compute Nodes" xmlns="http://www.dominicgiles.com/cpumonitor">' from dual
union all
select  '<MonitoredNode><HostName>'  || a.host_name || '.wellsfargo.com</HostName><Username>' || '&usr'  || '</Username><Password>' || '&pwd'  || '</Password><Port>22</Port><Comment>Oracle Linux Server</Comment></MonitoredNode>' from gv$instance a
union all
select '</CPUMonitor>' from dual;

spool off
set term on
host C:\Users\U267399\Desktop\Tools\dominicgiles\cpumonitor02092\cpumonitor\bin\cpumonitor.bat



