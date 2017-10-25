col sql_text for a80 word_wrap
select a.sql_id, child_number child_no, b.sql_text from v$sql_shared_cursor a, v$sqlstats b
where a.sql_id = b.sql_id
and USE_FEEDBACK_STATS = 'Y'
and a.sql_id like nvl('&sql_id',a.sql_id)
and upper(sql_text) like upper(nvl('&sql_text',sql_text))
and child_number > 0
order by 1, 2
/
