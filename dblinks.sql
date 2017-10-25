column owner format a30
column db_link format a20
column username format a30
column host format a200
set pages 999
set linesize 500
select owner,db_link,username,host from dba_db_links
order by 1,2;