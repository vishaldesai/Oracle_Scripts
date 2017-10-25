set markup html preformat on
set linesize 200
set pages 500
Rem
Rem Use the display table function from the dbms_xplan package to display the last
Rem explain plan. Force serial option for backward compatibility
Rem
select plan_table_output from table(dbms_xplan.display('plan_table',null,'ALL -PROJECTION -NOTE'));
