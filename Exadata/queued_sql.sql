break on sql_text on sql_id
col sql_text for a60 trunc
SELECT sid, sql_id, sql_exec_id, sql_text
from v$sql_monitor
WHERE status='QUEUED'
order by 3
/
clear break
