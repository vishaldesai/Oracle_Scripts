SET ECHO OFF
SET TERMOUT ON
SET FEEDBACK OFF
SET VERIFY OFF
SET SCAN ON

--REM
--REM Install the profiler tables
--REM
--REM @?/rdbms/admin/dbmshptab.sql

--REM
--REM Enable the profiler
--REM

-- BEGIN
--  dbms_hprof.start_profiling(location => 'PLSHPROF_DIR',
--                             filename => 'dbms_hprof.trc');
--END;
--/

--
--REM Stop the profiler
--REM

--BEGIN
--  dbms_hprof.stop_profiling;
--END;
--/

--Load profiling data into output tables
--SELECT dbms_hprof.analyze(location => 'PLSHPROF_DIR',
--                          filename => 'dbms_hprof.trc') AS runid
--FROM dual;


REM Namespaces

SELECT sum(function_elapsed_time)/1000 AS total_ms,
       100*ratio_to_report(sum(function_elapsed_time)) over () AS total_percent,
       sum(calls) AS calls,
       100*ratio_to_report(sum(calls)) over () AS calls_percent,
       namespace AS namespace_name
FROM dbmshp_function_info
WHERE runid = &runid
GROUP BY namespace
ORDER BY total_ms DESC;

PAUSE

REM Modules

SELECT sum(function_elapsed_time)/1000 AS total_ms,
       100*ratio_to_report(sum(function_elapsed_time)) over () AS total_percent,
       sum(calls) AS calls,
       100*ratio_to_report(sum(calls)) over () AS calls_percent,
       namespace,
       nvl(nullif(owner || '.' || module, '.'), function) AS module_name,
       type
FROM dbmshp_function_info
WHERE runid = &runid
GROUP BY namespace, nvl(nullif(owner || '.' || module, '.'), function), type
ORDER BY total_ms DESC;

PAUSE

REM Call hierarchy

SELECT lpad(' ', (level-1) * 2) || nullif(c.owner || '.', '.') ||
       CASE WHEN c.module = c.function THEN c.function ELSE nullif(c.module || '.', '.') || c.function END AS function_name,
       pc.subtree_elapsed_time/1000 AS total_ms, 
       pc.function_elapsed_time/1000 AS function_ms,
       pc.calls AS calls
FROM dbmshp_parent_child_info pc, 
     dbmshp_function_info p, 
     dbmshp_function_info c
START WITH pc.runid = &runid
AND p.runid = pc.runid
AND c.runid = pc.runid
AND pc.childsymid = c.symbolid
AND pc.parentsymid = p.symbolid
AND p.symbolid = 1
CONNECT BY pc.runid = prior pc.runid
AND p.runid = pc.runid 
AND c.runid = pc.runid
AND pc.childsymid = c.symbolid 
AND pc.parentsymid = p.symbolid
AND prior pc.childsymid = pc.parentsymid
ORDER SIBLINGS BY total_ms DESC;

PAUSE

REM Functions

SELECT c.subtree_elapsed_time/1000 AS total_ms,
       c.subtree_elapsed_time*100/t.total AS total_percent,
       c.function_elapsed_time/1000 AS function_ms,
       c.function_elapsed_time*100/t.total AS function_percent,
       (c.subtree_elapsed_time-c.function_elapsed_time)/1000 AS descendants_ms,
       (c.subtree_elapsed_time-c.function_elapsed_time)*100/t.total AS descendants_percent,
       c.calls AS calls,
       c.calls*100/t.tcalls AS calls_percent,
       nullif(c.owner || '.', '.') ||
         CASE WHEN c.module = c.function THEN c.function ELSE nullif(c.module || '.', '.') || c.function END ||
         CASE WHEN c.line# = 0 THEN '' ELSE ' (line '||c.line#||')' END AS function_name
FROM dbmshp_function_info c,
     (SELECT max(subtree_elapsed_time) AS total, 
             sum(calls) AS tcalls
      FROM dbmshp_function_info
      WHERE runid = &runid) t
WHERE c.runid = &runid
ORDER BY total_ms DESC;


UNDEFINE runid
