----------------------------------------------------------------------------------------
--
-- File name:   sql_performance_changed.sql
--
-- Purpose:     Lists SQL Statements with Elapsed Time per Execution changing over time
--
-- Author:      Carlos Sierra
--
-- Version:     2014/10/31
--
-- Usage:       Lists statements that have changed their elapsed time per execution over
--              some history.
--              Uses the ration between "elapsed time per execution" and the median of 
--              this metric for SQL statements within the sampled history, and using
--              linear regression identifies those that have changed the most. In other
--              words WHERE the slope of the linear regression is larger. Positive slopes
--              are considered "improving" while negative are "regressing".
--
-- Example:     @sql_performance_changed.sql
--
-- Notes:       Developed and tested on 11.2.0.3.
--
--              Requires an Oracle Diagnostics Pack License since AWR data is accessed.
--
--              To further investigate poorly performing SQL use sqltxplain.sql or sqlhc 
--              (or planx.sql or sqlmon.sql or sqlash.sql).
--
--				If database was shutdown between days_of_history_accessed output will be skewed.
--
-- Changes:		Modified column formatting for proper alignment of columns in windows sqlplus
--				Modified elapsed_time_total and executions_total to elapsed_time_delta and executions_delta
--				Modified DEF variable settings and commented out captured_at_least_x_days_apart
--				Added Total Elapsed as % of DB Time columns
---------------------------------------------------------------------------------------
--

DEF days_of_history_accessed = '5';
DEF captured_at_least_x_times = '1';
DEF captured_at_least_x_days_apart = '5';
DEF med_elap_microsecs_threshold = '1e4';
DEF min_slope_threshold = '0.1';
DEF max_num_rows = '20';
 
SET lin 300 ver OFF;
set linesize 500
COL row_n 			  format A2 	 HEA '#';
COL change			  format A13	 								  justify left;
COL slope 			  format 9999.99 HEA 'SLOPE'  					  justify right;
COL pctdbtim    	  format 99.99 	 HEA 'Total Elapsed|% DB Time'    justify right;
COL med_secs_per_exec format a15 	 HEA 'Median Secs|Per Exec'  	  justify right;
COL std_secs_per_exec format a15 	 HEA 'Std Dev Secs|Per Exec'   	  justify right;
COL avg_secs_per_exec format a15 	 HEA 'Avg Secs|Per Exec'  		  justify right;
COL min_secs_per_exec format a15 	 HEA 'Min Secs|Per Exec'  		  justify right;
COL max_secs_per_exec format a15 	 HEA 'Max Secs|Per Exec'  		  justify right;
COL plans 			  format 9999 									  justify right;
COL sql_text_80 	  format A80 									  justify left;
 
PRO SQL Statements with "Elapsed Time per Execution" changing over time
 
WITH
  per_time AS
  (
    SELECT
      h.dbid,
      h.sql_id,
      SYSDATE                   - CAST(s.end_interval_time AS DATE) days_ago,
      SUM(h.elapsed_time_delta) / SUM(decode(h.executions_delta,0,0.00000001,h.executions_delta))  time_per_exec,
      --SUM(h.elapsed_time_delta)  time_per_exec,
      SUM(decode(h.executions_delta,0,0.00000001,h.executions_delta)) execs
    FROM
      dba_hist_sqlstat h,
      dba_hist_snapshot s
    WHERE s.snap_id                  = h.snap_id
    AND s.dbid                     = h.dbid
    AND s.instance_number          = h.instance_number
    AND h.parsing_schema_name NOT IN ('SYS','SYSTEM','SYSTEM2','DBSNMP')
 	AND h.executions_delta           > 0
    AND CAST(s.end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed.
    GROUP BY
      h.dbid,
      h.sql_id,
      SYSDATE - CAST(s.end_interval_time AS DATE)
	HAVING
	  SUM(decode(h.executions_delta,0,0.00000001,h.executions_delta)) >= 1
  )
  ,
  db_time AS
  (
    SELECT
      tdbtim
    FROM
      (
      (
        SELECT
          e.stat_name ,
          (e.value - NVL(b.value,0)) value
        FROM
          dba_hist_sys_time_model b ,
          dba_hist_sys_time_model e
        WHERE
          e.dbid              = b.dbid
        AND e.instance_number = b.instance_number
        AND e.snap_id         =
          (
            SELECT
              MAX(snap_id)
            FROM
              dba_hist_snapshot
            WHERE
              CAST(end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed.
          )
        AND b.snap_id =
          (
            SELECT
              MIN(snap_id)
            FROM
              dba_hist_snapshot
            WHERE
              CAST(end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed.
          )
        AND b.stat_id    = e.stat_id
        AND e.stat_name IN ('DB time','DB CPU',
          'background elapsed time','background cpu time')
      )
      pivot (SUM(value) FOR stat_name IN ('DB time' tdbtim)) )
  )
  ,
  sql_dbt AS
  (
    SELECT
      h.sql_id,
      ROUND(h.time_per_exec*100/d.tdbtim,2) pctdbtim
    FROM
      (
        SELECT
          sql_id,
          SUM(time_per_exec*execs) time_per_exec
        FROM
          per_time
        GROUP BY
          sql_id
      )
      h,
      db_time d
  )
  ,
  avg_time AS
  (
    SELECT
      dbid,
      sql_id,
      MEDIAN(time_per_exec) med_time_per_exec,
      STDDEV(time_per_exec) std_time_per_exec,
      AVG(time_per_exec) avg_time_per_exec,
      MIN(time_per_exec) min_time_per_exec,
      MAX(time_per_exec) max_time_per_exec
    FROM
      per_time
    GROUP BY
      dbid,
      sql_id
    HAVING
      COUNT(*) >= &&captured_at_least_x_times.
      --AND MAX(days_ago) - MIN(days_ago) >=
      -- &&captured_at_least_x_days_apart.
    AND MEDIAN(time_per_exec) >   &&med_elap_microsecs_threshold.
  )
  ,
  time_over_median AS
  (
    SELECT
      h.dbid,
      h.sql_id,
      h.days_ago,
      (h.time_per_exec / a.med_time_per_exec) time_per_exec_over_med,
      a.med_time_per_exec,
      a.std_time_per_exec,
      a.avg_time_per_exec,
      a.min_time_per_exec,
      a.max_time_per_exec
    FROM
      per_time h,
      avg_time a
    WHERE
      a.sql_id = h.sql_id
  )
  ,
  ranked AS
  (
    SELECT
      RANK () OVER (ORDER BY ABS(REGR_SLOPE(t.time_per_exec_over_med,t.days_ago)) DESC) rank_num,
      t.dbid,
      t.sql_id,
      CASE
        WHEN REGR_SLOPE(t.time_per_exec_over_med, t.days_ago) > 0
        THEN 'IMPROVING'
        ELSE 'REGRESSING'
      END change,
      ROUND(REGR_SLOPE(t.time_per_exec_over_med, t.days_ago), 3)
      slope,
      ROUND(AVG(t.med_time_per_exec)/1e6, 3) med_secs_per_exec,
      ROUND(AVG(t.std_time_per_exec)/1e6, 3) std_secs_per_exec,
      ROUND(AVG(t.avg_time_per_exec)/1e6, 3) avg_secs_per_exec,
      ROUND(MIN(t.min_time_per_exec)/1e6, 3) min_secs_per_exec,
      ROUND(MAX(t.max_time_per_exec)/1e6, 3) max_secs_per_exec
    FROM
      time_over_median t
    GROUP BY
      t.dbid,
      t.sql_id
    HAVING
      ABS(REGR_SLOPE(t.time_per_exec_over_med, t.days_ago)) > &&min_slope_threshold.
  )
SELECT
  row_n,
  r.sql_id,
  change,
  slope,
  s.pctdbtim,
  lpad(med_secs_per_exec,15,' ') med_secs_per_exec,
  lpad(std_secs_per_exec,15,' ') std_secs_per_exec,
  lpad(avg_secs_per_exec,15,' ') avg_secs_per_exec,
  lpad(min_secs_per_exec,15,' ') min_secs_per_exec,
  lpad(max_secs_per_exec,15,' ') max_secs_per_exec,
  plans,
  sql_text_80
FROM
  (
    SELECT
      LPAD(ROWNUM, 2) row_n,
      r.sql_id,
      r.change,
      --TO_CHAR(r.slope, '990.000MI') slope,
      ROUND(r.slope,2) slope,
      --TO_CHAR(s.pctdbtim,'99.9999') ela_pct_dbtime,
      TO_CHAR(r.med_secs_per_exec, '999,990.000') med_secs_per_exec,
      TO_CHAR(r.std_secs_per_exec, '999,990.000') std_secs_per_exec,
      TO_CHAR(r.avg_secs_per_exec, '999,990.000') avg_secs_per_exec,
      TO_CHAR(r.min_secs_per_exec, '999,990.000') min_secs_per_exec,
      TO_CHAR(r.max_secs_per_exec, '999,990.000') max_secs_per_exec,
      (
        SELECT
          COUNT(DISTINCT p.plan_hash_value)
        FROM
          dba_hist_sql_plan p
        WHERE
          p.dbid     = r.dbid
        AND p.sql_id = r.sql_id
      )
      plans,
      REPLACE(
      (
        SELECT
          sys.DBMS_LOB.SUBSTR(s.sql_text, 80)
        FROM
          dba_hist_sqltext s
        WHERE
          s.dbid     = r.dbid
        AND s.sql_id = r.sql_id
      )
      , CHR(10)) sql_text_80
    FROM
      ranked r
    WHERE
      r.rank_num <= &&max_num_rows.
    ORDER BY
      r.rank_num
  )
  r,
  sql_dbt s
WHERE
  r.sql_id = s.sql_id
ORDER BY
  row_n
/


-- By force_matching_signature
COL force_matching_signature format 999999999999999999999999 HEA 'FORCE_MATCHING'  justify right;

WITH
  per_time AS
  (
    SELECT
      h.dbid,
      --h.sql_id,
      h.force_matching_signature,
      SYSDATE                   - CAST(s.end_interval_time AS DATE) days_ago,
      SUM(h.elapsed_time_delta) / SUM(decode(h.executions_delta,0,0.00000001,h.executions_delta))  time_per_exec,
      --SUM(h.elapsed_time_delta)  time_per_exec,
      SUM(decode(h.executions_delta,0,0.00000001,h.executions_delta)) execs
    FROM
      dba_hist_sqlstat h,
      dba_hist_snapshot s
    WHERE
      h.executions_delta           > 0
    AND s.snap_id                  = h.snap_id
    AND s.dbid                     = h.dbid
    AND s.instance_number          = h.instance_number
    AND h.parsing_schema_name NOT IN ('SYS','SYSTEM','SYSTEM2', 'DBSNMP')
    AND CAST(s.end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed.
    GROUP BY
      h.dbid,
      --h.sql_id,
      h.force_matching_signature,
      SYSDATE - CAST(s.end_interval_time AS DATE)
	HAVING
	  SUM(decode(h.executions_delta,0,0.00000001,h.executions_delta)) >= 1
  )
  ,
  db_time AS
  (
    SELECT
      tdbtim,
      tdbcpu,
      tbgtim,
      tbgcpu
    FROM
      (
      (
        SELECT
          e.stat_name ,
          (e.value - NVL(b.value,0)) value
        FROM
          dba_hist_sys_time_model b ,
          dba_hist_sys_time_model e
        WHERE
          e.dbid              = b.dbid
        AND e.instance_number = b.instance_number
        AND e.snap_id         =
          (
            SELECT
              MAX(snap_id)
            FROM
              dba_hist_snapshot
            WHERE
              CAST(end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed.
          )
        AND b.snap_id =
          (
            SELECT
              MIN(snap_id)
            FROM
              dba_hist_snapshot
            WHERE
              CAST(end_interval_time AS DATE) > SYSDATE - &&days_of_history_accessed.
          )
        AND b.stat_id    = e.stat_id
        AND e.stat_name IN ('DB time','DB CPU' ,'background elapsed time','background cpu time')
      )
      pivot (SUM(value) FOR stat_name IN ('DB time' tdbtim ,'DB CPU' tdbcpu ,'background elapsed time' tbgtim ,'background cpu time'  tbgcpu)))
  )
  ,
  sql_dbt AS
  (
    SELECT
      --h.sql_id,
      h.force_matching_signature,
      ROUND(h.time_per_exec*100/d.tdbtim,2) pctdbtim
    FROM
      (
        SELECT
          --sql_id,
          force_matching_signature,
          SUM(time_per_exec*execs) time_per_exec
        FROM
          per_time
        GROUP BY
          --sql_id
          force_matching_signature
      )
      h,
      db_time d
  )
  ,
  avg_time AS
  (
    SELECT
      dbid,
      --sql_id,
      force_matching_signature,
      MEDIAN(time_per_exec) med_time_per_exec,
      STDDEV(time_per_exec) std_time_per_exec,
      AVG(time_per_exec) avg_time_per_exec,
      MIN(time_per_exec) min_time_per_exec,
      MAX(time_per_exec) max_time_per_exec
    FROM
      per_time
    GROUP BY
      dbid,
      --sql_id
      force_matching_signature
    HAVING
      COUNT(*) >= &&captured_at_least_x_times.
      --AND MAX(days_ago) - MIN(days_ago) >=
      -- &&captured_at_least_x_days_apart.
    AND MEDIAN(time_per_exec) >  &&med_elap_microsecs_threshold.
  )
  ,
  time_over_median AS
  (
    SELECT
      h.dbid,
      --h.sql_id,
      h.force_matching_signature,
      h.days_ago,
      (h.time_per_exec / a.med_time_per_exec) time_per_exec_over_med,
      a.med_time_per_exec,
      a.std_time_per_exec,
      a.avg_time_per_exec,
      a.min_time_per_exec,
      a.max_time_per_exec
    FROM
      per_time h,
      avg_time a
      --WHERE a.sql_id = h.sql_id
    WHERE
      a.force_matching_signature = h.force_matching_signature
  )
  ,
  ranked AS
  (
    SELECT
      RANK () OVER (ORDER BY ABS(REGR_SLOPE(t.time_per_exec_over_med,
      t.days_ago)) DESC) rank_num,
      t.dbid,
      --t.sql_id,
      t.force_matching_signature,
      CASE
        WHEN REGR_SLOPE(t.time_per_exec_over_med, t.days_ago) > 0
        THEN 'IMPROVING'
        ELSE 'REGRESSING'
      END change,
      ROUND(REGR_SLOPE(t.time_per_exec_over_med, t.days_ago), 3)
      slope,
      ROUND(AVG(t.med_time_per_exec)/1e6, 3) med_secs_per_exec,
      ROUND(AVG(t.std_time_per_exec)/1e6, 3) std_secs_per_exec,
      ROUND(AVG(t.avg_time_per_exec)/1e6, 3) avg_secs_per_exec,
      ROUND(MIN(t.min_time_per_exec)/1e6, 3) min_secs_per_exec,
      ROUND(MAX(t.max_time_per_exec)/1e6, 3) max_secs_per_exec
    FROM
      time_over_median t
    GROUP BY
      t.dbid,
      --t.sql_id
      t.force_matching_signature
    HAVING
      ABS(REGR_SLOPE(t.time_per_exec_over_med, t.days_ago)) >  &&min_slope_threshold.
  )
SELECT
  row_n,
  --r.sql_id,
  r.force_matching_signature,
  change,
  slope,
  s.pctdbtim,
  lpad(med_secs_per_exec,15,' ') med_secs_per_exec,
  lpad(std_secs_per_exec,15,' ') std_secs_per_exec,
  lpad(avg_secs_per_exec,15,' ') avg_secs_per_exec,
  lpad(min_secs_per_exec,15,' ') min_secs_per_exec,
  lpad(max_secs_per_exec,15,' ') max_secs_per_exec
  -- plans,
  --sql_text_80
FROM
  (
    SELECT
      LPAD(ROWNUM, 2) row_n,
      --r.sql_id,
      r.force_matching_signature,
      r.change,
      --TO_CHAR(r.slope, '990.000MI') slope,
      ROUND(r.slope,2) slope,
      --TO_CHAR(s.pctdbtim,'99.9999') ela_pct_dbtime,
      TO_CHAR(r.med_secs_per_exec, '999,990.000') med_secs_per_exec,
      TO_CHAR(r.std_secs_per_exec, '999,990.000') std_secs_per_exec,
      TO_CHAR(r.avg_secs_per_exec, '999,990.000') avg_secs_per_exec,
      TO_CHAR(r.min_secs_per_exec, '999,990.000') min_secs_per_exec,
      TO_CHAR(r.max_secs_per_exec, '999,990.000') max_secs_per_exec
      --(SELECT COUNT(DISTINCT p.plan_hash_value) FROM
      -- dba_hist_sql_plan p WHERE p.dbid = r.dbid AND p.sql_id =
      -- r.sql_id) plans,
      --REPLACE((SELECT sys.DBMS_LOB.SUBSTR(s.sql_text, 80) FROM
      -- dba_hist_sqltext s WHERE s.dbid = r.dbid AND s.sql_id =
      -- r.sql_id), CHR(10)) sql_text_80
    FROM
      ranked r
    WHERE
      r.rank_num <= &&max_num_rows.
    ORDER BY
      r.rank_num
  )
  r,
  sql_dbt s
WHERE
  r.force_matching_signature = s.force_matching_signature
ORDER BY
  row_n
/
 

 
