set pagesize 100
set linesize 180
col object_name format A32
col object_type format A20
col owner format A20
col event format A48
col cnt format 999999999
col current_file# format 99999 head file
col current_block# format 9999999 head block 
/*
define event="gc current block busy"
define event="gc buffer busy acquire"
define block_cnt=5
*/
with  ash_gc as 
(select * from 
  (
  select /*+ materialize */ inst_id, event, current_obj#, current_file#, current_block#, Count(*) CNT
    from gv$active_session_history where event=lower('&event')
     group by inst_id,event, current_obj#, current_file#, current_block#
     having count(*) >  &block_cnt
   ) 
)
select * from (
select inst_id,owner, object_name,object_type, current_obj#, current_file#, current_block#, cnt 
  from ash_gc a, dba_objects o
  where (a.current_obj#=o.data_object_id(+)) and a.current_obj#>=1
union 
select inst_id, '','','Undo Header/Undo block' ,0,current_file#, current_block#, cnt 
  from ash_gc a
  where a.current_obj#=0
union
select inst_id, '','','Undo Block'   , -1, current_file#, current_block#, cnt 
  from ash_gc a
  where a.current_obj#=-1
) order by 7 desc
/
