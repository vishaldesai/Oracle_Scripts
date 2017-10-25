select
    'exec dbms_monitor.session_trace_disable('||sid||','||serial#||');' command_to_run
from
    v$session
where sid= &1
/

