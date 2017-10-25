-- File name	: refresh_sql.sql
-- Purpose		: Refresh output from SQL  at specific interval of time
--
-- Author		: Vishal Desai
-- Copyright	: TBD
--      
-- Pre req		:      
-- Run as		: dba/sysdba    
-- Usage		: @refresh_sql.sql "select inst_id,sql_id,plan_hash_value,executions,elapsed_time from gv$sql where sql_id=''bt38cac7gxwnx'' order by 1;" 5 5


set feed off
set head off
set echo off
set term off
set linesize 500
set verify off
spool refresh_sql_1.sql
set feedback off
set feed off
set serveroutput on
whenever sqlerror exit 
select cmd from (
--select '@' || '&1'  as cmd from dual
select  '&1'  as cmd from dual
union all
select 'exec dbms_lock.sleep(&2);' as cmd from dual
union all
select 'clear scr' as cmd from dual
) , (select rownum from dual connect by level <=&3) ;
spool off
set term on
set serveroutput on
set head on
clear scr
@refresh_sql_1.sql