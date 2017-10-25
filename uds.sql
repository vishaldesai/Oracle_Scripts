--orignial script from Tanel poder
--addendum from https://aprakash.wordpress.com/2015/04/12/ora-01628-max-extents-32765-reached-for-rollback-segment-_syssmuxxx/


prompt Show undo statistics from V$UNDOSTAT....
col uds_mb head MB format 999999.99
col uds_maxquerylen head "MAX|QRYLEN" format 999999
col uds_maxqueryid  head "MAX|QRY_ID" format a13 
col uds_ssolderrcnt head "ORA-|1555" format 999
col uds_nospaceerrcnt head "SPC|ERR" format 99999
col uds_unxpstealcnt head "UNEXP|STEAL" format 99999
col uds_expstealcnt head "EXP|STEAL" format 99999

select * from (
    select 
        begin_time, 
        to_char(end_time, 'HH24:MI:SS') end_time, 
        txncount, 
        undoblks * (select block_size from dba_tablespaces where upper(tablespace_name) = 
                        (select upper(value) from v$parameter where name = 'undo_tablespace')
                   ) / 1048576 uds_MB ,
        maxquerylen uds_maxquerylen,
        maxqueryid  uds_maxqueryid,
        ssolderrcnt uds_ssolderrcnt,
        nospaceerrcnt uds_nospaceerrcnt,
 	unxpstealcnt uds_unxpstealcnt,
	expstealcnt uds_expstealcnt
    from 
        v$undostat
    order by
        begin_time desc
) where rownum <= 30;

SELECT
       segment_name
     , ROUND(NVL(SUM(act),0)  /(1024*1024*1024),3 ) "ACT GB BYTES"
     , ROUND(NVL(SUM(unexp),0)/(1024*1024*1024),3) "UNEXP GB BYTES"
     , ROUND(NVL(SUM(exp),0)  /(1024*1024*1024),3) "EXP GB BYTES"
     , NO_OF_EXTENTS
FROM
       (
              SELECT
                     segment_name
                   , NVL(SUM(bytes),0) act
                   ,00 unexp
                   , 00 exp
                   , COUNT(*) NO_OF_EXTENTS
              FROM
                     DBA_UNDO_EXTENTS
              WHERE
                     status          ='ACTIVE'
                 AND tablespace_name =
                     (
                            SELECT
                                   value
                            FROM
                                   v$parameter
                            WHERE
                                   name='undo_tablespace'
                     )
              GROUP BY
                     segment_name
              UNION
              SELECT
                     segment_name
                   ,00 act
                   , NVL(SUM(bytes),0) unexp
                   , 00 exp
                   , COUNT(*) NO_OF_EXTENTS
              FROM
                     DBA_UNDO_EXTENTS
              WHERE
                     status          ='UNEXPIRED'
                 AND tablespace_name =
                     (
                            SELECT
                                   value
                            FROM
                                   v$parameter
                            WHERE
                                   name='undo_tablespace'
                     )
              GROUP BY
                     segment_name
              UNION
              SELECT
                     segment_name
                   , 00 act
                   , 00 unexp
                   , NVL(SUM(bytes),0) exp
                   , COUNT(*) NO_OF_EXTENTS
              FROM
                     DBA_UNDO_EXTENTS
              WHERE
                     status          ='EXPIRED'
                 AND tablespace_name =
                     (
                            SELECT
                                   value
                            FROM
                                   v$parameter
                            WHERE
                                   name='undo_tablespace'
                     )
              GROUP BY
                     segment_name
       )
GROUP BY
       segment_name
     , NO_OF_EXTENTS
HAVING
       NO_OF_EXTENTS >= 30
ORDER BY
       5 DESC;
       
break on report
compute sum label Total of Extent_Count Extent_MB on report
col Extent_MB format 999,999.00


SELECT
       segment_name
     , bytes/1024 "Extent_Size_KB"
     , COUNT(extent_id) "Extent_Count"
     , bytes * COUNT(extent_id) / power(1024, 2) "Extent_MB"
FROM
       dba_undo_extents
WHERE
       segment_name = &undoseg
GROUP BY
       segment_name
     , bytes
ORDER BY
       1
     , 3 DESC;