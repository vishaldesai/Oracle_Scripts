set linesize 500
set pages 9999

accept sql_id      prompt 'Enter sql_id          :'
accept phv         prompt 'Enter plan_hash_value :'
accept fix         prompt 'Enter Fixed(YES/NO)   :'
accept enabled		 prompt 'Enter Enabled(YES/NO) :'
accept child_no    prompt 'Enter child number    :'

SET SERVEROUTPUT ON
DECLARE
  l_plans_loaded  PLS_INTEGER;
BEGIN
  l_plans_loaded := dbms_spm.load_plans_from_cursor_cache(sql_id=>'&sql_id', plan_hash_value=>&phv, fixed =>'&fix', enabled=>'&enabled');
    
  DBMS_OUTPUT.put_line('Plans Loaded: ' || l_plans_loaded);
END;
/

SELECT sql_handle, plan_name, enabled, accepted 
FROM   dba_sql_plan_baselines
WHERE  signature = (select force_matching_signature from v$sql where sql_id='&sql_id' and plan_hash_value=&phv and child_number=&child_no);

undefine sql_id
undefine phv
undefine fix
undefine enabled