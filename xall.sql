select * from table( dbms_xplan.display_cursor(null, null, 'ADVANCED +PEEKED_BINDS +ALLSTATS LAST +MEMSTATS LAST +PARALLEL') );

