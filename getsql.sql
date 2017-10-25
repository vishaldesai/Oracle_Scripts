break on hash_value
set pagesize 1000
set long 200000000
select sql_id,plan_hash_value, sql_fulltext
from v$sql
where sql_id in
	(select sql_id from
		v$session where sid = &sid)
/
