column index_name format a30
column columns format a50
column index_type format a10 heading type
column owner format a10
column tablespace_name format a15
set linesize 300
set pages 9999

select b.uniqueness,b.index_type,b.partitioned,c.locality,b.blevel,b.leaf_blocks,b.clustering_factor,b.num_rows,b.last_analyzed,b.visibility,a.*
from
(select index_name,index_owner,
	max(decode(column_position,1,column_name,null))||
	max(decode(column_position,2,', '||column_name,null))||
	max(decode(column_position,3,', '||column_name,null))||
	max(decode(column_position,4,', '||column_name,null))||
	max(decode(column_position,5,', '||column_name,null)) columns from dba_ind_columns 
	where  table_name = upper('&table_name') 
      and    index_owner = upper('&owner')
group by index_name,index_owner) a,
dba_indexes b,
(select distinct owner,index_name,locality from dba_part_indexes) c
where a.index_name = b.index_name and
a.index_owner=b.owner and
b.index_name = c.index_name(+) and
b.owner=c.owner(+)
/
