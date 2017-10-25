col o_owner heading owner for a25
col o_object_name heading object_name for a30
col o_object_type heading object_type for a18
col o_status heading status for a9

prompt Display number of buffered blocks of a segment using X$KCBOQH for table &1

select 
    SUM(x.num_buf) num_buf,
    ROUND(SUM(x.num_buf * ts.blocksize) / 1024 / 1024 , 2)  mb_buf,
    o.owner o_owner,
    o.object_name o_object_name, 
    o.subobject_name,
    ts.name tablespace_name,
    o.object_type o_object_type,
    o.status o_status,
    o.object_id oid,
    o.data_object_id d_oid,
    o.created, 
    o.last_ddl_time
from 
    dba_objects o
  , x$kcboqh x
  , sys_objects so
  , ts$ ts
where 
    x.obj# = o.data_object_id
and o.data_object_id = so.object_id
and so.ts_number = ts.ts#
and
	upper(object_name) LIKE 
				upper(CASE 
					WHEN INSTR('&1','.') > 0 THEN 
					    SUBSTR('&1',INSTR('&1','.')+1)
					ELSE
					    '&1'
					END
				     )
AND	owner LIKE
		CASE WHEN INSTR('&1','.') > 0 THEN
			UPPER(SUBSTR('&1',1,INSTR('&1','.')-1))
		ELSE
			user
		END
group by
    o.owner 
  , o.object_name 
  , o.subobject_name
  , ts.name
  , o.object_type
  , o.status
  , o.object_id 
  , data_object_id
  , o.created 
  , o.last_ddl_time
order by 
    num_buf desc
--    o_object_name,
--    o_owner,
--    o_object_type
/
