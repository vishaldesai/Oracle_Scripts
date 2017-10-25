set lines 200
set pages 1000
select output
from GV$RMAN_OUTPUT
where session_recid = &SESSION_RECID
  and session_stamp = &SESSION_STAMP
order by recid;