SET ECHO OFF
REM ***************************************************************************
REM ******************* Troubleshooting Oracle Performance ********************
REM ************************* http://top.antognini.ch *************************
REM ***************************************************************************
REM
REM File name...: sqlarea.sql
REM Author......: Christian Antognini
REM Date........: January 2014
REM Description.: This script shows detailed information about a cursor.
REM               It can show:
REM               - The statistics since the cursor was loaded
REM               - The statistics about the last n seconds
REM               When the second parameter is set to a value greater than 0, 
REM               the latter are shown. Otherwise, the former are shown.
REM Notes.......: The data is based on the v$sqlarea dynamic performance view
REM Parameters..: &1: SQL id of the parent cursor
REM               &2: length of the interval in seconds
REM
REM You can send feedbacks or questions about this script to top@antognini.ch.
REM
REM Changes:
REM DD.MM.YYYY Description
REM ---------------------------------------------------------------------------
REM 30.06.2014 Implemented diff + Added header to the output
REM ***************************************************************************

SET TERMOUT OFF SERVEROUT ON LONG 1000000 LONGCHUNKSIZE 1000000 LINESIZE 90 VERIFY OFF FEEDBACK OFF HEADING OFF

COLUMN "Text" FORMAT A90 WRAP
COLUMN global_name NEW_VALUE global_name
COLUMN day NEW_VALUE day

VARIABLE sql_id VARCHAR2(13)
VARIABLE interval NUMBER

BEGIN
  :sql_id := '&1';
  :interval := to_number('&2');
  IF :interval < 0
  THEN
    :interval := 0;
  END IF;
EXCEPTION
  WHEN value_error THEN
    :interval := 0;
END;
/

UNDEFINE 1
UNDEFINE 2

SELECT global_name, decode(:interval, 0, to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'),
                                         to_char(sysdate,'YYYY-MM-DD')) AS day
FROM global_name;

TTITLE CENTER '&global_name / &day' SKIP 2

SET TERMOUT ON

SELECT sql_fulltext AS "Text"
FROM v$sqlarea
WHERE sql_id = :sql_id;

DECLARE
  c_line CONSTANT INTEGER := 90;
  c_col1 CONSTANT INTEGER := 36;
  c_col2 CONSTANT INTEGER := 54;

  t1 DATE;
  t2 DATE;
  s1 v$sqlarea%ROWTYPE;
  s2 v$sqlarea%ROWTYPE;
  w1 NUMBER;
  w2 NUMBER;
  r NUMBER;
  e NUMBER;
  p VARCHAR2(100);

  PROCEDURE o(p_name IN VARCHAR2, p_value IN VARCHAR2) AS
  BEGIN
    IF p_value IS NULL
    THEN
      dbms_output.put_line(p_name);
    ELSE
      dbms_output.put_line(rpad(p_name, c_col1) || lpad(p_value, c_col2));
    END IF;
  END;

  PROCEDURE o(p_name IN VARCHAR2, p_value1 IN VARCHAR2, p_value2 IN VARCHAR2, p_value3 IN VARCHAR2) AS
  BEGIN
    dbms_output.put_line(rpad(p_name, c_col1) || lpad(p_value1, c_col2/3) || lpad(p_value2, c_col2/3) || lpad(p_value3, c_col2/3));
  END;

  PROCEDURE o(p_text IN VARCHAR2) AS
  BEGIN
    o(p_text, cast(NULL AS VARCHAR2));
  END;

  PROCEDURE o(p_linesize IN INTEGER DEFAULT c_line) AS
  BEGIN
    dbms_output.put_line(rpad('-', p_linesize, '-'));
  END;

  PROCEDURE o(p_name IN VARCHAR2, p_value IN NUMBER, p_integer IN BOOLEAN DEFAULT TRUE) AS
  BEGIN
    IF p_integer
    THEN
      o(p_name, to_char(round(p_value, 0), '9,999,999,999,999'));
    ELSE
      o(p_name, to_char(round(p_value, 3), '9,999,999,990.999'));
    END IF;
  END;

  PROCEDURE o(p_name IN VARCHAR2, p_value IN NUMBER, p_executions IN NUMBER, p_rows IN NUMBER, p_integer IN BOOLEAN DEFAULT TRUE) AS
  BEGIN
    IF p_integer
    THEN
      o(p_name, 
        to_char(round(p_value, 0), '9,999,999,999,999'), 
        to_char(round(p_value/nullif(p_executions, 0), 0), '9,999,999,999,999'), 
        to_char(round(p_value/nullif(p_rows, 0), 3), '9,999,999,990.999'));
    ELSE
      o(p_name, 
        to_char(round(p_value, 3), '9,999,999,990.999'), 
        to_char(round(p_value/nullif(p_executions, 0), 3), '9,999,999,990.999'), 
        to_char(round(p_value/nullif(p_rows, 0), 3), '9,999,999,990.999'));
    END IF;
  END;
  
BEGIN
  t1 := sysdate;
  
  IF :interval > 0
  THEN
    SELECT * INTO s1
    FROM v$sqlarea
    WHERE sql_id = :sql_id;
  
    dbms_lock.sleep(:interval);
  END IF;

  t2 := sysdate;
  
  SELECT * INTO s2
  FROM v$sqlarea
  WHERE sql_id = :sql_id;

  IF :interval > 0
  THEN    
    o();
    o('Interval (seconds)', :interval);
    o('Period', to_char(t1, 'YYYY-MM-DD HH24:MI:SS') || ' - ' || to_char(t2, 'YYYY-MM-DD HH24:MI:SS'));
  END IF;
  o();
  o('Identification');
  o();
  $IF dbms_db_version.version >= 12
  $THEN
    o('Container Id', s2.con_id);
  $END
  o('SQL Id', s2.sql_id);
  o('Execution Plan Hash Value', to_char(s2.plan_hash_value));

  o();
  o('General');
  o();
  o('Module', s2.module);
  o('Action', s2.action);
  $IF NOT (dbms_db_version.version = 10 AND dbms_db_version.release = 1)
  $THEN
    o('Parsing Schema', s2.parsing_schema_name);
  $ELSE
    DECLARE
      l_username dba_users.username%TYPE;
    BEGIN
    	SELECT username INTO l_username
      FROM dba_users
      WHERE user_id = s2.parsing_schema_id;
      o('Parsing Schema', l_username);
    EXCEPTION
      WHEN no_data_found THEN
        o('Parsing Schema ID', s2.parsing_schema_id);
    END;
  $END
  BEGIN
    IF s2.program_id IS NOT NULL AND s2.program_id <> 0
    THEN
      SELECT owner || '.' || object_name INTO p
      FROM dba_objects
      WHERE object_id = s2.program_id;
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      p := to_char(s2.program_id);
  END;
  o('PL/SQL Program', p);
  o('PL/SQL Line Number', nullif(s2.program_line#,1));
  o('SQL Profile', s2.sql_profile);
  o('Stored Outline Category', s2.outline_category);
  $IF dbms_db_version.version >= 11
  $THEN
     o('SQL Plan Baseline', s2.sql_plan_baseline);
  $END

  o();
  o('Shared Cursors Statistics');
  o();
  o('Total Parses', s2.parse_calls - nvl(s1.parse_calls,0));
  o('Loads / Hard Parses', s2.loads - nvl(s1.loads,0));
  o('Invalidations', s2.invalidations - nvl(s1.invalidations,0));
  o('Cursor Size / Shared (bytes)', s2.sharable_mem - nvl(s1.sharable_mem,0));
  o('Cursor Size / Persistent (bytes)', s2.persistent_mem - nvl(s1.persistent_mem,0));
  o('Cursor Size / Runtime (bytes)', s2.runtime_mem - nvl(s1.runtime_mem,0));
  o('First Load Time', s2.first_load_time);
  o('Last Load Time', to_char(s2.last_load_time, 'YYYY-MM-DD/HH24:MI:SS'));

  o();
  o('Activity by Time');
  o();
  o('Elapsed Time (seconds)', (s2.elapsed_time - nvl(s1.elapsed_time,0)) / 1E6, FALSE);
  o('CPU Time (seconds)', (s2.cpu_time - nvl(s1.cpu_time,0)) / 1E6, FALSE);
  w1 := s1.elapsed_time - s1.cpu_time;
  w2 := s2.elapsed_time - s2.cpu_time;
  o('Wait Time (seconds)', (w2 - nvl(w1,0)) / 1E6, FALSE);

  o();
  o('Activity by Waits');
  o();
  o('Application Waits (%)', (s2.application_wait_time - nvl(s1.application_wait_time, 0)) / nullif(s2.elapsed_time - nvl(s1.elapsed_time,0), 0) * 100, FALSE);   
  o('Concurrency Waits (%)', (s2.concurrency_wait_time - nvl(s1.concurrency_wait_time, 0)) / nullif(s2.elapsed_time - nvl(s1.elapsed_time,0), 0) * 100, FALSE);   
  o('Cluster Waits (%)', (s2.cluster_wait_time - nvl(s1.cluster_wait_time, 0)) / nullif(s2.elapsed_time - nvl(s1.elapsed_time, 0), 0) * 100, FALSE);
  o('User I/O Waits (%)', (s2.user_io_wait_time - nvl(s1.user_io_wait_time, 0)) / nullif(s2.elapsed_time - nvl(s1.elapsed_time, 0), 0) * 100, FALSE);
  w1 := s1.elapsed_time - s1.cpu_time - s1.application_wait_time - s1.concurrency_wait_time - s1.cluster_wait_time - s1.user_io_wait_time;
  w2 := s2.elapsed_time - s2.cpu_time - s2.application_wait_time - s2.concurrency_wait_time - s2.cluster_wait_time - s2.user_io_wait_time;
  o('Remaining Waits (%)', (w2 - nvl(w1, 0)) / nullif(s2.elapsed_time - nvl(s1.elapsed_time, 0), 0) * 100, FALSE);   
  o('CPU (%)', (s2.cpu_time - nvl(s1.cpu_time, 0)) / nullif(s2.elapsed_time - nvl(s1.elapsed_time, 0), 0) * 100, FALSE);

  o();
  o('Elapsed Time Breakdown');
  o();
  w1 := s1.elapsed_time - s1.plsql_exec_time - s1.java_exec_time;
  w2 := s2.elapsed_time - s2.plsql_exec_time - s2.java_exec_time;
  o('SQL Time (seconds)', (w2 - nvl(w1, 0)) / 1E6, FALSE);  
  o('PL/SQL Time (seconds)', (s2.plsql_exec_time - nvl(s1.plsql_exec_time, 0)) / 1E6, FALSE);
  o('Java Time (seconds)', (s2.java_exec_time - nvl(s1.java_exec_time, 0)) / 1E6, FALSE);

  o();
  o('Execution Statistics', '             Total     Per Execution           Per Row');
  o();
  e := s2.executions - nvl(s1.executions, 0);
  r := s2.rows_processed - nvl(s1.rows_processed, 0);
  o('Elapsed Time (milliseconds)', (s2.elapsed_time - nvl(s1.elapsed_time, 0)) / 1E3, e, r);
  o('CPU Time (milliseconds)', (s2.cpu_time - nvl(s1.cpu_time, 0)) / 1E3, e, r);
  o('Executions', s2.executions - nvl(s1.executions, 0), e, r);
  o('Buffer Gets', s2.buffer_gets - nvl(s1.buffer_gets, 0), e, r);
  o('Disk Reads', s2.disk_reads - nvl(s1.disk_reads, 0), e, r);
  o('Direct Writes', s2.direct_writes - nvl(s1.direct_writes, 0), e, r);
  o('Rows', s2.rows_processed - nvl(s1.rows_processed, 0), e, r);
  o('Fetches', s2.fetches - nvl(s1.fetches, 0), e, r);
  o('Average Fetch Size', nullif(r, 0) / (s2.fetches - nvl(s1.fetches, 0)), NULL, NULL);

  o();
  o('Other Statistics');
  o();
  o('Executions that Fetched All Rows (%)', floor((s2.end_of_fetch_count - nvl(s1.end_of_fetch_count, 0)) / nullif(s2.executions - nvl(s1.executions, 0), 0) * 100));
  o('Serializable Aborts', s2.serializable_aborts - nvl(s1.serializable_aborts, 0));
  o('Remote', s2.remote);
  o('Obsolete', s2.is_obsolete);
  $IF dbms_db_version.version >= 11
  $THEN
    o('Bind Sensitive', s2.is_bind_sensitive);
    o('Bind Aware', s2.is_bind_aware);
  $END
  o();

END;
/

TTITLE OFF

CLEAR COLUMNS
