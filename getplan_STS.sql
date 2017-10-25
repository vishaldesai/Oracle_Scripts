set linesize 500
set pages 9999
set verify

accept stsname  prompt 'Enter STS name        :'
accept sql_id   prompt 'Enter sql_id          :'
accept phv      prompt 'Enter plan hash value :'

SELECT * FROM table (   DBMS_XPLAN.DISPLAY_SQLSET('&stsname','&sql_id',&phv,format=>'ADVANCED'));

undefine stsname
undefine sql_id
undefine phv