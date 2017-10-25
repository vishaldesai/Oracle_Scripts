accept owner      prompt 'Please enter the value for owner                  : '
accept index_name prompt 'Please enter the value for index_name             : '

set linesize 350
set pages 250
col owner format a15
col object_name format a25
col savtime format a10 truncate
col object_name format a35
column suboject_name format a20
column object_type format a10

SELECT
       ob.owner
     , ob.object_name
     , ob.subobject_name
     , ob.object_type
     , obj#
     , TO_CHAR(savtime,'MM/DD/YY HH24:MI:SS')
     , flags
     , rowcnt
     , blevel
     , LEAFCNT
     , DISTKEY
     , LBLKKEY
		 , DBLKKEY
		 , CLUFAC
		 , SAMPLESIZE
		 , ANALYZETIME
		 , GUESSQ
		 , CACHEDBLK
		 , CACHEHIT
		 , LOGICALREAD
FROM
       sys.WRI$_OPTSTAT_IND_HISTORY
     , dba_objects ob
WHERE
       owner        =upper('&owner')
   AND object_name  =upper('&index_name')
   AND object_type IN ('INDEX')
   AND object_id    =obj#
ORDER BY
       analyzetime;