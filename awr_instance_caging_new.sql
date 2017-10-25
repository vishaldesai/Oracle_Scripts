accept days_history     prompt 'Enter number of days			: '
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '


col cputhread         format 999			heading "Instance|CPU thread|Allocation"      
col totcputhread      format 9999			heading "Total Host|CPU thread|Count"
col oraicpua	      format a10			heading "Instance|CPU thread |Allocation %"
col maxthreadused     format 999.99			heading "Max|CPU thread|Used"
col avgthreadused 	  format 999.99			heading "Avg|CPU thread|Used"
col stddevthreadused  format 999.99		    heading "Std Dev|CPU thread|Used"
--CPU usage per second is measure in centi second. 1 centi second is 0.01 second. When process used 1 second of cpu it used 1 thread.

--Standard deviation is a number used to tell how measurements for a group are spread out from the average (mean), or expected value. 
--A low standard deviation means that most of the numbers are very close to the average. A high standard deviation means that the numbers are spread out.
--A low standard deviation indicates that the data points tend to be close to the mean (also called the expected value) of the set, 
--while a high standard deviation indicates that the data points are spread out over a wider range of values.


--	Sum of the squared deviations from the mean


SELECT s.instance_number
         ,TO_CHAR (s.end_interval_time, 'MM/DD/YY HH24:MI:SS') end_time
         ,TO_NUMBER (p.VALUE) cputhread
         ,os.VALUE totcputhread
         ,ROUND (p.VALUE * 100 / os.VALUE) || '%' oraicpua
         ,ROUND (sm.maxval / 100, 2) maxthreadused
		 ,ROUND (sm.average/100,2) avgthreadused
		 ,ROUND (sm.standard_deviation/100,2) stddevthreadused
    FROM  dba_hist_snapshot s
         ,dba_hist_sysmetric_summary sm
         ,dba_hist_parameter p
         ,dba_hist_osstat os
   WHERE     s.dbid = sm.dbid
         AND s.dbid = p.dbid
         AND s.dbid = os.dbid
         AND s.instance_number = sm.instance_number
         AND s.instance_number = p.instance_number
         AND s.instance_number = os.instance_number
         AND s.snap_id = sm.snap_id
         AND s.snap_id = p.snap_id
         AND s.snap_id = os.snap_id
         AND s.begin_interval_time >= TRUNC (SYSDATE) - &days_history + 1
         AND s.instance_number = DECODE (&inst, 0, s.instance_number, &inst)
         AND sm.metric_name = 'CPU Usage Per Sec'
         AND p.parameter_name = 'cpu_count'
         AND os.stat_name = 'NUM_CPUS'
ORDER BY s.instance_number,
         TO_CHAR (s.end_interval_time, 'MM/DD/YY HH24:MI:SS');
