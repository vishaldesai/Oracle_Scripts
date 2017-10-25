-- 10g2+

prompt Display execution plan for last statement for this session from library cache...

-- select * from table(dbms_xplan.display_cursor(null,null,'ALLSTATS LAST +COST +PEEKED_BINDS'));

-- this is 10gR1 command (or @x101.sql)
--
-- select * from table(dbms_xplan.display_cursor(null,null,'RUNSTATS_LAST'));

-- in 9.2 use @xm <hash_value> <child_number> 
-- <child_number> can be % if you want all children

def _x_temp_env=&_tpt_tempdir/env_&_tpt_tempfile..sql
def _x_temp_sql=&_tpt_tempdir/sql_&_tpt_tempfile..sql

set termout off
store set &_x_temp_env replace
save      &_x_temp_sql replace
set termout on

select * from table(dbms_xplan.display_cursor(null,null,'ALLSTATS LAST +PEEKED_BINDS +PARALLEL +PARTITION +COST'));

set termout off
@/&_x_temp_env
get &_x_temp_sql
set termout on 
