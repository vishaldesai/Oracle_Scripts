undefine sql_id
undefine sid
variable sql_id varchar2(20);

begin 
    select sql_id into :sql_id from v$session where sid = &sid;
end;
/

print sql_id

SELECT * FROM TABLE(dbms_xplan.display_cursor(:sql_id,null,format=>'ALL'));

undefine sql_id
undefine sid