set ver off pages 50000 lines 140 tab off
set linesize 300
set pages 9999
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept days_history     prompt 'Enter number of days			: '
accept service_name     prompt 'Enter service name				: '
accept wait_class       prompt 'Enter wait class(User I/O) :'

col end_snap_time format a30
col service_name  format a24
col wait_class    format a20
col total_waits   format 9999999999           heading "Total Waits"
col time_waited   format 9999999999           heading "Time Waited"


                      

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
				  sst.service_name,
				  sst.wait_class,
				  sst.total_waits,
				  sst.time_waited
				FROM
				  dba_hist_snapshot snp,
				  DBA_HIST_SERVICE_WAIT_CLASS sst
				WHERE
				  sst.instance_number = snp.instance_number
				AND sst.snap_id       = snp.snap_id
				AND snp.instance_number = decode(&inst,0,snp.instance_number,&inst)
				AND snp.begin_interval_time >= TRUNC(sysdate)- &days_history
				AND sst.service_name = '&service_name'
				AND sst.wait_class   = '&wait_class'
			   )
  )
SELECT
    b2.instance_number,
	to_char(b2.end_interval_time,'MM/DD/YY HH24:MI:SS') end_snap_time,
	b2.service_name,
	b2.wait_class,
	b2.total_waits - b1.total_waits	total_waits,
	b2.time_waited - b1.time_waited	time_waited
FROM
  base_line b1,
  base_line b2
WHERE
     b1.instance_number 	= b2.instance_number
AND  b1.snap_id + 1       = b2.snap_id
ORDER BY 
  1,2   ;


undef inst
undef service_name
undef days_history
undef wait_class

