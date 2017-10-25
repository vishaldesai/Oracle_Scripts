define d_owner = 'DEALLOGO'  
define d_table_name = 'SERVICE_TRANSACTION_LOG'
define d_num_buckets = 300
 
with extents_data as (
  select o.data_object_id, e.file_id, e.block_id, e.blocks
  from dba_extents e
  join all_objects o
  on (e.owner, e.segment_name, e.segment_type) = ((o.owner, o.object_name, o.object_type))
    and decode(e.partition_name, o.subobject_name, 0, 1) = 0
  where e.segment_type in ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
    and e.owner = '&d_owner'
    and e.segment_name = '&d_table_name'
)
, extents_with_sums as (   
  select sum(blocks) over() total_blocks,
    sum(blocks) over(order by data_object_id, file_id, block_id) - blocks cumul_prev_blocks,   
    sum(blocks) over(order by data_object_id, file_id, block_id) cumul_current_blocks,
    e.*
  from extents_data e 
)
, extents_with_buckets as (   
  select width_bucket(cumul_prev_blocks, 1, total_blocks + 1, &d_num_buckets) prev_bucket,
    width_bucket(cumul_prev_blocks+1, 1, total_blocks + 1, &d_num_buckets) first_bucket,
    width_bucket(cumul_current_blocks, 1, total_blocks + 1, &d_num_buckets) last_bucket,
    e.*
  from extents_with_sums e   
)
, selected_extents as (
  select *
  from extents_with_buckets
  where cumul_current_blocks = round((last_bucket * total_blocks) / &d_num_buckets)
    or prev_bucket < last_bucket
)
, expanded_extents as (   
  select first_bucket + level - 1 bucket,
    case level when 1 then cumul_prev_blocks
      else round(((first_bucket + level - 2) * total_blocks) / &d_num_buckets) 
    end start_blocks,   
    case first_bucket + level - 1 when last_bucket then cumul_current_blocks - 1
      else round(((first_bucket + level - 1) * total_blocks) / &d_num_buckets) - 1
    end end_blocks,
    e.*
  from selected_extents e
  connect by cumul_prev_blocks = prior cumul_prev_blocks   
    and first_bucket + level -1 <= last_bucket   
    and prior sys_guid() is not null
)
, answer as ( 
  select bucket,
    min(data_object_id)
      keep (dense_rank first order by cumul_prev_blocks) first_data_object_id,
    min(file_id)
      keep (dense_rank first order by cumul_prev_blocks) first_file_id,  
    min(block_id + start_blocks - cumul_prev_blocks)   
      keep (dense_rank first order by cumul_prev_blocks) first_block_id,
    max(data_object_id)
      keep (dense_rank last order by cumul_prev_blocks) last_data_object_id,
    max(file_id)
      keep (dense_rank last order by cumul_prev_blocks) last_file_id,  
    max(block_id + end_blocks - cumul_prev_blocks)   
      keep (dense_rank last order by cumul_prev_blocks) last_block_id,  
    max(end_blocks) + 1 - min(start_blocks) blocks   
  from expanded_extents   
  group by bucket 
)
, rowids as (
  select
  dbms_rowid.rowid_create(
    1, first_data_object_id, first_file_id, first_block_id, 0
  ) rowid_start,   
  dbms_rowid.rowid_create(
    1, last_data_object_id, last_file_id, last_block_id, 32767
  ) rowid_end   
  from answer
  order by bucket
)
select
'select count(*) cnt from &d_owner..&d_table_name union all select sum(cnt) from (' txt from dual
union all
select 'select count(*) cnt from &d_owner..&d_table_name where rowid between chartorowid('''
|| rowid_start || ''') and chartorowid(''' || rowid_end || ''')'
|| case when lead(rowid_start) over(order by rowid_start) is null then ');'
  else ' union all'
end test_sql
from rowids;