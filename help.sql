#Admin

reg.sql													: Registry history
                          			
#ASH                      			
		                      			
active_session_sql.sql 					: Display SQL Text for active sessions                	
as.sql 													: Display SQL Text for active sessions
ash_awr_sql_timings.sql					: For batch type sql show ash and awr statistics
ash_enq_TX_rowdetail.sql				: Find row details for sessions waiting on enq: TX - row lock contention
ash_plsql.sql										: Analyze ASH PL/SQL programs to show time spent in PL/SQL vs SQL
ash_sql_timings.sql    					: Display detailed ASH SQLID timings 
ash_wait_chains.sql							: Wait Chains based on V$ACTIVE_SESSION_HISTORY
ashmon.bat											: Client based ASH tool			
ashtop.sql											: Tanels ASH top script based on V$ACTIVE_SESSION_HISTORY
asqlmon.sql											: ASH SQL Monitoring based on v$ACTIVE_SESSION_HISTORY
asqlmon_hist.sql								: ASM SQL Monitoring based on DBA_HIST_ACTIVE_SESS_HISTORY
dash_wait_chains.sql						: Wait chains based on DBA_HIST_ACTIVE_SESS_HISTORY
dashtop.sql											: Tanels ASH top script based on DBA_HIST_ACTIVE_SESS_HISTORY
event_hist.sql									: Wait event histogram based on ASH
event_hist_cell.sql							: Wait event histogram based on ASH for Exadata by cell servers
event_hist_micro.sql						: Wait event histogram based on ASH for micro
rowsource_events.sql						: ASH based row source details
shortmon.sql										: Short wait event monitor such as log file sync, log file parallel write etc
                          			
                          			
#ASM                      			
                   	      			                                                            	                                             
asm.sql            							: ASM scripts						   
asm_dg_space.sql        				: Show diskgroup storage capacity		
asm_extentbalance.sql   				: Show asm disk group variance				
asm_list_disk_dg.sql    				: List asm disk and diskgroup mapping	     
asm_partnerdisk.sql							: Show asm partner disk relationships			          
asm_partnerdisk_bal.sql 				: Show asm partner disk balance			         
asm_recreate.sql								: Show details to recreate asm disk group	
asm_storage_usage.sql						: Show asm diskgroup storage usage		
			                    			
                        				                                                                  	
#AWR                      			
                          			
awr_dbtime.sql									: Find busiest time periods in AWR.
awr_dbtime_trend.sql						: DB Time breakdown over a period of time (value and %). Also check awr_dbtime_trend1.sql
awr_instance_caging.sql					: Shows CPU utilization when instance caging is configured.
awr_io_trend_file_fun.sql 			: Show IO statistics by File Type and Function name
awr_io_trend_filestat.sql 			: Show IO statistics by Data File/Tablespace
awr_io_trend_filetype.sql 			: Show IO statistics by File Type
awr_io_trend_function.sql				: Show IO statistics by Function
awr_io_trend_temp_filestat.sql	: Show IO statistics by Temp File
awr_os_stat.sql									: Show OS statistics (DBA_HIST_OSSTAT)
awr_plan_change_new.sql					: Shows different plan hash values ordered by elapsed_time.
awr_plan_change.sql							: Shows history of plan changes
awr_plan_stats.sql							: Shows stats (etime, lio etc) for statements by plan  	
awr_redo_nolog_size.sql					: Redo size estimation when force logging is turned off
awr_redo_size.sql								: Daily redo size 
awr_redo_size_history.sql				: Daily redo size hourly
awr_redo_size_rac.sql						: Redo size history for RAC
awr_section.sql									: Display any section of AWR for given snap ids.
awr_service_wait_class.sql			: Display database service wait class statistics for given range.
awr_snaps.sql										: List/Find AWR snaps based on interval 
awr_sqlid_perf_trend.sql				: Historical statistics for given SQL ID (similar to awr_plan_change.sql)
awr_sqlid_perf_trend_gline.sql	: Historical statistics for given SQL ID (similar to awr_plan_change.sql) using google charts.
awr_stat_trend.sql							: Show historical AWR statistics trend.
awr_sysmetric_trend.sql					: Show metric trend from sysmetric_summary.
awr_stat_trend_gline.sql				: Show historical AWR statistics trend in google line chart format.
awr_topobjects.sql							: Find AWR top objects by metrics such as LIO, PIO, ITL etc
awr_topsql.sql									: Find AWR top SQL by metrics such as CPU, LIO, PIO etc
awr_topsql_wdb.sql							: Find AWR top SQL by metrics such as CPU, LIO, PIO etc with % of dbtime
awr_topsql_wdb_sig.sql					: Find AWR top SQL (force_match) by metrics such as CPU, LIO, PIO etc with % of dbtime
awr_wait_hist_wc_pct.sql				: Show dba_hist_event_histogram latency buckets differnce between snapshots.
awr_wait_histogram.sql					: Show difference of dba_hist_event_histogram between two snapshots for given event.
awr_wait_trend.sql							: Show historical AWR wait event trend.
exa_awr_flash_hitratio.sql			: Show Exadata Flash hit ratio
exa_awr_smartscan.sql						: Show Exadata smart scan, storage index, flash statistics.
log_switch.sql									: Show redo log switch from gv$log_history by hour
sql-analysis.sql								: Historical SQL analysis (similar to awr_plan_stat.sql and awr_plan_change.sql)
awrsqlrpt.sql										: Display AWR sql plans based on snapshots       	        
awrlast.sql											: Generate awr report for last two snapshots      	        
awr_iostat.sql									: Generate IO report from AWR snapshots 
unstable_plans.sql							: Attempts to find SQL statments with plan instability.
whats_changed.sql								: Find statemens that have significantly different elapsed time than before.
whats_changed_c.sql						  : Find statemens that have significantly different elapsed time than before - Carlos Sierra version.
whats_changed_k.sql							: Finding the slowest SQL execution of the same query  based on ASH

# Backup and Recovery

backup_detail.sql								: Shows rman backup set details based on backup_summary.sql record id and stamp
backup_log.sql									: Shows log of rman based on backup_summary.sql record id and stamp
backup_summary.sql							: Shows summary of rman backups
                         			
# Buffer Cache            			
                          			
kcbbes.sql											: checkpoint reasons and buffer counts
kcboqh.sql											: buffer counts per segment in buffer cache
                          			
# Data Guard              			
                    			
                          			
#Exadata Database       				                                                             	
                        				
fsx4.sql 	   										: Display IO saved in %			        		
fsx3.sql 	   										: Display whether smart scan is used or not        		
sqlfn_offload.sql  							: Display SQL functions that can be offloaded        		
get_comp_ratio.sql 							: Display compression ratio estimates        			
si.sql 		   										: Display storage index statistics for current session		
esfc_hit_ratio.sql     					: Display Flash Cache hit ratio*******				
exasnap.sql 	       						: Exasnapper by Tanel Poder					
exafriendly.sql        					: Exa statistics						
examystats.sql         					: Display smart scan stats for current session                  
awr_exawait.sql         				: AWR Exadata wait events					
awr_ashpast_bydtl.sql   				: AWR ASH by sqlid						
awr_ashpast_bytype.sql  				: AWR ASH by type						
awr_ashpast_details.sql 				: AWR ASH details						
ss_ashcurrdetails.sql   				: ASH smart scan details					
ss_ashpast_details.sql  				: AWR ASH smart scan details				
exa_lightwaits.sql      				: List current exadata wait events				
exawait_ashcurr.sql     				: List ASH Exadata wait events				
ashcurredetails.sql     				: List ASH current details
ciops-all.sh										: Show Exadata IOPS
ciops-mon.sh										: Monitor Exadata IOPS every few minutes				
                    	    			
#Exadata Storage        				                                                            	
                          			
cellio.sql											: Cell IO script
cth.sql													: View cell thread history from database.                     	
show_cell.sql		   							: Display cell configuration        			
show_celldisks.sql	   					: Display cell disk configuration        	        	
show_griddisks.sql	   					: Display grid disk configuration        	       	 	
show_lun.sql		   							: Display lun configuration        	        		
show_physicaldisk.sql	  				: Display physical disk configuration        			
show_activerequest.pl	  				: Display active IO requests on stroage cell     		
celldisk-iostats.sh  	    			: Display celldisk IO statistics				
celldisk-smvsla.pl   	    			: Display small and large IO requests				
griddisk-iostats.sh  	    			: Display grid disk IO bottlenecks				
interconnect-probs.sh	    			: Display host interconnect bottlenecks				
flashlog-eff.sh	    	    			: Display flash cache efficiency	
cellsrvstat 										: statspack for cell server			
                        				         	
#Instance               				
                        				
hint.sql    										: Find hints @hint %batch%
hinth.sql												: Display hint Hierarchy
lightwaits.sql									: Instance Waits overview 
moat.sql												: MOAT: Mother of all tuning      	      	                
moat_rac.sql										: MOAT: Mother of all tuning  for RAC/Exadata
refresh.sql											: Refresh output of specific script at nth interval
swact.sql												: Coskan Instance waits @sw for all sessions
systat.sql											: Shows system statsitics @sys commits
ub.sql													: Background processes	 
valid_events.sql								: List/Search Oracle wait events	              
wait_histogram.sql							: Instance wide wait histogram with latencies    
whoami.sql											: Session overview
                          			
#IO                       			
ehm.sql													: RAC Real time monitoring of IO wait event histogram.
ehm_local.sql										: Real time monitoring of IO wait events (same as ehm.sql for but for single instance)
iostat.sql											: Database iostat	
oraiomon.sql										: Based on Kyle Haileys IO monitoring shell script oramon.sh
OraLatencyMap.sql								: Display Oracle latency heat maps.
wait_histogram_wc_pct.sql 			: v$event_histogram sampling
                          			
                        				
#Lock Latch and Mutexes 				                                                              	
                        				
bl.sql													: Displays blocking lock for single instance		
bclass.sql											: Block class for buffer busy waits p3	
bufprof.sql											: ** Shows type of logical IO (may or may not work)  	
dba.sql													: locate block in x$bh	
enq_TX_rowdetail.sql						: Find row details for sessions waiting on enq: TX - row lock contention
kgllk.sql												: Library cache lock @kgllk kgllkhdl='P1 without 0x' from @sw		
kglpn.sql												: Library cache pin @kglpn kglhdadr='' from @sw	
latchprof.sql										: Tanel Poder's latchprof.sql (dba.sql)
latchprofx.sql									: Tanel Poder's extended latchprofx.sql (dba.sql)
lc.sql		        							: Display child latch statistics				
lm.sql		        							: Display child latch misses			
lt.sql		        							: Display lock type description @lt TM			
mutexprof.sql	        					: Find mutexes holders and blockers			
tracing_enqueues.txt						: Trace enqueue 10704 and 10706 event	
                          			
#Materialized Views       			
                          			
advise_mview.sql								: Advise mview based on SQL
                        				
#Miscellaneous          				
                        				
html		        								: Convert output to html format								
ostackprof.sql									: Shows formatted stack @ostackprof <sid> <interval> <samp>
sample.sql											: Sample Database Views                          	         	        		
                        				
#Objects                				                                               
                        				
d.sql		        								: Find fixed views or data dictionary views	
ddl.sql													: Display ddl for an object	
desc.sql												: Describe table @desc OWNER.TABLE
estimate_index_size.sql					: Script to quickly estimate the size of an index if it were to be rebuilt.	
f.sql		        								: Fixed view definition @f v$SQL	
fobj.sql												: Find object name
index_fragmentation.sql					: Shows index structure details and fragmentation by blocks.
oid.sql													: Find object details based on object id @oid.sql <oid>						
procid.sql											: Display procedure/function/package name by object_id and subobject_id 
seg2.sql												: Display Segment statistics from dba_segments		
segstat.sql											: Segment statistics @segstat <owner> <segname>	<statistics name>	
tab.sql													: Search for object name @tab %undo%	
table_relation.sql							: Display table hierarchy relationships for given schema.
table_relation_graph.sql			  : Display table hierarchy relationships for given schema in ER diagram format.
table_subset_relation_graph.sql : Display table hierarchy relationships for given table in ER diagram format.
                        				             	
                        				
#PARALLEL               				                                                       	
                          			
bloom_join_filter.sql						: Returns information about bloom filter based on QC sid.                 	
psession.sql   									: Display parallel sessions		
px_dowgrade.sql									: parallel downgrade operation						
px_pool_status.sql							: Status of parallel processes
px_slave_dist.sql								: slave data distribution for previous query				
px_tq_mem.sql										: Memory usage by table queue	     			
pxs.sql													: Display parallel QC and slave 	
tq.sql													: Shows table queue from last parallel execution		
                        				
#Parameter and Optimizer				                                                       	
                        				
parms.sql												: Display parameter value by passing parameter		
parmsd.sql											: Display parameter description				
pd.sql													: Display parameter value by passing parameter  	        
pv.sql													: Display parameters and values by passing value	        
pvalid.sql											: Display possible, valid and default values of parameter  
sesopt.sql											: Display session optimizer parameters			
sp.sql													: Parameters specified in spfile.
                        				
#PARTITION              				                                                        	
                        				
partkeys.sql  									: Display partition key column @partkeys OWNER.TABLE	
partpruning.sql									: Partition pruning for script for event 10128		
tabpart.sql   									: Display table partition @tabpart OWNER.TABLE		
tabsubpart.sql									: Display table sub partition @tabsubpart OWNER.TABLE
                        	
#PGA and Temporary Tablespace                                                       	
                        	
pga_alloc.sql										: Shows allocated and maximum allocated PGA memory	        
pga_bysession.sql								: Shows pga memory usage by session	
pmemory.sql											: Shows process memory allocation and usage	         	 	        
psort.sql												: Shows temporary tablepsace usage by process        	
sortsize.sql										: Shows allocated, used and free sort space       	        
workarea_active.sql							: Shows memory usage for active workareas
                        				
#Session 
               				                                      	
global.sql											: Find session details from remote database through dblink                      				
kill.sql												: Kill database sessions
kill_rac.sql										: Kill RAC database sessions
mys.sql													: Session statistics for current session
runstats.sql										: Tom Kytes run1 run2 stats difference
se.sql													: Session event summary
sed.sql													: Session event description p1 p2 p3 @sed "event name"     				
ses.sql													: Session statistics 
ses_time_model.sql							: Session time model  			
ses_wait.sql										: Session current Wait 
sessinfo.sql										: Session information  	
session_longops.sql							: Display long running session   					
sest.sql												: Session time model v$ses_time_model			
set_sess_para.sql      					: Set session parameter(integer) for different session     
set_sess_para_b.sql    					: Set session parameter(boolean) for different session     
waitprof.sql										: Sample V$SESSION_WAIT at high frequency			
parsetrc.pl             				: Create IO histogram from trace files			
			                  				
                        				
#SGA			              				                                            	
                          			
flush_cursor.sql								: Flush cursor from SGA                    	
ksmlru.sql											: Who is flushing how much SGA and why (only top) 		
ksmsp.sql												: ** Performs Shared pool heap dump  
recent_sql.sql									: check for SQL that has recently appeared in the SGA heap 
sga_resize.sql  	 							: Displays recent SGA resize operations
sgastat.sql											: Display SGA stats @sgastat %library%			
shared_sub_pool.sql							: How many shared subpools does Oracle instance have
                        				
                        				
#Space                  				
                      					        
freespace.sql										: Tablespace space usage report               
release_tbs_space.sql						: Resize/Shrink datafiles @release_tbs_space <tbs name>    
	                      	
                        	
#SQL PLAN, SQLID, SQL Timings                                                      	

build_bind_sqlmonitor.sql 			: Build SQL*Plus script with variable definitions from gv$sql_monitor.
build_bind_vars.sql       			: Build SQL*Plus test script w/ variable definitions – including peeked binds (OTHER_XML) – formerly build_bind_vars.sql
build_bind_vars_awr.sql					: Build SQL*Plus test script w/ variable definitions – including binds from AWR – formerly build_bind_vars_awr.sql
build_bind_vars_plsql.sql				: Build SQL*Plus test script using pl/sql for dates         
build_bind_vars2.sql						: Build SQL*Plus test script w/ variable definitions – including binds from V$SQL_BIND_CAPTURE – formerly build_bind_vars2.sql
expand_sql_11g.sql							: Expand SQL text(views converted to SQL) in 11g
expand_sql_12c.sql							: Expand SQL text(views converted to SQL) in 12c
format_sqltext.sql							: Format sql text
gen_sqlidfromsql.sql						: Generate sqlid from SQL text
getplan_awr.sql									: Display AWR SQL Plan 
getplan_awr_tree.sql					  : Display SQL Plan tree from dba_hist_sql_plan                           		
getplan_cursor.sql							: Display runtime SQL Plan using SQL ID
getplan_cursor_tree.sql				  : Display SQL Plan Tree using SQL ID and plan hash value from gv$sql_plan_statistics_all           		
getplan_prev.sql								: Display previous explain plan for same session
getplan_realsqlmonitor_tree.sql	: Display SQL Plan Tree from real time sql monitor v$sql_monitor
getplan_spm.sql									: Display SQL Plan for SQL Plan Baselines.
getsql.sql											: Display SQL Text for SID
getsqlbind.sql									: Display bind variable values for SQL by SID     		  
hash.sql												: Display hash value, sql id for last sql	
nonshared.sql										: Show reasons for child cursors @nonshared <sqlid>	
plan_viz_sqlplan.sql						: Visualize plan/statistics using graphviz
sqlid.sql												: Display SQL Text, child cursor and execution stats
sqlid_n.sql											: Display SQL statistics in n seconds.
sqlidx.sql											: Display detailed SQL Text, child cursor and execution stat
sqlmem.sql											: Memory used by sql @sqlmem.sql <hash>			
x.sql														: Display execution plan for last sql in current session
xb.sql													: Display execution plan statistics such as logical io/row
x9.sql													: Display execution plan only SQL>select...@x9.sql     			
xi.sql													: Display execution plan by sql id @xi <sqlid> <cursor>    
xplain.sql											: Display SQL Plan (use for cardinality comparision)
xplan/xplan.sql        					: Display detailed SQL Plan	
xplan_ash.sql										: Display detailed SQL (Plan, ASH samples, Parallel Distribution/Skew etc).
java -jar xtrace.jar    				: SQL Trace GUI    				
#getsqlplan.sql									: Display runtime SQL Plan using SID              		
                        	
# SQL creats and SQL Plan Baselines and real time SQL monitoring

coe_load_sql_baseline.sql				: loads a plan from a modified SQL into the SPM of original SQL
coe_xfr_sql_profile.sql					: SQL Profile building script from SQLTXPLAIN
create_spm_awr.sql							: Create SPM from AWR
create_spm_cursor.sql						: Create SPM from cursor  
diff_pre_byphv.sql							: Show difference in predicates by plan hash value
diff_pred_bysqlid.sql    				: Show difference in predicates by sqlid
drop_spm.sql										: Drop SPM
drop_sql_profile.sql						: Drop SQL Profile
find_pred_mismatch.sql					: Identify SQL with mismatch predicate
getplan_baseline.sql						: Display baseline SQL Plan >=11g 
report_sql_monitor.sql 					: SQL monitoring report in command line
spm_hints.sql										: Hints used by SQL Plan baselines
sql_profile_hints.sql						: Hints used by SQL profile
sqlpch.sql											: Add hint for SQLID using sql patch (eg: BIND_AWARE)
xpa.sql    											: SQL monitoring report in html	  
                          			
# SQL Tuning Sets         			
                          			
getplan_STS.sql									: Display execution plan from SQL tuning Set.
run_STA_sqlid.sql								: Run SQL Tuning advisor for given SQL id.
                      	  			
#Statistics             				
                        				
column_statistics.sql						: Show detailed column statistics for table				
column_usage.sql								: Show column usage from col_usage$
comp_obj_stats.sql							: Compare object statistics history >=11g
descx.sql												: Describe table advanced @desc OWNER.TABLE	
ind.sql													: Display index statistics
ind_stat_hist.sql								: Display Index statistics history
statistics.sql									: Display detailed table level statistics			
tab_stat_hist.sql								: Display Table statistics history	
tab2.sql												: Display Table statistics from dba_tables	
                          			
                        				
#Trace                  				
46off.sql												: Disable 10046 for current session                                                 	
46on.sql												: Enable 10046 for current session
53off.sql												: Disable 10053 for current session
53on.sql												: Enable 10053 for current session
dbms_hprofile.sql								: Show pl/sql hierarchical profiler data for runid.
dump_block.sql									: Dump block command				                
System State Dump								: Metalink 121779.1,374569.1,359536.1 when you cannot connect to database          
Interpret Systemstate						: Metalink 423153.1							
Hanganalyze											: Metalink 175006.1, 215858.1
#trace.sql											: Trace sid						
#traceoff.sql										: Stop Trace				
                        	
#Undo Redo and Transactions                                               	
                        	
ktuxe.sql												: query dead transaction from undo seg headers after crash 
rollback_stats.sql							: Show progress of SMON rollback/recovery.
trans.sql												: How many undo blocks are created by session/transaction				
uds.sql													: Undo stats 	

                        	
#Users Roles and Profiles

createuserlike.sql							: Create user like another one @createuserlike EUSER NUSER 		
                        	          	
#Underscore parameters
                                                                   	
_serial_direct_read 	  							: Force serial reads to direct path reads   		
_kcfis_storageidx_disable 						: Disable/Enable Stroage indexes		   		
_bloom_predicate_pushdown_to_storage 	: Disable/Enable Bloom Filters		
_CELL_OFFLOAD_HYBRIDCOLUMNAR 					: Disable/Enable smart scan on HCC data		
_CELL_OFFLOAD_DECRYPTION 							: Disable/enable smart scan on Encrypted Data		
_cell_offload_virtual_columns 				: Disable/enable smart scan on Virtual columns	
_DISABLE_CELL_IMIZED_BACKUPS 					: Disable smart rman incremental backups		
_KCFIS_STORAGEIDX_DIAG_MODE 					: Stroage index scan on Exadata storage cell		
 
 
Events:

10132 - check for errors in hints

Errorstack
alter system set events '942 trace name errorstack level 3';
alter system set events '942 trace name context off';

Trace particular sql id
alter system set events 'sql_trace [sql:06d4jjswswagq] wait=true, plan_stat=all_executions';
alter system set events 'sql_trace [sql:06d4jjswswagq] off';
                                                           	

