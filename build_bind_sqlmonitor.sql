-------------------------------------------------------------------------------------------------------
--
-- File name:   build_bind_sqlmonitor.sql
--
-- Purpose:     Build SQL*Plus script with variable definitions from gv$sql_monitor.
--
-- Author:      Vishal Desai
--
-- Description: 

-- Usage:       This scripts prompts for three values. Provide input for at least one prompt and rest
--				is self explanatory.
--
--
-- http://vishaldesai.wordpress.com/2014/01/24/build-bind-variables-from-vsql_monitor-binds_xml-column/
-------------------------------------------------------------------------------------------------------

accept key      prompt 'Enter the value for Key if known       : '
accept sid      prompt 'Enter the value for Sid if known       : '
accept sql_id   prompt 'Enter the value for sql_id if known    : '


set pages 900
set feed off
set echo off
set verify off
set head on
set linesize 200
column key format 999999999999999
column username format a10 trunc
column module format a20 trunc
column program format a15 trunc
column first_refresh_time format a20 trunc
column sql_text format a20

select * from (
select inst_id,key,status,username,module,sid,sql_id,to_char(first_refresh_time,'MM/DD/YY HH24:MI:SS') as first_refresh_time,program,
substr(sql_text,1,20)  as sql_text
from gv$sql_monitor
where sid = nvl('&sid',sid)
  and key = nvl('&key',key)
  and sql_id = nvl('&sql_id',sql_id)
  and sql_text is not null
order by first_refresh_time desc) where rownum<10;
  
accept inst_id1  prompt 'Enter instance number			 : '
accept key1      prompt 'Enter Key from above       : '

set head off
select  'variable ' ||  replace(name,':','') || ' ' || dtystr || ';' from 
(select XMLTYPE.createXML(binds_xml) confval
from gv$sql_monitor
where key=&key1 and inst_id=&inst_id1) v,
xmltable('/binds/bind' passing v.confval
      columns
         name varchar2(25) path '@name',
         dtystr varchar2(25) path '@dtystr');
		 
select  case when dtystr like '%CHAR%' then 'exec ' || name || ' ' || ':=' || ' ' || '''' || value || '''' || ';'
						 when dtystr like '%RAW%' then 'exec ' || name || ' ' || ':=' || ' ' || '''' || value || '''' || ';'
             when dtystr like '%NUMB%' then 'exec ' || name || ' ' || ':=' || ' ' || value ||  ';' 
             when dtystr like '%TIMEST%' then 'exec ' || name || ' ' || ':=' || ' ' || '''' || value || '''' || ';'
	    end as h
from 
(select XMLTYPE.createXML(binds_xml) confval
from gv$sql_monitor
where key=&key1 and inst_id=&inst_id1) v,
xmltable('/binds/bind' passing v.confval
      columns
	     name varchar2(25) path '@name',
	     dtystr varchar2(25) path '@dtystr',
         value VARCHAR2(4000) path '.');

set long 9999 
select sql_text ||';' from gv$sql_monitor where key=&key1 and inst_id=&inst_id1;

undefine sid
undefine key
undefine sql_id
undefine key1
set feed on
set head on
set verify on

