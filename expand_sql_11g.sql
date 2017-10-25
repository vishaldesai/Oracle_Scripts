accept sql_text       prompt 'Please enter sql_text ('''' for literals) :'
set feedback off
 
declare
    m_sql_in    clob :='SELECT * FROM PFC_NDE_MAIN_STG_VW';
    m_sql_out   clob := empty_clob();
 
begin
    dbms_sql2.expand_sql_text(
        m_sql_in,
        m_sql_out
    );
 
    dbms_output.put_line(m_sql_out);
end;
/


accept sql_id       prompt 'Please enter sql_id :'
set feedback off
 
declare
    m_sql_in    clob ;
    m_sql_out   clob := empty_clob();
 
begin
	
	select sql_fulltext into m_sql_in from v$sql where sql_id='&sql_id' and child_number=0;
 
    dbms_sql2.expand_sql_text(
        m_sql_in,
        m_sql_out
    );
 
    dbms_output.put_line(m_sql_out);
end;
/


accept sql_id       prompt 'Please enter sql_id :'
set feedback off
 
declare
    m_sql_in    clob ;
    m_sql_out   clob := empty_clob();
 
begin
	
	select sql_text into m_sql_in from dba_hist_sqltext where sql_id='&sql_id' ;
 
    dbms_sql2.expand_sql_text(
        m_sql_in,
        m_sql_out
    );
 
    dbms_output.put_line(m_sql_out);
end;
/