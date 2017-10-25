set head off
set feed off
set echo off
set linesize 150
set serveroutput on

/*                         01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345 */
/*                                  10         20        30        40        50        60        70        80        90        100       110       120       130       140    */

exec dbms_output.put_line('=====================================================================================================================================================');
exec dbms_output.put_line('Monitoring								 Statistics  	 			     				        ');
exec dbms_output.put_line('__________								 __________  				     				        ');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('session_longops - long running operations   				 column_staistics - column high, low value, density, null,distinct, histogram   ');
exec dbms_output.put_line('v$sql_hints - list available hints					 column_usage - find column predicates used by queries instance, schema wide    ');
exec dbms_output.put_line('									 comparing_object_statistics - compare object statistics with history etc       ');
exec dbms_output.put_line('																			');
exec dbms_output.put_line('Explain Plan								 Memory										');
exec dbms_output.put_line('____________								 __________  				     				        ');
exec dbms_output.put_line('									 	  				     				        ');
exec dbms_output.put_line('getplan_prev - get explain plan for previous explain plan stmt		 pga_alloc - Shows allocated and maximum allocated PGA			');
exec dbms_output.put_line('getplan_cursor - get explain plan from SGA				 pga_bysession - Shows pga memory usage by session				');
exec dbms_output.put_line('getplan_awr - get explain plan from AWR					 workarea_active - Shows pga memory usage by active operations/sids	');
exec dbms_output.put_line('awrsqlrpt.sql - explain plan history from AWR													');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('SQL Tuning                                                                                                  					        ');
exec dbms_output.put_line('__________                                                                                                  					        ');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('sqlprofile_hints - hints used by sql profile and sql plan baseline                                                                                   ');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('Important Views								 Parallel                                           				');
exec dbms_output.put_line('_______________                                                          ________                                              			');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('v$sql_hints - list available hints                                       px_pool_status - status of parallel processes				');
exec dbms_output.put_line('v$sql_plan - execution plan during parse time                            px_tq_mem - memory usage by table queue                           		');
exec dbms_output.put_line('v$sql_plan_statistics - real time exec plan(statistic_level=all)         px_downgrade - parallel operations downgraded                      		');
exec dbms_output.put_line('			or hint gather_plan_statistics			 px_slave_dist - slave data distribution                                     ');
exec dbms_output.put_line('v$sql_workarea - memory workareas                                                                                                         		');
exec dbms_output.put_line('v$sql_plan_statistics_all - combined information from v$sql_plan*                                                                                    ');
exec dbms_output.put_line('v$sys_optimizer_env - execution environment at instance                                                                                        	');
exec dbms_output.put_line('v$ses_optimizer_env - execution environment at session                                                                                         	');
exec dbms_output.put_line('v$sql_optimizer_env - execution environment at sql                                                                                             	');
exec dbms_output.put_line('                                                                                                      					        ');

exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('                                                                                                      					        ');
exec dbms_output.put_line('*****************************************************************************************************************************************************');
exec dbms_output.put_line('Oracle performance firefighting scripts - OSM folder                                                                                                 ');



