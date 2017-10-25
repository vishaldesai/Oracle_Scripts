set serveroutput on size 1000000
exec runStats_pkg.rs_start;
select count(1) from dba_tables;
exec runStats_pkg.rs_middle;
select count(1) from dba_extents;
exec runStats_pkg.rs_stop;


