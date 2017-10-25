SET ECHO OFF
REM ***************************************************************************
REM ******************* Troubleshooting Oracle Performance ********************
REM ************************* http://top.antognini.ch *************************
REM ***************************************************************************
REM
REM File name...: comparing_object_statistics.sql
REM Author......: Christian Antognini
REM Date........: August 2008
REM Description.: This script shows how to compare current object statistics
REM               with object statistics stored in the history, that are
REM               pending, and stored in a backup table.
REM Notes.......: This scripts works in Oracle Database 11g only.
REM Parameters..: -
REM
REM You can send feedbacks or questions about this script to top@antognini.ch.
REM
REM Changes:
REM DD.MM.YYYY Description
REM ---------------------------------------------------------------------------
REM 08.03.2009 Fixed timing issue after sleep(15) + ORA-00001
REM ***************************************************************************

SET TERMOUT ON
SET FEEDBACK OFF
SET VERIFY OFF
SET SCAN ON
SET LONG 1000000

@../connect.sql

SET ECHO ON

REM
REM Setup test environment
REM

DROP TABLE t;

CREATE TABLE t
AS
SELECT rownum AS id,
       round(dbms_random.normal*1000) AS val1,
       10 + round(ln(rownum/2+2)) AS val2,
       dbms_random.string('p',25) AS pad
FROM dual
CONNECT BY level <= 10000
ORDER BY dbms_random.value;

ALTER TABLE t ADD CONSTRAINT t_pk PRIMARY KEY (id);

BEGIN
  dbms_stats.gather_table_stats(
    ownname          => user,
    tabname          => 'T',
    estimate_percent => 1,
    method_opt       => 'for all columns size skewonly',
    cascade          => TRUE
  );
END;
/

PAUSE

REM
REM Pending statistics
REM

INSERT INTO t
SELECT 10000+id, val1, val2, pad
FROM t
WHERE rownum <= 2500
ORDER BY dbms_random.value;

COMMIT;

BEGIN
  dbms_stats.set_table_prefs(
    ownname => user,
    tabname => 't',
    pname   => 'publish',
    pvalue  => 'false'
  );
  dbms_stats.gather_table_stats(
    ownname          => user,
    tabname          => 'T',
    estimate_percent => 1,
    method_opt       => 'for all columns size skewonly',
    cascade          => TRUE
  );
  dbms_stats.set_table_prefs(
    ownname => user,
    tabname => 't',
    pname   => 'publish',
    pvalue  => 'true'
  );
END;
/

PAUSE

SELECT *
FROM table(dbms_stats.diff_table_stats_in_pending(
             ownname => user,
             tabname => 'T',
             time_stamp => NULL,
             pctthreshold => 10));

PAUSE

REM
REM History
REM

execute dbms_lock.sleep(15)

BEGIN
  dbms_stats.publish_pending_stats(
    ownname => user, 
    tabname => 'T'
  );
END;
/

SELECT *
FROM table(dbms_stats.diff_table_stats_in_history(
             ownname      => 'VDESAI',
             tabname      => 'X',
             time1        => systimestamp - to_dsinterval('0 00:1:26'),
             time2        => NULL,
             pctthreshold => 10));

PAUSE

REM
REM Backup table
REM

INSERT INTO t
SELECT 20000+id, val1, val2, pad
FROM t
WHERE rownum <= 2500
ORDER BY dbms_random.value;

COMMIT;

BEGIN
  BEGIN
    dbms_stats.drop_stat_table(
      ownname => user, 
      stattab => 'MYSTATS'
    );
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  dbms_stats.create_stat_table(
    ownname  => user, 
    stattab  => 'MYSTATS', 
    tblspace => 'USERS'
  );
  dbms_stats.gather_table_stats(
    ownname          => user,
    tabname          => 'T',
    estimate_percent => 1,
    method_opt       => 'for all columns size skewonly',
    cascade          => TRUE,
    stattab          => 'MYSTATS',
    statown          => user,
    statid           => 'SET1'
  );
END;
/

PAUSE

SELECT *
FROM table(dbms_stats.diff_table_stats_in_stattab(
             ownname      => user,
             tabname      => 'T',
             stattab1     => 'MYSTATS',
             statid1      => 'SET1',
             stattab1own  => user,
             pctthreshold => 10));

PAUSE

SELECT stats_update_time
FROM user_tab_stats_history
WHERE table_name = 'T';

PAUSE

REM
REM Cleanup
REM

DROP TABLE t;
PURGE TABLE t;

BEGIN
  dbms_stats.drop_stat_table(
    ownname => user, 
    stattab => 'MYSTATS'
  );
END;
/
