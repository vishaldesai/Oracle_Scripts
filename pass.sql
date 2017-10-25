set linesize 200
set pages 200
column hostname format a20
column typ format a5
column dbname format a10
select platform,typ,hostname,dbname,username,pass,environment from APWSOWN.pass
where lower(hostname) like '%&1%';