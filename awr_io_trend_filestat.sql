set ver off pages 50000 lines 140 tab off
set linesize 300
set pages 9999
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept fileno           prompt 'Enter file number		: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

col inst for 9
col snap_time for a19
col file# format 99999
col TOT_P_R 					heading   "Total|Reads"        
col TOT_P_R_S					heading   "Total|Time(S)"
col TOT_P_R_AVG_MS	  heading   "Total|Avg(ms)"    
col S_P_R						  heading   "Single BLK|Reads"           
col S_P_R_S					  heading   "Single BLK|Time(S)"						
col S_P_R_AVG_MS			heading   "Single BLK|Avg(ms)"
col M_P_R							heading   "Multi BLK|Reads"
col M_P_R_AVG_SZ			heading   "Multi BLK|Avg Size"
col M_P_R_S						heading   "Multi BLK|Time(S)" 
col M_P_R_AVG_MS			heading   "Multi BLK|Avg(ms)"
col DBWR_P_W					heading		"DBWR|Writes"      
col DBWR_P_W_AVG_SZ		heading   "DBWR|Avg Size"   
col DBWR_P_W_S				heading   "DBWR|Time(S)"
col DBWR_P_W_AVG_MS		heading   "DBWR|Avg(ms)"
col TOT_P_BLK_R				heading   "Total BLK|Reads"
col TOT_P_BLK_W				heading   "Total BLK|Writes"
col WAIT_COUNT				heading   "Waits"
col TM                heading   "Wait Time"
                      

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
			sst.FILE#,
			sst.SINGLEBLKRDS,
			sst.SINGLEBLKRDTIM,
		  sst.PHYRDS,
			sst.PHYWRTS,
			sst.PHYRDS  - sst.SINGLEBLKRDS PHYRDS_M,
			sst.READTIM - sst.SINGLEBLKRDTIM READTIM_M,
			sst.READTIM,
			sst.WRITETIM,
			sst.PHYBLKRD,
			sst.PHYBLKWRT,
			sst.WAIT_COUNT,
			sst.TIME
    FROM
      snap snp,
      DBA_HIST_FILESTATXS sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.FILE#        in (&fileno)
  )
SELECT
  b2.instance_number,
  b2.end_time end_snap_time,
  b2.file#,
  round(b2.PHYRDS        	  - b1.PHYRDS,0) 																																																											as TOT_P_R,
  round((b2.READTIM	    	  - b1.READTIM)/100,0)																																																								as TOT_P_R_S,
  round((b2.READTIM	        - b1.READTIM)*1000/100/decode(b2.PHYRDS - b1.PHYRDS,0,1,b2.PHYRDS - b1.PHYRDS),2)			  																									as TOT_P_R_AVG_MS,
  round(b2.SINGLEBLKRDS  	  - b1.SINGLEBLKRDS,0)																																																								as S_P_R,
  round((b2.SINGLEBLKRDTIM	- b1.SINGLEBLKRDTIM)/100,0)																																																					as S_P_R_S,																		
  round((b2.SINGLEBLKRDTIM	- b1.SINGLEBLKRDTIM)*1000/100/decode(b2.SINGLEBLKRDS - b1.SINGLEBLKRDS,0,1,b2.SINGLEBLKRDS  - b1.SINGLEBLKRDS),2)													as S_P_R_AVG_MS,
  round(b2.PHYRDS_M         - b1.PHYRDS_M,0) 																																																										as M_P_R,
  round(((b2.PHYBLKRD			  - b1.PHYBLKRD)-(b2.SINGLEBLKRDS  	  - b1.SINGLEBLKRDS))/decode(b2.PHYRDS_M - b1.PHYRDS_M,0,1,b2.PHYRDS_M - b1.PHYRDS_M),0) 					as M_P_R_AVG_SZ,
  round((b2.READTIM_M       - b1.READTIM_M)/100,0) 																																																							as M_P_R_S,
  round((b2.READTIM_M       - b1.READTIM_M)*1000/100/decode(b2.PHYRDS_M - b1.PHYRDS_M,0,1,b2.PHYRDS_M - b1.PHYRDS_M),2) 																							as M_P_R_AVG_MS,
  round(b2.PHYWRTS 		 	    - b1.PHYWRTS,0)																																																											as DBWR_P_W,
  round((b2.PHYBLKWRT		    - b1.PHYBLKWRT)/decode(b2.PHYWRTS - b1.PHYWRTS,0,1,b2.PHYWRTS - b1.PHYWRTS),0) 																											as DBWR_P_W_AVG_SZ,
  round((b2.WRITETIM	    	- b1.WRITETIM)/100,0)																																																								as DBWR_P_W_S,
  round((b2.WRITETIM	   		- b1.WRITETIM)*1000/100/decode(b2.PHYWRTS - b1.PHYWRTS,0,1,b2.PHYWRTS - b1.PHYWRTS),2)  	  																							as DBWR_P_W_AVG_MS,
  round(b2.PHYBLKRD			    - b1.PHYBLKRD,0)																																																										as TOT_P_BLK_R,
  round(b2.PHYBLKWRT		    - b1.PHYBLKWRT,0)																																																										as TOT_P_BLK_W,
  round(b2.WAIT_COUNT		    - b1.WAIT_COUNT,0)																																																									as WAIT_COUNT,
  round(b2.TIME				    	- b1.TIME,0)																																																												as TM
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
     b1.instance_number 														= b2.instance_number
AND  b1.file#   																		= b2.file#
AND  b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
ORDER BY
  1,2,3 ;
  
undef inst
undef fileno
undef days_history
undef interval_minutes

