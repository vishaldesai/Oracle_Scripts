set lines 100 pages 200
/*
define event="gc current block busy"
define obj_cnt=10
*/
col object_name format A32
col object_type format A20
col owner format A20
col cnt format 999999999 

with ash_gc as 
(select * from (
select /*+ materialize */ inst_id, event, current_obj#, count(*) cnt 
from gv$active_session_history where event=lower('&event')
group by inst_id,event, current_obj# having count(*) > &obj_cnt 
))
select * from (
select inst_id,owner, object_name,object_type, cnt 
from ash_gc a, dba_objects o
where (a.current_obj#=o.data_object_id or a.current_obj#=o.object_id)
and a.current_obj#>=1
union 
select inst_id, '','','Undo Header/Undo block' , cnt 
from ash_gc a
where a.current_obj#=0
union
select inst_id, '','','Undo Block' , cnt 
from ash_gc a
where a.current_obj#=-1
) order by 5
/