select sql_id,plan_hash_value from gv$sql where sql_id='8g1bdwf9wnh8n';


select sql_handle,last_executed from dba_sql_plan_baselines;

select sql_id from gv$sql where sql_text like 'MERGE%LOAN_FEATURE%';