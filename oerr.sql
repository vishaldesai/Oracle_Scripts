-- OERR functionality - list description for and ORA- error code
-- The data comes from $ORACLE_HOME/rdbms/mesg/oraus.msb file
-- which is a binary compiled version of $ORACLE_HOME/rdbms/mesg/oraus.msg file


@@saveset
set serverout on size 1000000 feedback off
prompt
exec dbms_output.put_line(sqlerrm(-&1))
prompt
@@loadset