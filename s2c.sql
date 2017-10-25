  SELECT instance_number,
         owner,
         object_name,
         dt,
         MIN (start_dt),
         MAX (end_dt),
         SUM (totmin)
    FROM (SELECT *
            FROM (SELECT instance_number,
                         sql_id,
                         owner,
                         object_name,
                         TRUNC (start_dt) dt,
                         start_dt,
                         end_dt,
                         exect,
                         ROUND (
                              (  EXTRACT (DAY FROM exect) * 24 * 60 * 60
                               + EXTRACT (HOUR FROM exect) * 60 * 60
                               + EXTRACT (MINUTE FROM exect) * 60
                               + EXTRACT (SECOND FROM exect))
                            / (60))
                            totmin
                    FROM (  SELECT DISTINCT
                                   instance_number,
                                   sql_id,
                                   owner,
                                   object_name,
                                   --SQL_EXEC_ID,
                                   MIN (sql_exec_start) start_dt,
                                   MAX (sample_time) end_dt,
                                   MAX (sample_time) - MIN (sql_exec_start) exect
                              FROM dba_hist_active_sess_history, dba_objects
                             WHERE     service_hash = 3454704727
                                   AND TO_CHAR (sample_time, 'HH24') IN ('20',
                                                                         '21')
                                   AND snap_id >= 52883
                                   AND object_id = CURRENT_OBJ#
                                   AND owner = 'SRC_CORE2_DEAL'
                                   AND object_type = 'TABLE'
                          GROUP BY instance_number,
                                   sql_id,
                                   owner,
                                   object_name
                          --SQL_EXEC_ID
                          ORDER BY 5))
           WHERE totmin > 10)
GROUP BY instance_number,
         owner,
         object_name,
         dt
ORDER BY dt;



 SELECT instance_number,
         owner,
         object_name,
         dt,
         MIN (start_dt),
         MAX (end_dt),
         SUM (totmin)
    FROM (SELECT *
            FROM (SELECT instance_number,
                         sql_id,
                         owner,
                         object_name,
                         TRUNC (start_dt) dt,
                         start_dt,
                         end_dt,
                         exect,
                         ROUND (
                              (  EXTRACT (DAY FROM exect) * 24 * 60 * 60
                               + EXTRACT (HOUR FROM exect) * 60 * 60
                               + EXTRACT (MINUTE FROM exect) * 60
                               + EXTRACT (SECOND FROM exect))
                            / (60))
                            totmin
                    FROM (  SELECT DISTINCT
                                   instance_number,
                                   sql_id,
                                   owner,
                                   object_name,
                                   --SQL_EXEC_ID,
                                   MIN (sql_exec_start) start_dt,
                                   MAX (sample_time) end_dt,
                                   MAX (sample_time) - MIN (sql_exec_start) exect
                              FROM dba_hist_active_sess_history, dba_objects
                             WHERE     service_hash = 3454704727
                                   AND TO_CHAR (sample_time, 'HH24') IN ('20',
                                                                         '21')
                                   AND snap_id >= 52883
                                   AND object_id = CURRENT_OBJ#
                                   AND owner = 'SRC_CORE2_DEAL'
                                   AND object_type = 'TABLE'
                          GROUP BY instance_number,
                                   sql_id,
                                   owner,
                                   object_name
                          --SQL_EXEC_ID
                          ORDER BY 5))
           WHERE totmin > 10)
GROUP BY instance_number,
         owner,
         object_name,
         dt
ORDER BY dt;

