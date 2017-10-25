
set long 9999999
undefine sql_id
select sql_text from dba_hist_sqltext where sql_id='&sql_id';
undefine sql_id