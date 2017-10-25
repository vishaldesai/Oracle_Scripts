set linesize 200
set pages 2000
column value_string format a20
column name format a32
column sid format 99999
column username format a30
select sesion.sid,
       sesion.username,
       sesion.sql_id,
       sesion.sql_child_number,
       sql_bind_capture.name,
       sql_bind_capture.value_string
  from v$sql_bind_capture sql_bind_capture, v$session sesion
 where sesion.sql_hash_value = sql_bind_capture.hash_value
   and sesion.sql_address    = sql_bind_capture.address
   and sesion.sid = &sid;


set linesize 200
set pages 2000
column value_string format a20
column name format a32
column sid format 99999
column username format a30
column last_captured format a20
alter session set nls_date_format='MM/DD/YY HH24:MI';
select sesion.sql_id,
       sql_bind_capture.name,
       sql_bind_capture.datatype,
       sql_bind_capture.datatype_string,
       sql_bind_capture.value_string,
       sql_bind_capture.last_captured
  from gv$sql_bind_capture sql_bind_capture, gv$sql sesion
 where sesion.sql_id    = sql_bind_capture.sql_id
   and sesion.inst_id        = sql_bind_capture.inst_id
   and sesion.sql_id = '&sql_id'
   order by last_captured;