--Response Time Per Txn
--SQL Service Response Time
--User Transaction Per Sec
--Executions Per Sec
--http://www.oracle.com/technetwork/articles/schumacher-analysis-099313.html
set ver off pages 50000 lines 140 tab off
column metric_name format a35
accept inst             prompt 'Enter instance number (0 or 1,2,3..)	: '
accept metric_name        prompt 'Enter metric name SYSMETRIC_SUMMARY	: '
accept days_history     prompt 'Enter number of days			: '

select  sn.instance_number,
		to_char(cast(sn.end_interval_time as date),'MM/DD/YY HH24:MI') end_Date,
        CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then 'SQL Service Response Time (secs)'
            WHEN 'Response Time Per Txn' then 'Response Time Per Txn (secs)'
            ELSE METRIC_NAME
            END METRIC_NAME,
                CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((MINVAL / 100),3)
            WHEN 'Response Time Per Txn' then ROUND((MINVAL / 100),3)
            ELSE round(MINVAL,2)
            END MININUM,
                CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((MAXVAL / 100),3)
            WHEN 'Response Time Per Txn' then ROUND((MAXVAL / 100),3)
            ELSE round(MAXVAL,2)
            END MAXIMUM,
                CASE METRIC_NAME
            WHEN 'SQL Service Response Time' then ROUND((AVERAGE / 100),3)
            WHEN 'Response Time Per Txn' then ROUND((AVERAGE / 100),3)
            ELSE round(AVERAGE,2)
            END AVERAGE
from    DBA_HIST_SNAPSHOT sn , DBA_HIST_SYSMETRIC_SUMMARY ss
where   sn.snap_id = ss.snap_id
and		sn.instance_number = ss.instance_number
and     sn.instance_number = decode(&inst,0,sn.instance_number,&inst)
and     sn.begin_interval_time>=TRUNC(sysdate)- &days_history +1		
and		(ss.METRIC_NAME in ('&metric_name') )
order by 1,2;