prompt eXplain the execution plan for sqlid &1

select * from table(dbms_xplan.display_cursor('&1',null,'ALLSTATS LAST'));
