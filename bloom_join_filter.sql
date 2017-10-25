set linesize 500
set pages 9999
accept qc_sid prompt 'Enter Query Co-ordinator sid:'

select filtered,probed,probed-filtered as sent
from v$sql_join_filter
where qc_session_id=&qc_sid;