col used format 999,999,999,999,999
col free format 999,999,999,999,999
col maxused format 999,999,999,999,999
col totalsize format 999,999,999,999,999
compute sum of totalsize on report
compute sum of used on report
compute sum of free on report
compute sum of maxused on report

SELECT inst_id,tablespace_name, (TOTAL_BLOCKS * (select value from v$parameter where name='db_block_size')) "totalsize", 
(USED_BLOCKS * (select value from v$parameter where name='db_block_size') ) "used" , (FREE_BLOCKS * (select value from v$parameter where name='db_block_size')) "free" , 
(MAX_USED_BLOCKS * (select value from v$parameter where name='db_block_size') ) "maxused"
FROM gv$sort_segment order by inst_id;

