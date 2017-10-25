col key format 9999999999999999
set colsep '|'
set linesize 400
set pages 200
column module format a50

select s.sid,sm.sql_id, sm.sql_exec_id,
    to_char(max(sm.sql_exec_start) ,'DD/MM/YYYY HH24:Mi:SS')
        as sql_exec_start,
    sm.sql_child_address child_address,
	sm.PLSQL_OBJECT_ID   ,     
	sm.PLSQL_SUBPROGRAM_ID,
    sm.module,
    sm.action,
    sm.program
  from v$sql_monitor sm, v$session s 
  where sm.sid = s.sid
    and sm.session_serial# = s.serial#
	and s.status = 'ACTIVE'
   group by s.sid , sm.sql_id, sm.sql_exec_id, sm.sql_child_address,sm.PLSQL_OBJECT_ID,sm.PLSQL_SUBPROGRAM_ID,sm.module,sm.action,sm.program
order by sql_exec_start;

set colsep ' '