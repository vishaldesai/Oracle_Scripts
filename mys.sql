prompt Show current session statistics from V$SESSTAT....
set linesize 200

select 
	n.statistic# stat#,
	n.statistic# * 8 offset,
	n.name, 
	s.value
from v$mystat s, v$statname n
where s.statistic#=n.statistic#
and lower(n.name) like lower('%&1%')
/



