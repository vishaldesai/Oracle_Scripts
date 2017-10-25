-- ********************************************************************
-- * Copyright Notice   : (c)2001-2010 OraPub, Inc.
-- * Filename           : event_type.sql - For 10g+ databases!!!!!
-- * Author             : Craig A. Shallahamer
-- * Original           : 11-may-01
-- * Last Update        : 15-Jan-2010
-- * Description        : event_type.sql - Loads "event type" table
-- *                      which is used by other scripts.
-- * Usage              : start event_type.sql
-- *                      This is usually run (manually) after osmprep.sql
-- ********************************************************************

prompt
prompt file: event_type.sql for Oracle 10g and beyond...
prompt
prompt About to categorize wait events for OSM reports.
prompt
prompt Press ENTER to re-create the o$event_type table.
accept x

-- Event TYPES are defined as follows:

-- ior   	- IO read related wait
-- iow   	- IO write related wait
-- other 	- "real" but not explicitly categorized
-- idle/bogus	- idle events, usually not useful

drop table o$event_type
/
create table o$event_type (
event		varchar2(64),
type		varchar2(64)
)
/

insert into o$event_type
	select name,'other'
	from	v$event_name
	where	wait_class in ('Administrative','Application','Cluster','Concurrency',
			       'Configuration','Other','Scheduler','Queuing','Scheduler')
/
insert into o$event_type
	select	name,'bogus'
	from	v$event_name
	where	wait_class in ('Idle','Network')
/
insert into o$event_type
	select	name,'ior'
	from	v$event_name
	where	wait_class in ('Commit','System I/O','User I/O')
	  and	name like '%read%'
/
insert into o$event_type
	select	name,'iow'
	from	v$event_name
	where	wait_class in ('Commit','System I/O','User I/O')
	  and	name like '%write%'
/
insert into o$event_type
select name, 'other' from v$event_name
minus
select event, 'other' from o$event_type
/

-----------------------------------------------------------------------------------------
----- DO NOT REMOVE THE BELOW LINES as they make adjustments to the broad inserts above.
-----------------------------------------------------------------------------------------

update o$event_type set type='iow' where event = 'free buffer waits';
update o$event_type set type='other' where event like 'latch%';
update o$event_type set type='other' where event like 'enq%';
update o$event_type set type='other' where event like 'cursor%';
update o$event_type set type='iow' where event like 'log%sync%';
update o$event_type set type='iow' where event like 'log%write%';
update o$event_type set type='iow' where event like 'db%write%';
update o$event_type set type='iow' where event like 'log%file%switch%';
update o$event_type set type='iow' where event like 'LGWR%';
update o$event_type set type='ior' where event like 'log%read%';
update o$event_type set type='ior' where event like 'db%read%';
update o$event_type set type='iow' where event like 'i/o%slave%wait';
update o$event_type set type='iow' where event = 'write complete waits';
update o$event_type set type='other' where event = 'wait for unread message on broadcast channel';
update o$event_type set type='other' where event = 'wait for unread message on multiple broadcast channels';
update o$event_type set type='iow' where event like 'db%file%async%submit%';

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------


commit;

col name format a50 trunc
col wait_class format a20
col type format a20

prompt
prompt OraPub Categorization Summary
prompt ------------------------------------------------

select distinct type,
count(*)
from o$event_type
group by type
order by type
/
select count(*) from o$event_type
/

prompt
prompt Oracle Categorization Summary
prompt ------------------------------------------------

select distinct wait_class, count(*) from v$event_name group by wait_class order by wait_class
/
select count(*) from v$event_name
/

