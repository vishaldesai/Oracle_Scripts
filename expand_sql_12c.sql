accept sql_text       prompt 'Please enter sql_text ('''' for literals) :'
set linesize 32000 pagesize 0 serveroutput on
declare
   original_sql clob :='&sql_text';
   expanded_sql clob := empty_clob();
begin
    dbms_utility.expand_sql_text(original_sql,expanded_sql);
    dbms_output.put_line(expanded_sql);
end;
/  