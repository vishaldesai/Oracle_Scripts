/*****************************************************************************************/
--This script originally written by Dion Cho 
--http://dioncho.wordpress.com/2009/07/14/decoding-block-dump-using-utl_raw/
--
--What I changed was 
--1- scripts asks 3 parameter OBJECT_NAME OWNER I/D(depending on the dump type)
--2- include index_tree_dump conversion
--3- Changed the regexp_replace search string to cover the needs on index dump and columns with 2 digit length
--4- changed to extract only interpreted stack. 
--Usage 
--In the session you dumped the block 
--
--for table dumps
--SQL>decode_block_dump.sql TABLE_NAME OWNER D
--for index tree dumps
--SQL>decode_block_dump.sql INDEX_NAME OWNER I
--
--get_trace_file1  function is explained in his blog post 
--http://dioncho.wordpress.com/2009/03/19/another-way-to-use-trace-file/#comment-333
--I change it a bit to use the benefits of new diagnostics feature of 11g
--
/*********************************************************************************************/


spool C:\TEMP\scripts\logs\block_dump.txt


set serveroutput on

declare
v_varchar2 varchar2(4000);
v_number number;
col_idx number;
col_pos number;
pos number;
col_type varchar2(200);
col_name varchar2(100);
col_value varchar2(4000);
col_len number;
flag number;
begin

if upper('&3') = 'D' then
for r in (select column_value as txt from table(get_trace_file1)) loop
if r.txt like 'Block header dump:%' then
flag:=1;
elsif  r.txt like 'Dump of memory from%' then
dbms_output.new_line;
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-------NEW BLOCK DUMP STACK--------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
flag:=0;
end if;
If flag=1 then
dbms_output.put(r.txt);
if regexp_like(r.txt, 'col[[:space:]]+[[:digit:]]+:') then 
col_idx := regexp_replace(r.txt, 'col[[:space:]]+([[:digit:]])+: [[:print:]]+', '\1');

select data_length,column_name, data_type into col_len,col_name, col_type
from dba_tab_cols
where table_name = upper('&1')
and column_id = col_idx+1 and owner='&2';


col_value := replace(regexp_replace(r.txt, 'col[[:space:]]+[[:digit:]]+:[[:space:]]+\[([[:space:]]|[[:digit:]])+[[:digit:]]\][[:space:]]+([[:print:]]+)','\2'), ' ', '');
if col_type = 'NUMBER' and col_value not like  '%NULL%' and col_len<70 then
--dbms_stats.convert_raw_value(col_value, v_number);
v_number := utl_raw.cast_to_number(col_value);
dbms_output.put('---- means ' || col_name || ' = ' || v_number);
elsif col_type = 'VARCHAR2' and col_value not like  '%NULL%' and col_len<70 then
--dbms_stats.convert_raw_value(col_value, v_varchar2);
v_varchar2 := utl_raw.cast_to_varchar2(col_value);
dbms_output.put('---- means ' || col_name || ' = ' || v_varchar2);
-- elsif col_value not like  '%NULL%' and col_len<70 then
-- dbms_output.put(r.txt);
end if;
end if;
end if;
dbms_output.new_line;
end loop;
elsif upper('&3') = 'I' then
for r in (select column_value as txt from table(get_trace_file1))
loop
begin
if r.txt like 'Block header dump:%' then
flag:=1;
elsif r.txt like '%end of leaf block dump%' then
dbms_output.new_line;
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----NEW INDEX BLOCK DUMP STACK----');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
dbms_output.put('-----------------------------------');
dbms_output.put_line(chr(13));
flag:=0;
end if;
If flag=1 then
dbms_output.put(r.txt);
if regexp_like(r.txt, 'col[[:space:]]+[[:digit:]]+;') then 
col_idx := regexp_replace(r.txt, 'col[[:space:]]+([[:digit:]])+; [[:print:]]+', '\1');
select dic.column_name,data_type,dtc.data_length into col_name,col_type,col_len
from dba_ind_columns dic,dba_tab_columns dtc 
where dic.TABLE_NAME=dtc.TABLE_NAME
and dic.TABLE_OWNER=dtc.OWNER
and dic.column_name=dtc.column_name
and dic.index_name='&1'
and dtc.owner='&2'
and column_position=col_idx+1;

col_value := replace(regexp_replace(r.txt,'col[[:space:]]+[[:digit:]]+;[[:space:]]+len[[:space:]]+[[:digit:]]*+;[[:space:]]+\([[:digit:]]*\):[[:space:]]+([[:print:]]+)', '\1'), ' ', '');
if col_type = 'NUMBER' and col_value not like  '%NULL%' and col_len<70then
--dbms_stats.convert_raw_value(col_value, v_number);
v_number := utl_raw.cast_to_number(col_value);
dbms_output.put('---- means ' || col_name || ' = ' || v_number);
elsif col_type = 'VARCHAR2' and col_value not like  '%NULL%' and col_len<70 then
--dbms_stats.convert_raw_value(col_value, v_varchar2);
v_varchar2 := utl_raw.cast_to_varchar2(col_value);
dbms_output.put('---- means ' || col_name || ' = ' || v_varchar2);
-- elsif col_value not like  '%*NULL*%' and col_len<70 then
-- dbms_output.put(r.txt);
end if;
end if;
end if;

exception
when no_data_found then
col_name:=null;
col_type:=null;
end;
dbms_output.new_line;
end loop;
end if;
end;
/

set serveroutput off
spool off

