set linesize 400
set pages 9999
accept sql_id      prompt 'Please enter the sql_id                  :'
accept phv         prompt 'Please enter the phv                     :'
SELECT * FROM TABLE(dbms_xplan.display_awr('&sql_id','&phv',NULL,'ALL +predicate'));