column owner format a20
column object_name format a35
column suboject_name format a30
column last_ddl_time format a20
select owner,object_name,subobject_name,last_ddl_time
from dba_objects 
where object_name like upper('%&&1%') or subobject_name like upper('%&&1%');

