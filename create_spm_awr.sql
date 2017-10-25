set linesize 500
set pages 9999
set feedback off
set sqlblanklines on
set serveroutput on
set verify off

accept sql_id      prompt 'Enter sql_id          :'
accept phv         prompt 'Enter plan_hash_value :'

select distinct snap_id from DBA_HIST_SQLSTAT where sql_id='&sql_id' and plan_hash_value=&phv;

accept ssnap       prompt 'Enter start snapshot  :'
accept esnap       prompt 'Enter end   snapshot  :'

exec DBMS_SQLTUNE.CREATE_SQLSET('&sql_id');

declare
baseline_ref_cursor DBMS_SQLTUNE.SQLSET_CURSOR;
begin
open baseline_ref_cursor for
select VALUE(p) from table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(&ssnap, &esnap,'sql_id='||CHR(39)||'&sql_id'||CHR(39)||' and plan_hash_value=' || &phv,NULL,NULL,NULL,NULL,NULL,NULL,'ALL')) p;
DBMS_SQLTUNE.LOAD_SQLSET('&sql_id', baseline_ref_cursor);
end;
/

--Verify SQLID in STS
select sql_id, substr(sql_text,1, 100) text
from dba_sqlset_statements
where sqlset_name = '&sql_id'
order by sql_id;

accept fix         prompt 'Enter Fixed(YES/NO)   :'
accept enabled		 prompt 'Enter Enabled(YES/NO) :'

SET SERVEROUTPUT ON
DECLARE
  l_plans_loaded  PLS_INTEGER;
BEGIN
  l_plans_loaded := dbms_spm.load_plans_from_sqlset(sqlset_name => '&sql_id',
                                              sqlset_owner => USER,
                                              fixed => '&fix',
                                              enabled => '&enabled');
                                              DBMS_OUTPUT.PUT_line(l_plans_loaded);
    
  DBMS_OUTPUT.put_line('Plans Loaded: ' || l_plans_loaded);
END;
/

set long 9999999
SELECT sql_handle, plan_name, enabled, accepted ,sql_text
FROM   dba_sql_plan_baselines
WHERE  signature = (select distinct force_matching_signature from dba_hist_sqlstat where sql_id='&sql_id' and plan_hash_value=&phv);

BEGIN
  DBMS_SQLTUNE.DROP_SQLSET( sqlset_name => '&sql_id' );
END;
/

undefine sql_id
undefine phv
undefine fix
undefine enabled
undefine ssnap
undefine esnap
