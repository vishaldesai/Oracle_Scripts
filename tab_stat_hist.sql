accept owner      prompt 'Please enter the value for owner                  : '
accept table_name prompt 'Please enter the value for table_name             : '
column owner format a30
column object_name format a45
column 
set linesize 350
set pages 250
col owner format a15
col object_name format a25
col savtime format a10 truncate
col dt format a25
SELECT ob.owner, ob.object_name, ob.subobject_name, ob.object_type,obj#, to_char(savtime,'MM/DD/YY HH24:MI:SS') dt, flags, rowcnt, blkcnt, avgrln ,samplesize, analyzetime, cachedblk, cachehit, logicalread
FROM sys.WRI$_OPTSTAT_TAB_HISTORY, dba_objects ob
WHERE owner=upper('&owner')
and object_name=upper('&table_name')
and object_type in ('TABLE')
and object_id=obj#
order by analyzetime;