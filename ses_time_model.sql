WITH
    db_time AS (SELECT sid, value
                FROM v$sess_time_model
                WHERE sid= &sid
                AND stat_name = 'DB time')
  SELECT ses.stat_name AS statistic,
         round(ses.value / 1E6, 3) AS seconds,
         round(ses.value / nullif(tot.value, 0) * 1E2, 1) AS "%"
  FROM v$sess_time_model ses, db_time tot
  WHERE ses.sid= tot.sid
  AND ses.stat_name <> 'DB time'
  AND ses.value > 0
 ORDER BY ses.value DESC;