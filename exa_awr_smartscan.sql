/*
set ver off pages 50000 lines 140 tab off
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '

set arraysize 5000
set termout on
set echo off verify off
set lines 290
set pages 900

col INSTANCE_NUMBER format 99   heading "Inst#"
col mbps   format 99999999	    heading "MBPS"
col ambps  format 99999999		heading "Application|MBPS"
col mbpsef format 99999999		heading "MBPS eligible|for offload"
col mbssi  format 99999999		heading "MBPS saved|by SI"
col mbpsss format 99999999		heading "MBPS returned|by SS"
col mbpso  format 99999999		heading "MBPS|optimized"
col pmbpso format 999.99		heading "% MBPS|optimized"
col r1     format 999.99		heading "% bytes eligible|for predicate offload"
col r2     format 999.99		heading "% bytes saved by SI|from eligible bytes"
col r3	   format 999.99		heading "% bytes returned by SS|from eligible bytes|without compression"
col r4     format 999.99		heading "% bytes returned by SS|from eligible bytes|with compression"
col r5     format 999.99		heading "%Read|IOPsOpt"
col r6     format 999.99		heading "%Write|IOPsOpt"
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
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24 END_INTERVAL_TIME
    FROM
      dba_hist_snapshot
    WHERE
      begin_interval_time>=TRUNC(sysdate)- &days_history +1
    AND  instance_number = decode(&inst,0,instance_number,&inst)
    GROUP BY
      instance_number,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24
    ORDER BY
      3
  )
  ,
  base_line AS
  (
	select * from
        (select snp.instance_number, sst.snap_id, to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time, sst.stat_name, sst.value from
        snap snp, dba_hist_sysstat sst
		where sst.instance_number = snp.instance_number
        AND sst.snap_id       = snp.snap_id
    ) pivot
    (sum(value) for (stat_name) in
        (
     'cell physical IO bytes eligible for predicate offload' as cpibefpo, 
		 'cell physical IO bytes saved by storage index' as cpibsbsi,
		 'cell physical IO interconnect bytes returned by smart scan' as cpiibrbss,
		 'cell IO uncompressed bytes' as ciub,
		 'cell physical IO interconnect bytes' as cpiib,
		 'physical read total bytes optimized' as prtbo,
     'physical read total bytes' as prtb,
		 'physical read bytes' as prb,
		 'physical read total IO requests' as prtir,
		 'physical read IO requests' as prir,
		 'physical read requests optimized' as prro,
		 'physical write total bytes' as pwtb,
		 'physical write total IO requests' as pwtir,
		 'physical write IO requests' as pwir,
		 'physical write requests optimized' as pwro))
  )
  SELECT
   b2.instance_number
  ,b2.end_time end_snap_time
  ,(b2.prtb     - b1.prtb)/(1024*1024*&interval_minutes*60) 			  								   mbps
  ,(b2.prb      - b1.prb)/(1024*1024*&interval_minutes*60) 												     ambps			
  ,(b2.cpibefpo - b1.cpibefpo)/(1024*1024*&interval_minutes*60)									       mbpsef	
  ,(b2.cpibsbsi - b1.cpibsbsi)/(1024*1024*&interval_minutes*60)	     								   mbssi
  ,(b2.cpiibrbss - b1.cpiibrbss)/(1024*1024*&interval_minutes*60)								       mbpsss
  ,(b2.prtbo - b1.prtbo)/(1024*1024*&interval_minutes*60)			 							 	         mbpso
  ,(b2.prtbo - b1.prtbo)*100/(b2.prtb - b1.prtb) 															         pmbpso
  --,(((b2.prtb - b1.prtb) + (b2.pwtb - b1.pwtb)*2) - (b2.cpiib - b1.cpiib))/(1024*1024*&interval_minutes*60)    estimate
  --,(b2.prtb     - b1.prtb)/(1024*1024)					 			  									  mbps
  --,(b2.prb      - b1.prb)/(1024*1024)					 												     ambps			
  --,(b2.cpibefpo - b1.cpibefpo)/(1024*1024)														        mbpsef	
  --,(b2.cpibsbsi - b1.cpibsbsi)/(1024*1024)						     								     mbssi
  --,(b2.cpiibrbss - b1.cpiibrbss)/(1024*1024)														        mbpsss
  --,(b2.prtbo - b1.prtbo)/(1024*1024)									 							 	     mbpso
  ,(b2.cpibefpo - b1.cpibefpo)*100/(b2.prtb - b1.prtb) 													        r1
  ,(b2.cpibsbsi - b1.cpibsbsi)*100/decode((b2.cpibefpo - b1.cpibefpo),0,1,(b2.cpibefpo - b1.cpibefpo))	        r2
  ,(b2.cpiibrbss - b1.cpiibrbss)*100/(b2.prtb - b1.prtb) 										                r3
  ,(b2.cpiibrbss - b1.cpiibrbss)*100/decode((b2.ciub - b1.ciub),0,1,(b2.ciub - b1.ciub))						r4
  ,(b2.prro - b1.prro)*100/(b2.prtir - b1.prtir)																r5
  ,(b2.pwro - b1.pwro)*100/(b2.pwtir - b1.pwtir)																r6
FROM
  base_line b1,
  base_line b2,
  inter
WHERE
     b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
ORDER BY 1,2;

*/

/*
BASIC				DB_LAYER_IO						DB_PHYSIO_BYTES							physical read total bytes + physical write total bytes
BASIC				DB_LAYER_IO						DB_PHYSRD_BYTES							physical read total bytes
BASIC				DB_LAYER_IO						DB_PHYSWR_BYTES							physical write total bytes
			
ADVANCED	 	AVOID_DISK_IO					PHYRD_OPTIM_BYTES						physical read total bytes optimized
ADVANCED	 	AVOID_DISK_IO					PHYRD_DISK_AND_FLASH_BYTES	
BASIC				AVOID_DISK_IO					PHYRD_FLASH_RD_BYTES				physical read total bytes optimized - cell physical IO saved by storage indexes
BASIC				AVOID_DISK_IO					PHYRD_STORIDX_SAVED_BYTES		cell physical IO saved by storage indexes
			
BASIC				REAL_DISK_IO					SPIN_DISK_IO_BYTES					physical read total bytes - physical read total bytes optimized + physical write total bytes * 3
BASIC				REAL_DISK_IO					SPIN_DISK_RD_BYTES					physical read total bytes - physical read total bytes optimized
BASIC				REAL_DISK_IO					SPIN_DISK_WR_BYTES					physical write total bytes * 3 (asm mirror)
			
ADVANCED		COMPRESS							SCANNED_UNCOMP_BYTES				cell IO uncompressed bytes
ADVANCED		COMPRESS							EST_FULL_UNCOMP_BYTES	
			
BASIC				REDUCE_INTERCONNECT		PRED_OFFLOADABLE_BYTES			cell physical IO bytes eligible for predicate offload
BASIC				REDUCE_INTERCONNECT		PRED_OFFLOADABLE_BYTES			cell physical IO bytes eligible for predicate offload - cell physical IO saved by storage indexes
BASIC				REDUCE_INTERCONNECT		TOTAL_IC_RW_BYTES						cell physical IO interconnect bytes
BASIC				REDUCE_INTERCONNECT		TOTAL_IC_RD_BYTES						cell physical IO interconnect bytes - physical write total bytes*3
BASIC				REDUCE_INTERCONNECT		SMART_SCAN_RET_RD_BYTES			cell physical IO interconnect bytes returned by smart scan - 
BASIC				REDUCE_INTERCONNECT		SMART_SCAN_RET_BYTES				cell physical IO interconnect bytes returned by smart scan
BASIC				REDUCE_INTERCONNECT		NON_SMART_SCAN_BYTES				cell physical IO interconnect bytes - cell physical IO interconnect bytes returned by smart scan
			
ADVANCED		CELL_PROC_DEPTH				CELL_PROC_CACHE_BYTES	 			cell blocks processed by cache layer * 8192 (block_size)
ADVANCED		CELL_PROC_DEPTH				CELL_PROC_TXN_BYTES					cell blocks processed by txn layer * 8192 (block_size)
BASIC				CELL_PROC_DEPTH				CELL_PROC_DATA_BYTES				cell blocks processed by data layer * 8192 (block_size)
BASIC				CELL_PROC_DEPTH				CELL_PROC_INDEX_BYTES				cell blocks processed by index layer * 8192 (block_size)
ADVANCED		CELL_PROC_DEPTH				CELL_BAL_CPU_BYTES					cell physical IO bytes sent directly to DB node to balance CPU
			
ADVANCED		IN_DB_PROCESSING			CURR_GETS_CACHE_BYTES				db block gets from cache * 8192 (block_size)
ADVANCED		IN_DB_PROCESSING			CONS_GETS_CACHE_BYTES				consistent gets from cache * 8192 (block_size)
ADVANCED		IN_DB_PROCESSING			CURR_GETS_DIRECT_BYTES			db block gets direct * 8192 (block_size)
ADVANCED		IN_DB_PROCESSING			CONS_GETS_DIRECT_BYTES			consistent gets direct * 8192 (block_size)
			
BASIC				CLIENT_COMMUNICATION	NET_TO_CLIENT_BYTES					bytes sent via SQL*Net to client
BASIC				CLIENT_COMMUNICATION	NET_FROM_CLIENT_BYTES				bytes received via SQL*Net from client
			
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_FETCH_CONT_ROW				table fetch continued row
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_ROWS_SKIPPED					chained rows skipped by cell
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_ROWS_PROCESSED				chained rows processed by cell
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_ROWS_REJECTED					chained rows rejected by cell
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_BLOCKS_SKIPPED	
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_BLOCKS_PROCESSED	
ADVANCED		FALLBACK_TO_BLOCK_IO	CHAIN_BLOCKS_REJECTED	

*/


set ver off pages 50000 lines 140 tab off
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes		: '
accept unit				prompt 'Enter unit (M=MB,G=GB,T=TB)		: '

set arraysize 5000
set termout on
set echo off verify off
set lines 800
set pages 900

col INSTANCE_NUMBER format 99   heading "Inst#"

col DB_APP_PHYSRD_MBYTES			format  999999999   heading 'DB_APP_LAYER_IO|DB_PHYSRD_&unit.BYTES'
col DB_APP_PHYSWR_MBYTES			format  999999999   heading 'DB_APP_LAYER_IO|DB_PHYSWR_&unit.BYTES'
col DB_PHYSRD_MBYTES    			format 	999999999	heading 'DB_LAYER_IO|DB_PHYSRD_&unit.BYTES'
col DB_PHYSWR_MBYTES				format 	999999999	heading 'DB_LAYER_IO|DB_PHYSWR_&unit.BYTES'
col DB_PHYSIO_MBYTES				format 	999999999	heading 'DB_LAYER_IO|DB_PHYSIO_&unit.BYTES'
col PHYRD_OPTIM_RD_MBYTES			format  999999999   heading 'AVOID_DISK_IO|PHYRD_OPTIM_&unit.BYTES'
col PHYRD_FLASH_RD_MBYTES			format  999999999   heading 'AVOID_DISK_IO|PHYRD_FLASH_RD_&unit.BYTES'
col PHYRD_FLASH_WR_MBYTES			format  999999999	heading 'AVOID_DISK_IO|PHYRD_FLASH_WR_&unit.BYTES'
col PHYRD_STORIDX_SAVED_MBYTES		format  999999999   heading 'AVOID_DISK_IO|PHYRD_STORIDX_SAVED_&unit.BYTES'
col SPIN_DISK_RD_MBYTES             format  999999999   heading 'REAL_DISK_IO|SPIN_DISK_RD_&unit.BYTES'
col SPIN_DISK_WR_MBYTES				format  999999999   heading 'REAL_DISK_IO|SPIN_DISK_WR_&unit.BYTES'
col SPIN_DISK_IO_MBYTES				format  999999999   heading 'REAL_DISK_IO|SPIN_DISK_IO_&unit.BYTES'
col SCANNED_UNCOMP_MBYTES			format  999999999	heading 'COMPRESS|SCANNED_UNCOMP_&unit.BYTES'
col PRED_OFFLOADABLE_MBYTES			format  999999999   heading 'REDUCE_INTERCONNECT|PRED_OFFLOADABLE_&unit.BYTES(SS+SI)'
col PRED_OFFLOADABLE_MBYTES_1		format  999999999	heading 'REDUCE_INTERCONNECT|PRED_OFFLOADABLE_&unit.BYTES(SS)'
col TOTAL_IC_RW_MBYTES				format  999999999	heading 'REDUCE_INTERCONNECT|TOTAL_IC_RW_&unit.BYTES'
col TOTAL_IC_RD_MBYTES				format  999999999	heading 'REDUCE_INTERCONNECT|TOTAL_IC_RD_&unit.BYTES(FL+SS+NONSS)'
col SMART_SCAN_RET_RD_MBYTES		format  999999999.99	heading 'REDUCE_INTERCONNECT|SMART_SCAN_RET_RD_&unit.BYTES'
col NON_SMART_SCAN_RD_MBYTES		format  999999999	heading 'REDUCE_INTERCONNECT|NON_SMART_SCAN_RD_&unit.BYTES'
col CELL_PROC_CACHE_MBYTES			format  999999999	heading 'CELL_PROC_DEPTH|CELL_PROC_CACHE_&unit.BYTES'
col CELL_PROC_TXN_MBYTES			format  999999999	heading 'CELL_PROC_DEPTH|CELL_PROC_TXN_&unit.BYTES'
col CELL_PROC_DATA_MBYTES			format  999999999   heading 'CELL_PROC_DEPTH|CELL_PROC_DATA_&unit.BYTES'
col CELL_PROC_INDEX_MBYTES			format  999999999   heading 'CELL_PROC_DEPTH|CELL_PROC_INDEX_&unit.BYTES'
col CELL_BAL_CPU_MBYTES				format  999999999	heading 'CELL_PROC_DEPTHCELL_BAL_CPU_&unit.BYTES'
col CURR_GETS_CACHE_MBYTES			format  999999999	heading 'IN_DB_PROCESSING|CURR_GETS_CACHE_&unit.BYTES'
col CONS_GETS_CACHE_MBYTES			format  999999999   heading 'IN_DB_PROCESSING|CONS_GETS_CACHE_&unit.BYTES'
col CURR_GETS_DIRECT_MBYTES			format  999999999   heading 'IN_DB_PROCESSING|CURR_GETS_DIRECT_&unit.BYTES'
col CONS_GETS_DIRECT_MBYTES			format  999999999   heading 'IN_DB_PROCESSING|CONS_GETS_DIRECT_&unit.BYTES'
col CHAIN_FETCH_CONT_ROW			format  99999999999999 heading 'FALLBACK_TO_BLOCK_IO|CHAIN_FETCH_CONT_ROW'
col CHAIN_ROWS_SKIPPED              format  99999999999999 heading 'FALLBACK_TO_BLOCK_IO|CHAIN_ROWS_SKIPPED'
col CHAIN_ROWS_PROCESSED			format  99999999999999 heading 'FALLBACK_TO_BLOCK_IO|CHAIN_ROWS_PROCESSED'
col CHAIN_ROWS_REJECTED				format  99999999999999 heading 'FALLBACK_TO_BLOCK_IO|CHAIN_ROWS_REJECTED'

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
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24 END_INTERVAL_TIME
    FROM
      dba_hist_snapshot
    WHERE
      begin_interval_time>=TRUNC(sysdate)- &days_history +1
    AND  instance_number = decode(&inst,0,instance_number,&inst)
    GROUP BY
      instance_number,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24
    ORDER BY
      3
  )
  ,
  base_line AS
  (
	select * from
        (select snp.instance_number, sst.snap_id, to_char(snp.end_interval_time,'MM/DD/YY HH24:MI:SS') end_time, sst.stat_name, sst.value from
        snap snp, dba_hist_sysstat sst
		where sst.instance_number = snp.instance_number
        AND sst.snap_id       = snp.snap_id
    ) pivot
    (sum(value) for (stat_name) in
        (
		 -- db layer
		 'redo size' as rs,
		 'physical read bytes' as prb,
		 'physical write bytes' as pwb,
		 'physical read total bytes' as prtb,
		 'physical write total bytes' as pwtb,
		 --avoid disk io layer
		 'physical read total bytes optimized' as prtbo,
		 'physical write total bytes optimized' as pwtbo,
		 'cell physical IO bytes saved by storage index' as cpisbsi,
		 --real disk io
		 --derived from above
		 --compress
		 'cell IO uncompressed bytes' as ciub,
		 --interconnect bytes
		 'cell physical IO bytes eligible for predicate offload' as cpibefpo,
		 'cell physical IO interconnect bytes' as cpiib,
		 'cell physical IO interconnect bytes returned by smart scan' as cpiibrbss,
		 --cell proc depth
		 'cell blocks processed by cache layer' as cbpbcl,
		 'cell blocks processed by txn layer' as cbpbtl,
		 'cell blocks processed by data layer' as cbpbdl,
		 'cell blocks processed by index layer' as cbpbil,
		 'cell physical IO bytes sent directly to DB node to balance CPU' as cpibsdtdntbc,
		 --in db processing
		 'db block gets from cache' as dbgfc,
		 'consistent gets from cache' as cgfc,
		 'db block gets direct' as dbgd,
		 'consistent gets direct' as cgd,
		 --fallback to block io
		 'table fetch continued row' as tfcr,
		 'chained rows skipped by cell' as crsbc,
		 'chained rows processed by cell' as crpbc,
		 'chained rows rejected by cell' as crrbc,
		 --other
		 'cell num bytes in block IO during predicate offload' cnbbidpo
		 ))
  )
  SELECT
   b2.instance_number
  ,b2.end_time end_snap_time
  --DB_LAYER_IO
  ,(b2.prb  - b1.prb)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																	DB_APP_PHYSRD_MBYTES
  ,(b2.pwb  - b1.pwb)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																	DB_APP_PHYSWR_MBYTES
  ,(b2.prtb - b1.prtb)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																	DB_PHYSRD_MBYTES
  ,(b2.pwtb - b1.pwtb)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																	DB_PHYSWR_MBYTES
  ,((b2.prtb - b1.prtb) + (b2.pwtb - b1.pwtb))/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)											DB_PHYSIO_MBYTES
  --AVOID DISK IO
  ,(b2.prtbo - b1.prtbo)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																PHYRD_OPTIM_RD_MBYTES
  ,((b2.prtbo - b1.prtbo) - (b2.cpisbsi - b1.cpisbsi))/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)									PHYRD_FLASH_RD_MBYTES
  ,(b2.pwtbo - b1.pwtbo)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																PHYRD_FLASH_WR_MBYTES
  ,(b2.cpisbsi - b1.cpisbsi)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)															PHYRD_STORIDX_SAVED_MBYTES
  --SPIN_DISK_IO_MB
  ,((b2.prtb - b1.prtb) - (b2.prtbo - b1.prtbo))/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)										SPIN_DISK_RD_MBYTES
  ,(b2.pwtb - b1.pwtb)*3/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																SPIN_DISK_WR_MBYTES
  ,((b2.prtb - b1.prtb) - (b2.prtbo - b1.prtbo) + (b2.pwtb - b1.pwtb)*3)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)				SPIN_DISK_IO_MBYTES
  --compressed
  ,(b2.ciub - b1.ciub)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																	SCANNED_UNCOMP_MBYTES
  --reduce interconnect
  ,(b2.cpibefpo - b1.cpibefpo)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)															PRED_OFFLOADABLE_MBYTES
  ,((b2.cpibefpo - b1.cpibefpo) - (b2.cpisbsi - b1.cpisbsi))/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)							PRED_OFFLOADABLE_MBYTES_1
  ,(b2.cpiib - b1.cpiib)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)																TOTAL_IC_RW_MBYTES
  --,((b2.cpiib - b1.cpiib) - (b2.pwb - b1.pwb)*3)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)										TOTAL_IC_RD_MBYTES
  ,(b2.cpiibrbss - b1.cpiibrbss)/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)														SMART_SCAN_RET_RD_MBYTES
  --,((b2.cpiib - b1.cpiib) - (b2.cpiibrbss - b1.cpiibrbss))/1024/1024							NON_SMART_SCAN_RD_MBYTES
  ,((b2.cpiib - b1.cpiib) - (b2.cpiibrbss - b1.cpiibrbss))
   /decode('&unit','M',1048576,'G',1073741824,'T',1099511627776) 																					NON_SMART_SCAN_RD_MBYTES
  --CELL_PROC_DEPTH
  ,(b2.cbpbcl - b1.cbpbcl)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)														CELL_PROC_CACHE_MBYTES
  ,(b2.cbpbtl - b1.cbpbtl)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)														CELL_PROC_TXN_MBYTES
  ,(b2.cbpbdl - b1.cbpbdl)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)														CELL_PROC_DATA_MBYTES
  ,(b2.cbpbil - b1.cbpbil)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)														CELL_PROC_INDEX_MBYTES
  ,(b2.cpibsdtdntbc - b1.cpibsdtdntbc)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)											CELL_BAL_CPU_MBYTES
  --In DB processing
  ,(b2.dbgfc - b1.dbgfc)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)															CURR_GETS_CACHE_MBYTES
  ,(b2.cgfc  - b1.cgfc)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)															CONS_GETS_CACHE_MBYTES
  ,(b2.dbgd  - b1.dbgd)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)															CURR_GETS_DIRECT_MBYTES
  ,(b2.cgd   - b1.cgd)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)															CONS_GETS_DIRECT_MBYTES
  --Fallback to Block IO
  ,(b2.tfcr - b1.tfcr)																																CHAIN_FETCH_CONT_ROW
  ,(b2.crsbc - b1.crsbc)																															CHAIN_ROWS_SKIPPED
  ,(b2.crpbc - b1.crpbc)																															CHAIN_ROWS_PROCESSED
  ,(b2.crrbc - b1.crrbc)																															CHAIN_ROWS_REJECTED
  --OTHER
  ,(b2.cnbbidpo - b1.cnbbidpo)*8192/decode('&unit','M',1048576,'G',1073741824,'T',1099511627776)													blkio
  FROM
  base_line b1,
  base_line b2,
  inter
WHERE
     b1.instance_number = b2.instance_number
AND b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
ORDER BY 1,2;
