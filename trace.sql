select 
    'exec dbms_monitor.session_trace_enable('||sid||','||serial#||',waits=>true,binds=>true);' command_to_run
from
    v$session
where sid= &1
/
