prompt alter session set events '10053 trace name context forever, level 2';;
prompt alter session set "_optimizer_trace"=all;;

alter session set events '10053 trace name context forever, level 2';
alter session set "_optimizer_trace"=all;

/*
execute DBMS_SQLDIAG.DUMP_TRACE(p_sql_id=>'sql_id',  p_child_number=>0, 
p_component=>'Compiler',
p_file_id=>' test1053');

*/
