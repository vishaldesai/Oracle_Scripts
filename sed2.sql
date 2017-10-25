prompt Show wait event descriptions matching &1...

col sed_name head EVENT_NAME for a55
col sed_p1 head PARAMETER1 for a20
col sed_p2 head PARAMETER2 for a20
col sed_p3 head PARAMETER3 for a20
col sed_event# head EVENT# for 99999
set linesize 200
set pages 9999

select 
	event# sed_event#, 
	name sed_name, 
  wait_class,
	parameter1 sed_p1, 
	parameter2 sed_p2, 
	parameter3 sed_p3 
from 
	v$event_name 
where 
	lower(name) like lower('&1') 
order by 
	sed_name
/
