set linesize 200
set pages 9999
select usn, state, undoblockstotal "Total", undoblocksdone "Done", 
undoblockstotal-undoblocksdone "ToDo", 
decode(cputime,0,'unknown',sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400)) 
"Estimated time to complete" 
from gv$fast_start_transactions
where undoblocksdone>0
/