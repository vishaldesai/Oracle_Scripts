set linesize 200
set pages 999
set verify off

accept p_inst number default 1 prompt 'Instance Number (default 1)     : '
accept p_days number default 7 prompt 'Report Interval (default 7 days): '

column start_time format a17
column end_time format a17
select snap_id, s.instance_number, to_char(begin_interval_time,'MM/DD/YY HH24:MI') start_time, 
		   to_char(end_interval_time,'MM/DD/YY HH24:MI') end_time
	from  dba_hist_snapshot s, gv$instance i
	where begin_interval_time between trunc(sysdate)-&p_days and sysdate 
	and   s.instance_number = i.instance_number
	and   s.instance_number = &p_inst
	order by snap_id;
	
accept p_bid prompt 'Enter Begin Snap :'
accept p_eid prompt 'Enter End Snap   :'

select 'Database Summary'																				as section from dual union all
select 'Database Instances Included In Report'                  as section from dual union all
select 'Top Event P1/P2/P3 Values'                              as section from dual union all
select 'Top SQL with Top Events'                                as section from dual union all
select 'Top SQL with Top Row Sources'                           as section from dual union all
select 'Top Sessions'                                           as section from dual union all
select 'Top Blocking Sessions'                                  as section from dual union all
select 'Top PL/SQL Procedures'                                  as section from dual union all
select 'Top Events'                                             as section from dual union all
select 'Top DB Objects'                                         as section from dual union all
select 'Activity Over Time'                                     as section from dual union all
select 'Wait Event Histogram Detail (64 msec to 2 sec)'         as section from dual union all
select 'Wait Event Histogram Detail (4 sec to 2 min)'           as section from dual union all
select 'Wait Event Histogram Detail (4 min to 1 hr)'            as section from dual union all
select 'SQL ordered by Elapsed Time'                            as section from dual union all
select 'SQL ordered by CPU Time'                                as section from dual union all
select 'SQL ordered by User I/O Wait Time'                      as section from dual union all
select 'SQL ordered by Gets'                                    as section from dual union all
select 'SQL ordered by Reads'                                   as section from dual union all
select 'SQL ordered by Physical Reads (UnOptimized)'            as section from dual union all
select 'SQL ordered by Optimized Reads'                         as section from dual union all
select 'SQL ordered by Executions'                              as section from dual union all
select 'SQL ordered by Parse Calls'                             as section from dual union all
select 'SQL ordered by Sharable Memory'                         as section from dual union all
select 'SQL ordered by Version Count'                           as section from dual union all
select 'SQL ordered by Cluster Wait Time'                       as section from dual union all
select 'Key Instance Activity Stats'                            as section from dual union all
select 'Instance Activity Stats'                                as section from dual union all
select 'IOStat by Function summary'                             as section from dual union all
select 'IOStat by Filetype summary'                             as section from dual union all
select 'IOStat by Function/Filetype summary'                    as section from dual union all
select 'Tablespace IO Stats'                                    as section from dual union all
select 'File IO Stats'                                          as section from dual union all
select 'Checkpoint Activity'                                    as section from dual union all
select 'MTTR Advisory'                                          as section from dual union all
select 'Segments by Logical Reads'                              as section from dual union all
select 'Segments by Physical Reads'                             as section from dual union all
select 'Segments by Direct Physical Reads'                      as section from dual union all
select 'Segments by Physical Read Requests'                     as section from dual union all
select 'Segments by UnOptimized Reads'                          as section from dual union all
select 'Segments by Optimized Reads'                            as section from dual union all
select 'Segments by Physical Write Requests'                    as section from dual union all
select 'Segments by Physical Writes'                            as section from dual union all
select 'Segments by Direct Physical Writes'                     as section from dual union all
select 'Segments by DB Blocks Changes'                          as section from dual union all
select 'Segments by Table Scans'                                as section from dual union all
select 'Segments by Row Lock Waits'                             as section from dual union all
select 'Segments by ITL Waits'                                  as section from dual union all
select 'Segments by Buffer Busy Waits'                          as section from dual union all
select 'Segments by Global Cache Buffer Busy'                   as section from dual union all
select 'Segments by CR Blocks Received'                         as section from dual union all
select 'Segments by Current Blocks Received'                    as section from dual union all
select 'In-Memory Segments by Scans'                            as section from dual union all
select 'In-Memory Segments by DB Block Changes'                 as section from dual union all
select 'In-Memory Segments by Populate CUs'                     as section from dual union all
select 'In-Memory Segments by Repopulate CUs'                   as section from dual union all
select 'Interconnect Device Statistics'                         as section from dual union all
select 'Dynamic Remastering Stats'                              as section from dual union all
select 'Resource Manager Plan Statistics'                       as section from dual union all
select 'Resource Manager Consumer Group Statistics'             as section from dual union all
select 'Replication System Resource Usage'                      as section from dual union all
select 'Replication SGA Usage'                                  as section from dual union all
select 'GoldenGate Capture'                                     as section from dual union all
select 'GoldenGate Capture Rate'                                as section from dual union all
select 'GoldenGate Apply Reader'                                as section from dual union all
select 'GoldenGate Apply Coordinator'                           as section from dual union all
select 'GoldenGate Apply Server'                                as section from dual union all
select 'GoldenGate Apply Coordinator Rate'                      as section from dual union all
select 'GoldenGate Apply Reader and Server Rate'                as section from dual union all
select 'XStream Capture'                                        as section from dual union all
select 'XStream Capture Rate'                                   as section from dual union all
select 'XStream Apply Reader'                                   as section from dual union all
select 'XStream Apply Coordinator'                              as section from dual union all
select 'XStream Apply Server'                                   as section from dual union all
select 'XStream Apply Coordinator Rate'                         as section from dual union all
select 'XStream Apply Reader and Server Rate'                   as section from dual union all
select 'Table Statistics by DML Operations'                     as section from dual union all
select 'Table Statistics by Conflict Resolutions'               as section from dual union all
select 'Replication Large Transaction Statistics'               as section from dual union all
select 'Replication Long Running Transaction Statistics'        as section from dual union all
select 'Streams Capture'                                        as section from dual union all
select 'Streams Capture Rate'                                   as section from dual union all
select 'Streams Apply'                                          as section from dual union all
select 'Streams Apply Rate'                                     as section from dual union all
select 'Buffered Queues'                                        as section from dual union all
select 'Buffered Queue Subscribers'                             as section from dual union all
select 'Persistent Queues'                                      as section from dual union all
select 'Persistent Queues Rate'                                 as section from dual union all
select 'Persistent Queue Subscribers'                           as section from dual union all
select 'Rule Set'                                               as section from dual union all
select 'Shared Servers Activity'                                as section from dual union all
select 'Shared Servers Rates'                                   as section from dual union all
select 'Shared Servers Utilization'                             as section from dual union all
select 'Shared Servers Common Queue'                            as section from dual union all
select 'Shared Servers Dispatchers'                             as section from dual union all
select 'init.ora Parameters'                                    as section from dual union all
select 'init.ora Multi-Valued Parameters'                       as section from dual union all
select 'Cluster Interconnect'                                   as section from dual union all
select 'Wait Classes by Total Wait Time'                        as section from dual union all
select 'Top 10 Foreground Events by Total Wait Time'            as section from dual union all
select 'Top ADDM Findings by Average Active Sessions'           as section from dual union all
select 'Cache Sizes'                                            as section from dual union all
select 'Host Configuration Comparison'                          as section from dual union all
select 'Top Timed Events'                                       as section from dual union all
select 'Top SQL Comparison by Elapsed Time'                     as section from dual union all
select 'Top SQL Comparison by I/O Time'                         as section from dual union all
select 'Top SQL Comparison by CPU Time'                         as section from dual union all
select 'Top SQL Comparison by Buffer Gets'                      as section from dual union all
select 'Top SQL Comparison by Physical Reads'                   as section from dual union all
select 'Top SQL Comparison by UnOptimized Read Requests'        as section from dual union all
select 'Top SQL Comparison by Optimized Reads'                  as section from dual union all
select 'Top SQL Comparison by Executions'                       as section from dual union all
select 'Top SQL Comparison by Parse Calls'                      as section from dual union all
select 'Top SQL Comparison by Cluster Wait Time'                as section from dual union all
select 'Top SQL Comparison by Sharable Memory'                  as section from dual union all
select 'Top SQL Comparison by Version Count'                    as section from dual union all
select 'Top Segments Comparison by Logical Reads'               as section from dual union all
select 'Top Segments Comparison by Physical Reads'              as section from dual union all
select 'Top Segments Comparison by Direct Physical Reads'       as section from dual union all
select 'Top Segments Comparison by Physical Read Requests'      as section from dual union all
select 'Top Segments Comparison by Optimized Read Requests'     as section from dual union all
select 'Top Segments Comparison by Physical Write Requests'     as section from dual union all
select 'Top Segments Comparison by Physical Writes'             as section from dual union all
select 'Top Segments Comparison by Table Scans'                 as section from dual union all
select 'Top Segments Comparison by DB Block Changes'            as section from dual union all
select 'Top Segments by Buffer Busy Waits'                      as section from dual union all
select 'Top Segments by Row Lock Waits'                         as section from dual union all
select 'Top Segments by ITL Waits'                              as section from dual union all
select 'Top Segments by CR Blocks Received'                     as section from dual union all
select 'Top Segments by Current Blocks Received'                as section from dual union all
select 'Top Segments by GC Buffer Busy Waits'                   as section from dual union all
select 'Top In-Memory Segments Comparison by Scans'             as section from dual union all
select 'Top In-Memory Segments Comparison by DB Block Changes'  as section from dual union all
select 'Top In-Memory Segments Comparison by Populate CUs'      as section from dual union all
select 'Top In-Memory Segments Comparison by Repopulate CUs'    as section from dual union all
select 'Service Statistics'                                     as section from dual union all
select 'Service Statistics (RAC)'                               as section from dual union all
select 'Global Messaging Statistics'                            as section from dual union all
select 'Global CR Served Stats'                                 as section from dual union all
select 'Global CURRENT Served Stats'                            as section from dual union all
select 'Replication System Resource Usage'                      as section from dual union all
select 'Replication SGA Usage'                                  as section from dual union all
select 'Streams by CPU Time'                                    as section from dual union all
select 'GoldenGate Capture'                                     as section from dual union all
select 'GoldenGate Capture Rate'                                as section from dual union all
select 'GoldenGate Apply Coordinator'                           as section from dual union all
select 'GoldenGate Apply Reader'                                as section from dual union all
select 'GoldenGate Apply Server'                                as section from dual union all
select 'GoldenGate Apply Coordinator Rate'                      as section from dual union all
select 'GoldenGate Apply Reader and Server Rate'                as section from dual union all
select 'XStream Capture'                                        as section from dual union all
select 'XStream Capture Rate'                                   as section from dual union all
select 'XStream Apply Coordinator'                              as section from dual union all
select 'XStream Apply Reader'                                   as section from dual union all
select 'XStream Apply Server'                                   as section from dual union all
select 'XStream Apply Coordinator Rate'                         as section from dual union all
select 'XStream Apply Reader and Server Rate'                   as section from dual union all
select 'Table Statistics by DML Operations'                     as section from dual union all
select 'Table Statistics by Conflict Resolutions'               as section from dual union all
select 'Replication Large Transaction Statistics'               as section from dual union all
select 'Replication Long Running Transaction Statistics'        as section from dual union all
select 'Streams by IO Time'                                     as section from dual union all
select 'Streams Capture'                                        as section from dual union all
select 'Streams Capture Rate'                                   as section from dual union all
select 'Streams Apply'                                          as section from dual union all
select 'Streams Apply Rate'                                     as section from dual union all
select 'Buffered Queues'                                        as section from dual union all
select 'Rule Set by Evaluations'                                as section from dual union all
select 'Rule Set by Elapsed Time'                               as section from dual union all
select 'Persistent Queues'                                      as section from dual union all
select 'Persistent Queues Rate'                                 as section from dual union all
select 'IOStat by Function - Data Rate per Second'              as section from dual union all
select 'IOStat by Function - Requests per Second'               as section from dual union all
select 'IOStat by File Type - Data Rate per Second'             as section from dual union all
select 'IOStat by File Type - Requests per Second'              as section from dual union all
select 'Tablespace IO Stats'                                    as section from dual union all
select 'Top File Comparison by IO'                              as section from dual union all
select 'Top File Comparison by Read Time'                       as section from dual union all
select 'Top File Comparison by Buffer Waits'                    as section from dual union all
select 'Key Instance Activity Stats'                            as section from dual union all
select 'Other Instance Activity Stats'                          as section from dual union all
select 'Enqueue Activity'                                       as section from dual union all
select 'Buffer Wait Statistics'                                 as section from dual union all
select 'Dynamic Remastering Stats'                              as section from dual union all
select 'Library Cache Activity'                                 as section from dual union all
select 'Library Cache Activity (RAC)'                           as section from dual union all
select 'init.ora Parameters'                                    as section from dual union all
select 'init.ora Multi-Valued Parameters'                       as section from dual union all
select 'Buffered Subscribers'                                   as section from dual union all
select 'Persistent Queue Subscribers'                           as section from dual union all
select 'Shared Servers Activity'                                as section from dual union all
select 'Shared Servers Rates'                                   as section from dual union all
select 'Shared Servers Utilization'                             as section from dual union all
select 'Shared Servers Common Queue'                            as section from dual union all
select 'Shared Servers Dispatchers'                             as section from dual union all
select 'Database Summary'                                       as section from dual union all
select 'Database Instances Included In Report'                  as section from dual union all
select 'Top ADDM Findings by Average Active Sessions'           as section from dual union all
select 'Cache Sizes'                                            as section from dual union all
select 'OS Statistics By Instance'                              as section from dual union all
select 'Foreground Wait Classes -  % of Total DB time'          as section from dual union all
select 'Foreground Wait Classes'                                as section from dual union all
select 'Foreground Wait Classes -  % of DB time '               as section from dual union all
select 'Time Model'                                             as section from dual union all
select 'Time Model - % of DB time'                              as section from dual union all
select 'System Statistics'                                      as section from dual union all
select 'System Statistics - Per Second'                         as section from dual union all
select 'System Statistics - Per Transaction'                    as section from dual union all
select 'Global Cache Efficiency Percentages'                    as section from dual union all
select 'Global Cache and Enqueue Workload Characteristics'      as section from dual union all
select 'Global Cache and Enqueue Messaging Statistics'          as section from dual union all
select 'SysStat and Global Messaging  - RAC'                    as section from dual union all
select 'SysStat and  Global Messaging (per Sec)- RAC'           as section from dual union all
select 'SysStat and Global Messaging (per Tx)- RAC'             as section from dual union all
select 'CR Blocks Served Statistics'                            as section from dual union all
select 'Current Blocks Served Statistics'                       as section from dual union all
select 'Global Cache Transfer Stats'                            as section from dual union all
select 'Global Cache Transfer (Immediate)'                      as section from dual union all
select 'Cluster Interconnect'                                   as section from dual union all
select 'Interconnect Client Statistics'                         as section from dual union all
select 'Interconnect Client Statistics (per Second)'            as section from dual union all
select 'Interconnect Device Statistics'                         as section from dual union all
select 'Interconnect Device Statistics (per Second)'            as section from dual union all
select 'Ping Statistics'                                        as section from dual union all
select 'Top Timed Events'                                       as section from dual union all
select 'Top Timed Foreground Events'                            as section from dual union all
select 'Top Timed Background Events'                            as section from dual union all
select 'Resource Manager Plan Statistics'                       as section from dual union all
select 'Resource Manager Consumer Group Statistics'             as section from dual union all
select 'SQL ordered by Elapsed Time (Global)'                   as section from dual union all
select 'SQL ordered by CPU Time (Global)'                       as section from dual union all
select 'SQL ordered by User I/O Time (Global)'                  as section from dual union all
select 'SQL ordered by Gets (Global)'                           as section from dual union all
select 'SQL ordered by Reads (Global)'                          as section from dual union all
select 'SQL ordered by UnOptimized Read Requests (Global)'      as section from dual union all
select 'SQL ordered by Optimized Reads (Global)'                as section from dual union all
select 'SQL ordered by Cluster Wait Time (Global)'              as section from dual union all
select 'SQL ordered by Executions (Global)'                     as section from dual union all
select 'IOStat by Function (per Second)'                        as section from dual union all
select 'IOStat by File Type (per Second)'                       as section from dual union all
select 'Segment Statistics (Global)'                            as section from dual union all
select 'Library Cache Activity'                                 as section from dual union all
select 'System Statistics (Global)'                             as section from dual union all
select 'Global Messaging Statistics (Global)'                   as section from dual union all
select 'System Statistics (Absolute Values)'                    as section from dual union all
select 'PGA Aggregate Target Statistics'                        as section from dual union all
select 'Process Memory Summary'                                 as section from dual union all
select 'init.ora Parameters'                                    as section from dual union all
select 'init.ora Multi-valued Parameters'                       as section from dual union all
select 'Database Summary'                                       as section from dual union all
select 'Database Instances Included In Report'                  as section from dual union all
select 'Time Model Statistics'                                  as section from dual union all
select 'Operating System Statistics'                            as section from dual union all
select 'Host Utilization Percentages'                           as section from dual union all
select 'Global Cache Load Profile'                              as section from dual union all
select 'Wait Classes'                                           as section from dual union all
select 'Wait Events'                                            as section from dual union all
select 'Cache Sizes'                                            as section from dual union all
select 'PGA Aggr Target Stats'                                  as section from dual union all
select 'init.ora Parameters'                                    as section from dual union all
select 'init.ora Multi-valued Parameters'                       as section from dual union all
select 'Global Cache Transfer Stats'                            as section from dual union all
select ' Exadata Storage Server Model'                          as section from dual union all
select ' Exadata Storage Server Version'                        as section from dual union all
select ' Exadata Storage Information'                           as section from dual union all
select ' Exadata Griddisks'                                     as section from dual union all
select ' Exadata Celldisks'                                     as section from dual union all
select ' ASM Diskgroups'                                        as section from dual union all
select ' Exadata Non-Online Disks'                              as section from dual union all
select ' Exadata Alerts Summary'                                as section from dual union all
select ' Exadata Alerts Detail'                                 as section from dual union all
select 'Exadata Statistics'                                     as section from dual;

accept  p_section     prompt 'Enter section name from above		:'

with snap as (
  select &p_bid bid, &p_eid eid from dual
),
awr as (
        select rownum line,output
        from table(
                dbms_workload_repository.awr_report_text(l_dbid=>(select dbid from v$database),l_inst_num=>&p_inst,l_bid=>(select bid from snap),l_eid=>(select eid from snap),l_options=>1+4+8)
        )
),
awr_sections as (
        select
         last_value(case when regexp_replace(output,' *DB/Inst.*$') in (''
        ,'Database Summary'
        ,'Database Instances Included In Report'
        ,'Top Event P1/P2/P3 Values'
        ,'Top SQL with Top Events'
        ,'Top SQL with Top Row Sources'
        ,'Top Sessions'
        ,'Top Blocking Sessions'
        ,'Top PL/SQL Procedures'
        ,'Top Events'
        ,'Top DB Objects'
        ,'Activity Over Time'
        ,'Wait Event Histogram Detail (64 msec to 2 sec)'
        ,'Wait Event Histogram Detail (4 sec to 2 min)'
        ,'Wait Event Histogram Detail (4 min to 1 hr)'
        ,'SQL ordered by Elapsed Time'
        ,'SQL ordered by CPU Time'
        ,'SQL ordered by User I/O Wait Time'
        ,'SQL ordered by Gets'
        ,'SQL ordered by Reads'
        ,'SQL ordered by Physical Reads (UnOptimized)'
        ,'SQL ordered by Optimized Reads'
        ,'SQL ordered by Executions'
        ,'SQL ordered by Parse Calls'
        ,'SQL ordered by Sharable Memory'
        ,'SQL ordered by Version Count'
        ,'SQL ordered by Cluster Wait Time'
        ,'Key Instance Activity Stats'
        ,'Instance Activity Stats'
        ,'IOStat by Function summary'
        ,'IOStat by Filetype summary'
        ,'IOStat by Function/Filetype summary'
        ,'Tablespace IO Stats'
        ,'File IO Stats'
        ,'Checkpoint Activity'
        ,'MTTR Advisory'
        ,'Segments by Logical Reads'
        ,'Segments by Physical Reads'
        ,'Segments by Direct Physical Reads'
        ,'Segments by Physical Read Requests'
        ,'Segments by UnOptimized Reads'
        ,'Segments by Optimized Reads'
        ,'Segments by Physical Write Requests'
        ,'Segments by Physical Writes'
        ,'Segments by Direct Physical Writes'
        ,'Segments by DB Blocks Changes'
       ,'Segments by Table Scans'
        ,'Segments by Row Lock Waits'
        ,'Segments by ITL Waits'
        ,'Segments by Buffer Busy Waits'
        ,'Segments by Global Cache Buffer Busy'
        ,'Segments by CR Blocks Received'
        ,'Segments by Current Blocks Received'
        ,'In-Memory Segments by Scans'
        ,'In-Memory Segments by DB Block Changes'
        ,'In-Memory Segments by Populate CUs'
        ,'In-Memory Segments by Repopulate CUs'
        ,'Interconnect Device Statistics'
        ,'Dynamic Remastering Stats'
        ,'Resource Manager Plan Statistics'
        ,'Resource Manager Consumer Group Statistics'
        ,'Replication System Resource Usage'
        ,'Replication SGA Usage'
        ,'GoldenGate Capture'
        ,'GoldenGate Capture Rate'
        ,'GoldenGate Apply Reader'
        ,'GoldenGate Apply Coordinator'
        ,'GoldenGate Apply Server'
        ,'GoldenGate Apply Coordinator Rate'
        ,'GoldenGate Apply Reader and Server Rate'
        ,'XStream Capture'
        ,'XStream Capture Rate'
        ,'XStream Apply Reader'
        ,'XStream Apply Coordinator'
        ,'XStream Apply Server'
        ,'XStream Apply Coordinator Rate'
        ,'XStream Apply Reader and Server Rate'
        ,'Table Statistics by DML Operations'
        ,'Table Statistics by Conflict Resolutions'
        ,'Replication Large Transaction Statistics'
        ,'Replication Long Running Transaction Statistics'
        ,'Streams Capture'
        ,'Streams Capture Rate'
        ,'Streams Apply'
        ,'Streams Apply Rate'
        ,'Buffered Queues'
        ,'Buffered Queue Subscribers'
        ,'Persistent Queues'
        ,'Persistent Queues Rate'
        ,'Persistent Queue Subscribers'
        ,'Rule Set'
        ,'Shared Servers Activity'
        ,'Shared Servers Rates'
        ,'Shared Servers Utilization'
        ,'Shared Servers Common Queue'
        ,'Shared Servers Dispatchers'
        ,'init.ora Parameters'
        ,'init.ora Multi-Valued Parameters'
        ,'Cluster Interconnect'
        ,'Wait Classes by Total Wait Time'
        ,'Top 10 Foreground Events by Total Wait Time'
        ,'Top ADDM Findings by Average Active Sessions'
        ,'Cache Sizes'
        ,'Host Configuration Comparison'
        ,'Top Timed Events'
        ,'Top SQL Comparison by Elapsed Time'
        ,'Top SQL Comparison by I/O Time'
        ,'Top SQL Comparison by CPU Time'
        ,'Top SQL Comparison by Buffer Gets'
        ,'Top SQL Comparison by Physical Reads'
        ,'Top SQL Comparison by UnOptimized Read Requests'
        ,'Top SQL Comparison by Optimized Reads'
        ,'Top SQL Comparison by Executions'
        ,'Top SQL Comparison by Parse Calls'
        ,'Top SQL Comparison by Cluster Wait Time'
        ,'Top SQL Comparison by Sharable Memory'
        ,'Top SQL Comparison by Version Count'
        ,'Top Segments Comparison by Logical Reads'
        ,'Top Segments Comparison by Physical Reads'
        ,'Top Segments Comparison by Direct Physical Reads'
        ,'Top Segments Comparison by Physical Read Requests'
        ,'Top Segments Comparison by Optimized Read Requests'
        ,'Top Segments Comparison by Physical Write Requests'
        ,'Top Segments Comparison by Physical Writes'
        ,'Top Segments Comparison by Table Scans'
        ,'Top Segments Comparison by DB Block Changes'
        ,'Top Segments by Buffer Busy Waits'
        ,'Top Segments by Row Lock Waits'
        ,'Top Segments by ITL Waits'
        ,'Top Segments by CR Blocks Received'
        ,'Top Segments by Current Blocks Received'
        ,'Top Segments by GC Buffer Busy Waits'
        ,'Top In-Memory Segments Comparison by Scans'
        ,'Top In-Memory Segments Comparison by DB Block Changes'
        ,'Top In-Memory Segments Comparison by Populate CUs'
        ,'Top In-Memory Segments Comparison by Repopulate CUs'
        ,'Service Statistics'
        ,'Service Statistics (RAC)'
        ,'Global Messaging Statistics'
        ,'Global CR Served Stats'
        ,'Global CURRENT Served Stats'
        ,'Replication System Resource Usage'
        ,'Replication SGA Usage'
        ,'Streams by CPU Time'
        ,'GoldenGate Capture'
        ,'GoldenGate Capture Rate'
        ,'GoldenGate Apply Coordinator'
        ,'GoldenGate Apply Reader'
        ,'GoldenGate Apply Server'
        ,'GoldenGate Apply Coordinator Rate'
        ,'GoldenGate Apply Reader and Server Rate'
        ,'XStream Capture'
        ,'XStream Capture Rate'
        ,'XStream Apply Coordinator'
        ,'XStream Apply Reader'
        ,'XStream Apply Server'
        ,'XStream Apply Coordinator Rate'
        ,'XStream Apply Reader and Server Rate'
        ,'Table Statistics by DML Operations'
        ,'Table Statistics by Conflict Resolutions'
        ,'Replication Large Transaction Statistics'
        ,'Replication Long Running Transaction Statistics'
        ,'Streams by IO Time'
        ,'Streams Capture'
        ,'Streams Capture Rate'
        ,'Streams Apply'
        ,'Streams Apply Rate'
        ,'Buffered Queues'
        ,'Rule Set by Evaluations'
        ,'Rule Set by Elapsed Time'
        ,'Persistent Queues'
        ,'Persistent Queues Rate'
        ,'IOStat by Function - Data Rate per Second'
        ,'IOStat by Function - Requests per Second'
        ,'IOStat by File Type - Data Rate per Second'
        ,'IOStat by File Type - Requests per Second'
        ,'Tablespace IO Stats'
        ,'Top File Comparison by IO'
        ,'Top File Comparison by Read Time'
        ,'Top File Comparison by Buffer Waits'
        ,'Key Instance Activity Stats'
        ,'Other Instance Activity Stats'
        ,'Enqueue Activity'
        ,'Buffer Wait Statistics'
        ,'Dynamic Remastering Stats'
        ,'Library Cache Activity'
        ,'Library Cache Activity (RAC)'
        ,'init.ora Parameters'
        ,'init.ora Multi-Valued Parameters'
        ,'Buffered Subscribers'
        ,'Persistent Queue Subscribers'
        ,'Shared Servers Activity'
        ,'Shared Servers Rates'
        ,'Shared Servers Utilization'
        ,'Shared Servers Common Queue'
        ,'Shared Servers Dispatchers'
        ,'Database Summary'
        ,'Database Instances Included In Report'
        ,'Top ADDM Findings by Average Active Sessions'
        ,'Cache Sizes'
        ,'OS Statistics By Instance'
        ,'Foreground Wait Classes -  % of Total DB time'
        ,'Foreground Wait Classes'
        ,'Foreground Wait Classes -  % of DB time '
        ,'Time Model'
        ,'Time Model - % of DB time'
        ,'System Statistics'
        ,'System Statistics - Per Second'
        ,'System Statistics - Per Transaction'
        ,'Global Cache Efficiency Percentages'
        ,'Global Cache and Enqueue Workload Characteristics'
        ,'Global Cache and Enqueue Messaging Statistics'
        ,'SysStat and Global Messaging  - RAC'
        ,'SysStat and  Global Messaging (per Sec)- RAC'
        ,'SysStat and Global Messaging (per Tx)- RAC'
        ,'CR Blocks Served Statistics'
        ,'Current Blocks Served Statistics'
        ,'Global Cache Transfer Stats'
        ,'Global Cache Transfer (Immediate)'
        ,'Cluster Interconnect'
        ,'Interconnect Client Statistics'
        ,'Interconnect Client Statistics (per Second)'
        ,'Interconnect Device Statistics'
        ,'Interconnect Device Statistics (per Second)'
        ,'Ping Statistics'
        ,'Top Timed Events'
        ,'Top Timed Foreground Events'
        ,'Top Timed Background Events'
        ,'Resource Manager Plan Statistics'
        ,'Resource Manager Consumer Group Statistics'
        ,'SQL ordered by Elapsed Time (Global)'
        ,'SQL ordered by CPU Time (Global)'
        ,'SQL ordered by User I/O Time (Global)'
        ,'SQL ordered by Gets (Global)'
        ,'SQL ordered by Reads (Global)'
        ,'SQL ordered by UnOptimized Read Requests (Global)'
        ,'SQL ordered by Optimized Reads (Global)'
        ,'SQL ordered by Cluster Wait Time (Global)'
        ,'SQL ordered by Executions (Global)'
        ,'IOStat by Function (per Second)'
        ,'IOStat by File Type (per Second)'
        ,'Segment Statistics (Global)'
        ,'Library Cache Activity'
        ,'System Statistics (Global)'
        ,'Global Messaging Statistics (Global)'
        ,'System Statistics (Absolute Values)'
        ,'PGA Aggregate Target Statistics'
        ,'Process Memory Summary'
        ,'init.ora Parameters'
        ,'init.ora Multi-valued Parameters'
        ,'Database Summary'
        ,'Database Instances Included In Report'
        ,'Time Model Statistics'
        ,'Operating System Statistics'
        ,'Host Utilization Percentages'
        ,'Global Cache Load Profile'
        ,'Wait Classes'
        ,'Wait Events'
        ,'Cache Sizes'
        ,'PGA Aggr Target Stats'
        ,'init.ora Parameters'
        ,'init.ora Multi-valued Parameters'
        ,'Global Cache Transfer Stats'
        ,' Exadata Storage Server Model'
        ,' Exadata Storage Server Version'
        ,' Exadata Storage Information'
        ,' Exadata Griddisks'
        ,' Exadata Celldisks'
        ,' ASM Diskgroups'
        ,' Exadata Non-Online Disks'
        ,' Exadata Alerts Summary'
        ,' Exadata Alerts Detail'
        ,'Exadata Statistics'
) then output end ) ignore nulls over(order by line) section
        ,output
        from awr
)
select output AWR_REPORT_TEXT from awr_sections where regexp_like(section,'&p_section') or regexp_like(output,'')
/