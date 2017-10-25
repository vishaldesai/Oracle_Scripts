column used_space format 99,999,999
column free_space format 99,999,999
column total_space format 99,999,999
column largest_extent format 99,999,999
column auto_grow format 99,999,999
column tablespace_name format a28
column pctfull format 999
column pctautogrow format 99,999,999
set pagesize 110
set pages 4000
set linesize 500

select t.tablespace_name,t.total_space,
	nvl(f.free_space,0) free_space, 
	t1.total_space-t.total_space Auto_grow,
	nvl(f.largest_extent,0) largest_extent,
	t.total_space-nvl(f.free_space,0) used_space,
	(t.total_space-nvl(f.free_space,0))*100/t.total_space pctfull,
	(t1.total_space-t.total_space)*100/t.total_space pctautogrow
  from
   (select tablespace_name, sum(bytes)/(1024*1024) total_space  
	from dba_data_files group by tablespace_name ) t,
	(select tablespace_name,sum(case when autoextensible = 'YES' then maxbytes/1024/1024
                                when autoextensible = 'NO'  then bytes/1024/1024 END) total_space
from dba_data_files group by tablespace_name) t1,
   (select tablespace_name, sum(bytes)/(1024*1024) free_space,
	max(bytes)/(1024*1024) largest_extent
	from dba_free_space group by tablespace_name)  f
	where t.tablespace_name=f.tablespace_name (+)
	and   t1.tablespace_name=t.tablespace_name
	order by 1
/

select sum(t.total_space) total_space ,
        sum(nvl(f.free_space,0)) free_space,
        sum(total_space-nvl(f.free_space,0)) used_space
  from
   (select tablespace_name, sum(bytes)/(1024*1024) total_space
        from dba_data_files group by tablespace_name ) t,
   (select tablespace_name, sum(bytes)/(1024*1024) free_space,
        max(bytes)/(1024*1024) largest_extent
        from dba_free_space group by tablespace_name)  f
        where t.tablespace_name=f.tablespace_name (+)
/

col used format 999,999,999,999
col free format 999,999,999,999
col maxused format 999,999,999,999
col totalsize format 999,999,999,999
break on report
compute sum of totalsize on report
compute sum of used on report
compute sum of free on report

SELECT inst_id,tablespace_name, (TOTAL_BLOCKS * (select value from v$parameter where name='db_block_size')) "totalsize", 
(USED_BLOCKS * (select value from v$parameter where name='db_block_size') ) "used" , (FREE_BLOCKS * (select value from v$parameter where name='db_block_size')) "free" , 
(MAX_USED_BLOCKS * (select value from v$parameter where name='db_block_size') ) "maxused"
FROM gv$sort_segment order by inst_id;
