-- File name	: refresh.sql
-- Purpose		: Refresh output from other scripts at specific interval of time
--
-- Author		: Vishal Desai
-- Copyright	: TBD
--      
-- Pre req		:      
-- Run as		: dba/sysdba    
-- Usage		: @refresh swact 5 5
--				: @refresh "wait_histogram direct%path%read" 5 5


set feed off
set head off
set echo off
set term off
set linesize 500
set verify off
spool refresh_1.sql
set feedback off
set feed off
set serveroutput on
whenever sqlerror exit 
select cmd from (
select '@' || '&1'  as cmd from dual
--select  '&1'  as cmd from dual
--select 'exec dbms_lock.sleep(&2);' as cmd from dual
--union all
--select 'host ping 1.1.1.1 -n 1 -w &2' || '000' as cmd from dual
--union all
--select 'clear scr' as cmd from dual
--select '1' as cmd from dual
) , (select rownum from dual connect by level <=&3) ;
spool off
set term on
set serveroutput on
set head on
clear scr
@refresh_1.sql