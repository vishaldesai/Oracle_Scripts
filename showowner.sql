--
-- given an object name
-- show what schema owns it and what it is
--

col object_name format a30

select owner,object_type,object_name,status
from dba_objects
where object_name like upper('%&&1%')
order by 1,2,3
/
