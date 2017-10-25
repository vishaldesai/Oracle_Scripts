prompt Gather Table Statistics for table &1....

exec dbms_stats.gather_table_stats('&1', upper('&2'), degree=>8, method_opt=>'FOR ALL INDEXED COLUMNS SIZE 254', cascade=>true, granularity=>'ALL');

