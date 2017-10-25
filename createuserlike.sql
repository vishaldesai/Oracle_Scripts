set head off
set pages 0
set long 9999999
set linesize 400
column cu format a200
set feed off
set echo off
set verify off
whenever sqlerror continue
exec dbms_metadata.set_transform_param(dbms_metadata.SESSION_TRANSFORM,'SQLTERMINATOR',TRUE);


spool c:\temp\scripts\user_script.sql
select 'set feed on' from dual;
select 'set echo on' from dual;
select 'WHENEVER SQLERROR CONTINUE' from dual;
select replace(cu,'&&1','&&2') as cu from (
SELECT DBMS_METADATA.GET_DDL('USER', '&&1') as cu FROM dual
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('ROLE_GRANT', '&&1') as cu FROM dual 
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('SYSTEM_GRANT', '&&1') as cu FROM dual
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('OBJECT_GRANT', '&&1') as cu FROM dual
UNION ALL
SELECT DBMS_METADATA.GET_GRANTED_DDL('TABLESPACE_QUOTA', '&&1') as cu FROM dual
);

select 'alter user ' || '&&2' || ' identified by ifmc;' from dual;
spool off;

@c:\temp\scripts\user_script.sql


