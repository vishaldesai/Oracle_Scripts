
select address,hash_value,loads,parse_calls,executions,buffer_gets,disk_reads, buffer_gets/decode(executions,0,1,executions) avg_read ,disk_reads/decode(executions,0,1,executions) avg_pread
,sql_text from v$sqlarea
where  hash_value=&hash
/
