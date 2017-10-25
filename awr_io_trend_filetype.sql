set ver off pages 50000 lines 140 tab off
set linesize 300
set pages 9999
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '

column filetype_name format a40
select distinct filetype_name from v$iostat_file;

accept filetype_name    prompt 'Enter filetype_name			: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

col inst for 9
col snap_time for a19
col filetype_name format a30
column SM_R_MB 		heading "Small|Read MB"                                                                                                                                                                     
column SM_W_MB 		heading "Small|Write MB" 
column SM_R_RQ 		heading "Small|Read Reqs"                                                                                                         
column SM_W_RQ 		heading "Small|Write Reqs" 
column LG_R_MB 		heading "Large|Read MB"                                                                                                        
column LG_W_MB 		heading "Large|Write MB"                                                                                                                                                                                                             
column LG_R_RQ 		heading "Large|Read Reqs"                                                                                                          
column LG_W_RQ 		heading "Large|Write Reqs" 
column SM_R_MS		heading "Small|Read Avg(ms)"
column SM_W_RQ    heading "Small|Read Reqs"
column SM_W_MS    heading "Small|Write Avg(ms)"
column SM_S_R_RQ  heading "Small|Sync Read Reqs"
column SM_S_R_MS  heading "Small|Sync Read Avg(ms)"
column LG_R_RQ    heading "Large|Read Reqs"
column LG_R_MS    heading "Large|Read Avg(ms)"
column LG_W_MS    heading "Large|Write Avg(ms)"
BREAK ON instance_number SKIP 1


WITH
  inter AS
  (
    SELECT
      extract(DAY FROM 24*60*snap_interval) inter_val
    FROM
      dba_hist_wr_control where dbid in (select dbid from v$database)
  )
  ,
  snap AS
  (
    SELECT
      INSTANCE_NUMBER,
      MIN(snap_id) SNAP_ID,
    trunc(sysdate-&days_history)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24 END_INTERVAL_TIME
    FROM
      dba_hist_snapshot
    WHERE
      begin_interval_time>=TRUNC(sysdate)- &days_history
    AND  instance_number = decode(&inst,0,instance_number,&inst)
    GROUP BY
      instance_number,
    trunc(sysdate-&days_history)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24
    ORDER BY
      3
  )
  ,
  base_line AS
  (
    SELECT
      snp.instance_number,
      to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time,
      sst.snap_id,
      sst.filetype_name ,
      sst.small_read_megabytes,
      sst.small_write_megabytes,
      sst.large_read_megabytes,
      sst.large_write_megabytes,
      sst.small_read_reqs,
      sst.small_read_servicetime,
      sst.small_write_reqs,
      sst.small_write_servicetime,
      sst.small_sync_read_reqs,
      sst.small_sync_read_latency,
      sst.large_read_reqs,
      sst.large_read_servicetime,
      sst.large_write_reqs,
      sst.large_write_servicetime
    FROM
      snap snp,
      DBA_HIST_IOSTAT_FILETYPE sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.filetype_name    = '&filetype_name'
  )
SELECT
  b2.instance_number,
  b2.end_time end_snap_time,
  b2.filetype_name,
  round(b2.small_read_megabytes        - b1.small_read_megabytes,0) 	SM_R_MB,
  round(b2.small_write_megabytes       - b1.small_write_megabytes,0)  SM_W_MB,
  round(b2.large_read_megabytes        - b1.large_read_megabytes,0)   LG_R_MB,
  round(b2.large_write_megabytes       - b1.large_write_megabytes,0)  LG_W_MB,
  round(b2.small_read_reqs             - b1.small_read_reqs,0)        SM_R_RQ,
  round((b2.small_read_servicetime     - b1.small_read_servicetime)/decode((b2.small_read_reqs              - b1.small_read_reqs),0,1,(b2.small_read_reqs              - b1.small_read_reqs)),2)        SM_R_MS,
  round(b2.small_write_reqs            - b1.small_write_reqs,0)       																																																																	SM_W_RQ,
  round((b2.small_write_servicetime    - b1.small_write_servicetime)/decode((b2.small_write_reqs            - b1.small_write_reqs),0,1,(b2.small_write_reqs            - b1.small_write_reqs)),2)       SM_W_MS,
  round(b2.small_sync_read_reqs        - b1.small_sync_read_reqs,0)   																																																																	SM_S_R_RQ,
  round((b2.small_sync_read_latency    - b1.small_sync_read_latency)/decode((b2.small_sync_read_reqs        - b1.small_sync_read_reqs),0,1,(b2.small_sync_read_reqs    - b1.small_sync_read_reqs)),2)   SM_S_R_MS,
  round(b2.large_read_reqs             - b1.large_read_reqs,0)        																																																																	LG_R_RQ,
  round((b2.large_read_servicetime     - b1.large_read_servicetime)/decode((b2.large_read_reqs              - b1.large_read_reqs),0,1,(b2.large_read_reqs              - b1.large_read_reqs)),2)        LG_R_MS,
  round(b2.large_write_reqs            - b1.large_write_reqs,0)       																																																																	LG_W_RQ,
  round((b2.large_write_servicetime    - b1.large_write_servicetime)/decode((b2.large_write_reqs            - b1.large_write_reqs),0,1,(b2.large_write_reqs            - b1.large_write_reqs)),2)       LG_W_MS
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
     b1.instance_number = b2.instance_number
AND  b1.filetype_name   = b2.filetype_name
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
ORDER BY
  1,2 ;
  
undef inst
undef filetype_name
undef days_history
undef interval_minutes

