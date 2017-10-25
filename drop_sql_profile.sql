set linesize 500
set pages 9999
set verify

accept sql_profile_name  prompt 'Enter sql_profile_name :'

set long 9999999

select NAME,CATEGORY,SIGNATURE,SQL_TEXT,FORCE_MATCHING from dba_sql_profiles where name='&sql_profile_name';


BEGIN
  DBMS_SQLTUNE.DROP_SQL_PROFILE(name => '&sql_profile_name');
END;
/

undefine sql_profile_name