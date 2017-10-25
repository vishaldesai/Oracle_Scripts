set long 999999
set linesize 200
set pages 800
select * from table(dbms_xplan.display(NULL,NULL,'advanced'));