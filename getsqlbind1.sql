set linesize 500
set pages 9999
set long 9999999

select xmltype(binds_xml) from v$sql_monitor where sid = &sid ;
--and status = 'EXECUTING';