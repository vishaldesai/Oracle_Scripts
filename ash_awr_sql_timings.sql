-- Note this sql should be used only when you are trying to track elapsed time of bunch of 
-- batch type sql that runs only one time

-- parallel 
--trunc(px_flags / 2097152): The actual DOP (for the current DFO)
--trunc(mod(px_flags/65536, 32)): the "PX Step ID" (1 or 2 for PX operations of the plan, )
--mod(px_flags, 65536): The "PX Step ARG" (Allows to identify the (other) Table Queue involved in the operation)

column tab_n format a30
column start_time format a18
column end_time format a18
column sql_plan_hash_value heading hash_value format 9999999999999999
column parallel_dop heading DOP format 99999
column awrexecs format 999999
column awrelapsec format 999999
column cpu_s format 999999
column iowait_s format 999999
column clwait_s format 999999
column apwait_s format 999999
column ccwait_s format 999999
column rows_n format 9999999999
column buffer_gets format 9999999999
column direct_reads format 9999999999
column direct_writes format 9999999999
set linesize 500
set pages 999
accept sqlid char prompt 'Enter list of sqlid   :'
accept ndate prompt 'Enter MM/DD/YY :'

/* select listagg (sql_id,',') WITHIN GROUP (ORDER BY sql_id) as listsqlid from
  (
 select '''' || sql_id || '''' as sql_id from dba_hist_sqltext
 where  upper(sql_text) LIKE 'MERGE%SRC_MSP_ACCTS.%');
 
 */

WITH sqlid_tab_map
     AS (SELECT sql_id msql_id,
                TO_CHAR(SUBSTR (
                   REPLACE (
                      REGEXP_SUBSTR (UPPER (sql_text), 'INTO.*TGT USING'),
                      ' TGT USING',
                      ''),
                     INSTR (
                        REGEXP_SUBSTR (UPPER (sql_text), 'INTO.*TGT USING'),
                        '.')
                   + 1))
                   tab_n
           FROM dba_hist_sqltext
          WHERE     -- PROD
                    UPPER (sql_text) LIKE 'MERGE%SRC_MSP_ACCTS.%'
          ),
    ash
    AS   (
              SELECT
                    sql_id
                   ,sql_exec_id
                   ,sql_plan_hash_value
                   ,end_time
                   ,parallel_dop
                   ,MIN(start_time) start_time
              FROM
                     (
                            SELECT
                                   sql_id
                                 , sql_exec_id
                                 , sql_plan_hash_value
                                 , MAX(CAST(sample_time AS DATE)) end_time
                                 , CAST(sql_exec_start AS DATE) start_time
                                 , COUNT (distinct session_id) parallel_dop
                            FROM
                                   dba_hist_active_sess_history ,
                                   sqlid_tab_map 
                            WHERE
                                   sql_exec_id IS NOT NULL
                             --AND sql_id       in ('132uhuxjn8wth','1zfp819wwmumd','3h032r227yuvu','3qhp336a9vvav','3y7tv32gdwf99','42j2xtcmh440x','434yyzb6q8q0u','4ccf90hr4mbbd','4s8qbnyku75gx','4zdudd9r44g39','689g469htpkzj','6wjx3vyq0a8ab','742n9zw1n9c0m','7cpr4g94k308b','7rjvk68bv2qfv','8fu3j96jxgcsc','8wrdzqgunvzax','96v3w9nh125rc','99qzyzt7abf2h','ab861p9hmjvdc','atkusxx09cpgs','ax3kquhvhz9sh','b9t7962c495a3','bd4wagu0k56xr','bjj4bnjn3stmc','bm1p0v6znrxbx','bm6js3j8w0jrz','c95vzp19gcd8n','cfy2n3fvc3kbm','ck4bj245431nc','cu7y2sjpkqk57','d4nn1huadncc7', 'd926yur4zx4pp','dwh73fhgx96b6','f3g1kzzu78r7h','fjf8fpw7j7bn8','fv8tqw9zpmgrt','fyzt834k7hzaq','g9p9jmw4pfzqd','gfruk3qatamjs','gn99wrrbymccx','gv0aghtcunakj')
                               AND msql_id = sql_id
                               AND to_char(sample_time,'MM/DD/YY') = '&ndate'
                            GROUP BY
                                   sql_id
                                 , sql_exec_id
                                 , sql_plan_hash_value
                                 , sql_exec_start
                     )
              GROUP BY
                     sql_id
                   ,sql_exec_id
                   ,sql_plan_hash_value
                   ,end_time
                   ,parallel_dop
       ),
    awr
    AS (   SELECT
					       hss.sql_id
					     , tab_n
					     , round(SUM(hss.elapsed_time_delta)/1000000) elapsed_time_s
					     , round(SUM(hss.cpu_time_delta)    /1000000) cpu_time_s
					     , round(SUM(hss.iowait_delta)      /1000000) iowait_time_s
					     , round(SUM(hss.clwait_delta)      /1000000) clwait_time_s
					     , round(SUM(hss.apwait_delta)      /1000000) apwait_time_s
					     , round(SUM(hss.ccwait_delta)      /1000000) ccwait_time_s
					     , round(SUM(hss.plsexec_time_delta)/1000000) plsexec_time_s
					     , round(SUM(hss.javexec_time_delta)/1000000) javexec_time_s
					     , SUM(hss.executions_delta) execs
					     , SUM(hss.rows_processed_delta) rows_processed
					     , SUM(hss.buffer_gets_delta) buffer_gets
					     , SUM(hss.disk_reads_delta) disk_reads
					     , SUM(hss.direct_writes_delta) direct_writes
					     , SUM(hss.FETCHES_DELTA) fetches
					     , SUM(hss.PX_SERVERS_EXECS_DELTA) PX
					     , SUM(hss.PHYSICAL_READ_REQUESTS_DELTA) physical_reads
					     , SUM(hss.PHYSICAL_WRITE_REQUESTS_DELTA) physical_writes
					     , SUM(hss.PHYSICAL_READ_BYTES_DELTA  /1024/1024) physical_reads_Mbytes
					     , SUM(hss.PHYSICAL_WRITE_BYTES_DELTA /1024/1024) physical_writes_Mbytes
					     , SUM(hss.IO_OFFLOAD_ELIG_BYTES_DELTA/1024/1024) IO_OFFLOAD_ELIG_MBYTES
					     , SUM(hss.IO_INTERCONNECT_BYTES_DELTA/1024/1024) IO_INTERCONNECT_MBYTES
					     , SUM(hss.OPTIMIZED_PHYSICAL_READS_DELTA) OPTIMIZED_PHYSICAL_READS
					     , SUM(hss.CELL_UNCOMPRESSED_BYTES_DELTA/1024/1024) CELL_UNCOMPRESSED_MBYTES
					     , SUM(hss.IO_OFFLOAD_RETURN_BYTES_DELTA/1024/1024) IO_OFFLOAD_RETURN_Mbytes
					FROM
					       dba_hist_sqlstat hss
					     , dba_hist_snapshot hs
					     , sqlid_tab_map
					WHERE
					       --hss.sql_id IN ('132uhuxjn8wth','1zfp819wwmumd','3h032r227yuvu','3qhp336a9vvav','3y7tv32gdwf99','42j2xtcmh440x','434yyzb6q8q0u','4ccf90hr4mbbd','4s8qbnyku75gx','4zdudd9r44g39','689g469htpkzj','6wjx3vyq0a8ab','742n9zw1n9c0m','7cpr4g94k308b','7rjvk68bv2qfv','8fu3j96jxgcsc','8wrdzqgunvzax','96v3w9nh125rc','99qzyzt7abf2h','ab861p9hmjvdc','atkusxx09cpgs','ax3kquhvhz9sh','b9t7962c495a3','bd4wagu0k56xr','bjj4bnjn3stmc','bm1p0v6znrxbx','bm6js3j8w0jrz','c95vzp19gcd8n','cfy2n3fvc3kbm','ck4bj245431nc','cu7y2sjpkqk57','d4nn1huadncc7', 'd926yur4zx4pp','dwh73fhgx96b6','f3g1kzzu78r7h','fjf8fpw7j7bn8','fv8tqw9zpmgrt','fyzt834k7hzaq','g9p9jmw4pfzqd','gfruk3qatamjs','gn99wrrbymccx','gv0aghtcunakj')
					       --hss.sql_id in (&sqlid)
					       msql_id = hss.sql_id
					   AND to_char(hs.end_interval_time,'MM/DD/YY')= '&ndate'
					   AND hss.snap_id        =hs.snap_id
					   AND hss.instance_number=hs.instance_number
					GROUP BY
					       hss.sql_id
					     , tab_n
				) 
SELECT
      ash.sql_id
     ,awr.tab_n
     ,ash.sql_plan_hash_value
     ,ash.sql_exec_id
     ,(ash.end_time-ash.start_time)* (3600*24) 		ashelapsec
     ,ash.parallel_dop
     ,awr.execs																	  awrexecs
     ,awr.elapsed_time_s													awrelapsec
     ,awr.cpu_time_s															cpu_s
     ,awr.iowait_time_s														iowait_s
     ,awr.clwait_time_s														clwait_s
     ,awr.apwait_time_s														apwait_s
     ,awr.ccwait_time_s														ccwait_s
     ,awr.rows_processed													rows_n
     ,awr.buffer_gets															buffer_gets
     ,awr.disk_reads															disk_reads
     ,awr.direct_writes														direct_writes
     ,to_char(ash.start_time,'MM/DD/YY HH24:MI') 	start_Time
     ,to_char(ash.end_time,'MM/DD/YY HH24:MI') 		end_time
FROM
ash, awr       
WHERE ash.sql_id = awr.sql_id
ORDER BY
       start_time;
       
