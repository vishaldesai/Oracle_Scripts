set ver off pages 50000 lines 140 tab off
set linesize 300
set pages 9999
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '

col end_snap_time format a30
col load        format 990.00           heading "OS|Load"
col num_cpus    format 90               heading "CPU"
col mem         format 999990.00        heading "Memory|(GB)"
col oscpupct    format 990              heading "OS|CPU%"
col oscpuusr    format 990              heading "USR%"
col oscpusys    format 990              heading "SYS%"
col oscpuio     format 990              heading "IO%"


                      

BREAK ON instance_number SKIP 1


WITH
  base_line AS
  (
		SELECT
		*
			FROM
				(
				SELECT
				  snp.instance_number,
				  snp.end_interval_time ,
				  sst.snap_id,
				  sst.stat_name,
				  sst.value
				FROM
				  dba_hist_snapshot snp,
				  dba_hist_osstat sst
				WHERE
				  sst.instance_number = snp.instance_number
				AND sst.snap_id       = snp.snap_id
				AND snp.instance_number = decode(&inst,0,snp.instance_number,&inst)
				AND snp.begin_interval_time >= TRUNC(sysdate)- &days_history
			   )
		  pivot (SUM(value) FOR (stat_name) IN (
		  'LOAD'									   AS LOAD,
		  'NUM_CPUS'								   AS NUM_CPUS,
		  'PHYSICAL_MEMORY_BYTES'                      AS PHYSICAL_MEMORY_BYTES, 
		  'BUSY_TIME'           					   AS BUSY_TIME,
		  'USER_TIME'                                  AS USER_TIME,
		  'SYS_TIME'                                   AS SYS_TIME,
		  'IOWAIT_TIME'                                AS IOWAIT_TIME))
  )
SELECT
    b2.instance_number,
	to_char(b2.end_interval_time,'MM/DD/YY HH24:MI:SS') end_snap_time,
	b2.NUM_CPUS,
	round(b2.LOAD,1) LOAD,
	round(b2.PHYSICAL_MEMORY_BYTES/1024/1024/1024,0) mem,
	(((b2.busy_time - b1.busy_time)/100) / ((round(EXTRACT(DAY FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM b2.END_INTERVAL_TIME   - b1.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) / 60, 2)*60)*b2.NUM_CPUS))*100 as oscpupct,
	(((b2.user_time - b1.user_time)/100) / ((round(EXTRACT(DAY FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM b2.END_INTERVAL_TIME   - b1.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) / 60, 2)*60)*b2.NUM_CPUS))*100 as  oscpuusr,
    (((b2.sys_time - b1.sys_time)/100) / ((round(EXTRACT(DAY FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM b2.END_INTERVAL_TIME   - b1.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) / 60, 2)*60)*b2.NUM_CPUS))*100 as  oscpusys,
    (((b2.iowait_time - b1.iowait_time)/100) / ((round(EXTRACT(DAY FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM b2.END_INTERVAL_TIME   - b1.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM b2.END_INTERVAL_TIME - b1.END_INTERVAL_TIME) / 60, 2)*60)*b2.NUM_CPUS))*100 as  oscpuio
FROM
  base_line b1,
  base_line b2
WHERE
     b1.instance_number 	= b2.instance_number
AND  b1.snap_id + 1         = b2.snap_id
ORDER BY 
  1,2   ;


undef inst
undef fileno
undef days_history
undef interval_minutes

