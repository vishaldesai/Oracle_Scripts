--------------------------------------------------------------------------------
--
-- File name:   dashtop.sql
-- Purpose:     Display top ASH time (count of ASH samples) grouped by your
--              specified dimensions
--              
-- Author:      Tanel Poder
-- Copyright:   (c) http://blog.tanelpoder.com
--              
-- Usage:       
--     @dashtop <grouping_cols> <filters> <fromsnap> <tosnap>
--
-- Example:
--     @dashtop username,sql_id session_type='FOREGROUND' sysdate-1/24 sysdate
--
-- Other:
--     This script uses only the AWR's DBA_HIST_ACTIVE_SESS_HISTORY, use
--     @dashtop.sql for accessiong the V$ ASH view
--              
--------------------------------------------------------------------------------
set linesize 500
set pages 9999
COL "%This" FOR A6
COL "UserI/O"   FOR 999999
COL "SystemI/O" FOR 999999


SELECT * FROM (
    SELECT /*+ LEADING(a) USE_HASH(u) */
        LPAD(ROUND(RATIO_TO_REPORT(COUNT(*)) OVER () * 100)||'%',5,' ') "%This"
      , &1
      , 10 * COUNT(*)                                                      "TotalSeconds"
      , 10 * SUM(CASE WHEN wait_class IS NULL           THEN 1 ELSE 0 END) "CPU"
      , 10 * SUM(CASE WHEN wait_class ='User I/O'       THEN 1 ELSE 0 END) "UserI/O"
      , 10 * SUM(CASE WHEN wait_class ='Application'    THEN 1 ELSE 0 END) "Application"
      , 10 * SUM(CASE WHEN wait_class ='Concurrency'    THEN 1 ELSE 0 END) "Concurrency"
      , 10 * SUM(CASE WHEN wait_class ='Commit'         THEN 1 ELSE 0 END) "Commit"
      , 10 * SUM(CASE WHEN wait_class ='Configuration'  THEN 1 ELSE 0 END) "Configuration"
      , 10 * SUM(CASE WHEN wait_class ='Cluster'        THEN 1 ELSE 0 END) "Cluster"
      , 10 * SUM(CASE WHEN wait_class ='Idle'           THEN 1 ELSE 0 END) "Idle"
      , 10 * SUM(CASE WHEN wait_class ='Network'        THEN 1 ELSE 0 END) "Network"
      , 10 * SUM(CASE WHEN wait_class ='System I/O'     THEN 1 ELSE 0 END) "SystemI/O"
      , 10 * SUM(CASE WHEN wait_class ='Scheduler'      THEN 1 ELSE 0 END) "Scheduler"
      , 10 * SUM(CASE WHEN wait_class ='Administrative' THEN 1 ELSE 0 END) "Administrative"
      , 10 * SUM(CASE WHEN wait_class ='Queueing'       THEN 1 ELSE 0 END) "Queueing"
      , 10 * SUM(CASE WHEN wait_class ='Other'          THEN 1 ELSE 0 END) "Other"
      , MIN(sample_time)
      , MAX(sample_time)
    FROM
        dba_hist_active_sess_history a
      , dba_users u
    WHERE
        a.user_id = u.user_id (+)
    AND &2
    AND snap_id BETWEEN &3 AND &4
    AND snap_id IN (SELECT snap_id FROM dba_hist_snapshot WHERE snap_id BETWEEN &3 AND &4) -- for partition pruning
    GROUP BY
        &1
    ORDER BY
        "TotalSeconds" DESC
       , &1
)
WHERE
    ROWNUM <= 20
/

