set verify off
set linesize 200
column sizeMB format 9,999,999.99
column segment_name format a45

select owner,segment_type,segment_name,sum(bytes)/1024/1024 SizeMB from dba_Segments where 
owner like nvl('&owner','%') 
and segment_name like upper('%&segment_name%')
group by owner,segment_name,segment_type
order by 1,2;