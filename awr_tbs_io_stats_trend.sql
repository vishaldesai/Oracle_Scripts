set ver off pages 50000 lines 140 tab off
set linesize 400
set pages 9999

col tsname     format a30           heading 'Tablespace';
col reads      format 9,999,999,999,990 heading 'Reads' ;
col atpr       format 990.0         heading 'Av|Rd(ms)'     just c;
col writes     format 999,999,999,990   heading 'Writes';
col waits      format 9,999,999,999     heading 'Buffer|Waits'
col atpwt      format 990.0         heading 'Av Buf|Wt(ms)' just c;
col rps        format 99,999,999        heading 'Av|Reads/s'    just c;
col wps        format 99,999,999       heading 'Av|Writes/s'   just c;
col bpr        format 999.0         heading 'Av|Blks/Rd'    just c;
col ios        noprint
col end_snap_time format a20
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '
accept tsname           prompt 'Enter Tablespace name     : '



WITH base_line
     AS (SELECT snp.end_interval_time,
                dhfs.snap_id,
                dhfs.instance_number,
                dhfs.TSNAME,
                dhfs.BLOCK_SIZE,
                dhfs.PHYRDS,
                dhfs.PHYWRTS,
                dhfs.SINGLEBLKRDS,
                dhfs.READTIM,
                dhfs.WRITETIM,
                dhfs.SINGLEBLKRDTIM,
                dhfs.PHYBLKRD,
                dhfs.PHYBLKWRT,
                dhfs.WAIT_COUNT,
                dhfs.TIME
           FROM DBA_HIST_FILESTATXS dhfs, DBA_HIST_SNAPSHOT snp
          WHERE     dhfs.instance_number = snp.instance_number
                AND dhfs.snap_id = snp.snap_id
                AND snp.instance_number =
                       DECODE (&inst, 0, snp.instance_number, &inst)
                AND snp.begin_interval_time >=
                       TRUNC (SYSDATE) - &days_history
                AND dhfs.tsname = '&tsname')
  SELECT  b2.instance_number
         ,TO_CHAR (b2.end_interval_time, 'MM/DD/YY HH24:MI:SS') end_snap_time
         ,b2.tsname
         ,SUM (b2.phyrds - NVL (b1.phyrds, 0)) reads
         ,SUM (b2.phyrds - NVL (b1.phyrds, 0)) / 1800 rps
         ,DECODE (SUM (b2.phyrds - NVL (b1.phyrds, 0)),0, 0,(  SUM (b2.readtim - NVL (b1.readtim, 0))/ SUM (b2.phyrds - NVL (b1.phyrds, 0)))* 10)         atpr
         ,DECODE (SUM (b2.phyrds - NVL (b1.phyrds, 0)),0, TO_NUMBER (NULL),SUM (b2.phyblkrd - NVL (b1.phyblkrd, 0))/ SUM (b2.phyrds - NVL (b1.phyrds, 0))) bpr
         ,SUM (b2.phywrts - NVL (b1.phywrts, 0)) writes
         ,SUM (b2.phywrts - NVL (b1.phywrts, 0)) / 1800 wps
         ,SUM (b2.wait_count - NVL (b1.wait_count, 0)) waits
         ,DECODE (SUM (b2.wait_count - NVL (b1.wait_count, 0)),0, 0,(  SUM (b2.time - NVL (b1.time, 0))/ SUM (b2.wait_count - NVL (b1.wait_count, 0)))* 10) atpwt
         ,SUM (b2.phyrds - NVL (b1.phyrds, 0))  + SUM (b2.phywrts - NVL (b1.phywrts, 0))         ios
    FROM base_line b1, base_line b2
   WHERE     b1.instance_number = b2.instance_number
         AND b1.snap_id + 1 = b2.snap_id
   GROUP BY
      b2.instance_number
         ,TO_CHAR (b2.end_interval_time, 'MM/DD/YY HH24:MI:SS') 
         ,b2.tsname
ORDER BY 1, 2   ;