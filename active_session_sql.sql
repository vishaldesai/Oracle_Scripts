set linesize 500
set pages 500
column sql_text format a100

select
	ses.sid, ses.serial#, ses.username, ses.status,
--	ses.osuser, ses.machine, ses.module, 
	ses.EVENT, ses.logon_time, ses.curr_prev,
	sql.sql_id, sql.child_number, sql.sql_text
from	
	(
	select
		ses1.sid, ses1.serial#, ses1.username, ses1.status,
	--	ses1.osuser, ses1.machine, ses1.module, 
		'Current' curr_prev,
		ses1.event, ses1.logon_time,
		ses1.sql_id, ses1.sql_child_number, ses1.sql_address
	from
		v$session	ses1
	union all
	select
		ses2.sid, ses2.serial#, ses2.username, ses2.status,
	--	ses2.osuser, ses2.machine, ses2.module, 
		'Previous' curr_prev,
		ses2.event, ses2.logon_time,
		ses2.prev_sql_id, ses2.prev_child_number, ses2.prev_sql_addr
	from
		v$session	ses2
	)		ses,
	v$sql		sql
where
	ses.username	 = 'TEST_USER'
and	ses.sql_address != '00'
and	ses.status	 = 'ACTIVE'
and	sql.sql_id	 = ses.sql_id
and	sql.child_number = ses.sql_child_number
order by
	ses.sid, ses.curr_prev
;



set linesize 200
