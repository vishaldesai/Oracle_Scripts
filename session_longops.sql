COL sid format a15
COL "Time Now" format a15
COL filename format a70 heading "Backup Set"
COL mins_taken format 9990 heading "Mins Taken"
COL mb_per_min format 990.00 heading "Backup Speed|MB/Min"
COL total_mb format 999,999,990.00 heading "Backup Set|Size (MB)"
COL total_backup format 999,999,990.00 heading "Total Backup|Size (MB)"
COL total_mins format a8 heading "Total|Time(HH:MI)"
COL message format a90
set linesize 200
set pages 200


SELECT    SID
       || '.'
       || serial#  || ',@' || inst_id as SID,
       ROUND(sofar / DECODE(totalwork, 0, sofar, totalwork)
          * 100, 2) "% Complete",
       SUBSTR(TO_CHAR(SYSDATE, 'yymmdd hh24:mi:ss'), 1, 15) "Time Now",
       elapsed_seconds, MESSAGE
  FROM gv$session_longops
 WHERE ROUND(sofar / DECODE(totalwork, 0, sofar, totalwork) * 100, 2) < 100
and sofar <> totalwork;