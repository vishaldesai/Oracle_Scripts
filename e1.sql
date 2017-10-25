/*
 
Copyright 2010 Iggy Fernandez
 
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
 
The purpose of this SQL*Plus script is to generate a Graphviz
program that can draw a tree-structure graphical version of a query
plan. It prompts for a SQL_ID and CHILD_NUMBER. The following basic
data items are first obtained from V$SQL_PLAN_STATISTICS_ALL:
 
  id
  parent_id
  object_name
  operation
  options
  last_starts
  last_elapsed_time / 1000000 AS last_elapsed_time
  cardinality
  last_output_rows
  last_cr_buffer_gets + last_cu_buffer_gets AS last_buffer_gets
  last_disk_reads
 
The following items are then computed from the basic data:
 
  execution_sequence#
  delta_elapsed_time
  delta_buffer_gets
  delta_disk_reads
  delta_percentage_elapsed_time
  delta_percentage_buffer_gets
  delta_percentage_disk_reads
  last_percentage_elapsed_time
  last_percentage_buffer_gets
  last_percentage_disk_reads
 
Graphviz commands are then spooled to plan.dot. If Graphviz has been
installed, the following command can be used to produce graphical
output.
 
  dot -Tjpg -oplan.jpg plan.dot
 
As an example, the following query generates a list of employees
whose salaries are higher than their respective managers.
 
SELECT
  emp.employee_id AS emp_id,
  emp.salary AS emp_salary
FROM
  employees emp
WHERE EXISTS (
  SELECT
    *
  FROM
    employees mgr
  WHERE
    emp.manager_id = mgr.employee_id
  AND
    emp.salary > mgr.salary
);
 
Here is an abbreviated version of the traditional tabular query
plan.
 
----------------------------------------
| Id  | Operation          | Name      |
----------------------------------------
|   0 | SELECT STATEMENT   |           |
|   1 |  HASH JOIN SEMI    |           |
|   2 |   TABLE ACCESS FULL| EMPLOYEES |
|   3 |   TABLE ACCESS FULL| EMPLOYEES |
----------------------------------------
 
And here is an abbreviated version of the Graphviz program produced
by this script.
 
digraph EnhancedPlan {graph[ordering="out"];node[fontname=Arial fontsize=8];
"0" [label="Step 4 (Id 0)\nSELECT STATEMENT", shape=plaintext];
"1" [label="Step 3 (Id 1)\nHASH JOIN SEMI", shape=plaintext];
"2" [label="Step 1 (Id 2)\nTABLE ACCESS FULL EMPLOYEES", shape=plaintext];
"3" [label="Step 2 (Id 3)\nTABLE ACCESS FULL EMPLOYEES", shape=plaintext];
"0"->"1" [dir=back];
"1"->"2" [dir=back];
"1"->"3" [dir=back];
}
 
*/
--------------------------------------------------------------------------------
 
-- SQL*Plus settings
 
SET linesize 1000
SET trimspool on
SET pagesize 0
SET echo off
SET heading off
SET feedback off
SET verify off
SET time off
SET timing off
SET sqlblanklines on
 
SPOOL plan.dot
 
--------------------------------------------------------------------------------
 
-- First retrieve the basic data from V$SQL_PLAN_STATISTICS_ALL.
-- Modify this subquery if you want data from a different source.
 
WITH plan_table AS
 
(
 
  SELECT
 
    id,
    parent_id,
    object_name,
    operation,
    options,
    last_starts,
    last_elapsed_time / 1000000 AS last_elapsed_time,
    cardinality,
    last_output_rows,
    last_cr_buffer_gets + last_cu_buffer_gets AS last_buffer_gets,
    last_disk_reads
 
  FROM
 
    v$sql_plan_statistics_all
 
  WHERE
 
    sql_id = '&sql_id'
    AND child_number = &child_number
 
),
 
--------------------------------------------------------------------------------
 
-- Determine the order in which steps are actually executed
 
execution_sequence AS
 
(
 
  SELECT
 
    id,
    ROWNUM AS execution_sequence#
 
  FROM
 
    plan_table pt1
 
  START WITH
 
    -- Start with the leaf nodes
    NOT EXISTS (
      SELECT *
      FROM plan_table pt2
      WHERE pt2.parent_id = pt1.id
    )
 
  CONNECT BY
 
    -- Connect to the parent node
    pt1.id = PRIOR pt1.parent_id
    -- if the prior node was the oldest sibling
    AND PRIOR pt1.id >= ALL(
      SELECT pt2.id
      FROM plan_table pt2
      WHERE pt2.parent_id = pt1.id
    )
 
  -- Process the leaf nodes from left to right
  ORDER SIBLINGS BY pt1.id
 
),
 
--------------------------------------------------------------------------------
 
-- Calculate deltas for elapsed time, buffer gets, and disk reads
 
deltas AS
 
(
 
  SELECT
 
    t1.id,
    t1.last_elapsed_time - NVL(SUM(t2.last_elapsed_time),0) AS delta_elapsed_time,
    t1.last_buffer_gets - NVL(SUM(t2.last_buffer_gets),0) AS delta_buffer_gets,
    t1.last_disk_reads - NVL(SUM(t2.last_disk_reads),0) AS delta_disk_reads
 
  FROM
 
    plan_table t1
    LEFT OUTER JOIN plan_table t2
    ON t1.id = t2.parent_id
 
  GROUP BY
 
    t1.id,
    t1.last_elapsed_time,
    t1.last_buffer_gets,
    t1.last_disk_reads
 
),
 
--------------------------------------------------------------------------------
 
-- Join the results of the previous subqueries
 
enhanced_plan_table AS
 
(
 
  SELECT
 
    -- Items from the plan_table subquery
 
    plan_table.id,
    plan_table.parent_id,
    plan_table.object_name,
    plan_table.operation,
    plan_table.options,
    plan_table.last_starts,
    plan_table.last_elapsed_time,
    plan_table.cardinality,
    plan_table.last_output_rows,
    plan_table.last_buffer_gets,
    plan_table.last_disk_reads,
 
    -- Items from the execution_sequence subquery
 
    execution_sequence.execution_sequence#,
 
    -- Items from the deltas subquery
 
    deltas.delta_elapsed_time,
    deltas.delta_buffer_gets,
    deltas.delta_disk_reads,
 
    -- Computed percentages
 
    CASE
      WHEN (SUM(deltas.delta_elapsed_time) OVER () = 0)
      THEN (100)
      ELSE (100 * deltas.delta_elapsed_time / SUM(deltas.delta_elapsed_time) OVER ())
    END AS delta_percentage_elapsed_time,
 
    CASE
      WHEN (SUM(deltas.delta_buffer_gets) OVER () = 0)
      THEN (100)
      ELSE (100 * deltas.delta_buffer_gets / SUM(deltas.delta_buffer_gets) OVER ())
    END AS delta_percentage_buffer_gets,
 
    CASE
      WHEN (SUM(deltas.delta_disk_reads) OVER () = 0)
      THEN (100)
      ELSE (100 * deltas.delta_disk_reads / SUM(deltas.delta_disk_reads) OVER ())
    END AS delta_percentage_disk_reads,
 
    CASE
      WHEN (SUM(deltas.delta_elapsed_time) OVER () = 0)
      THEN (100)
      ELSE (100 * plan_table.last_elapsed_time / SUM(deltas.delta_elapsed_time) OVER ())
    END AS last_percentage_elapsed_time,
 
    CASE
      WHEN (SUM(deltas.delta_buffer_gets) OVER () = 0)
      THEN (100)
      ELSE (100 * plan_table.last_buffer_gets / SUM(deltas.delta_buffer_gets) OVER ())
    END AS last_percentage_buffer_gets,
 
    CASE
      WHEN (SUM(deltas.delta_disk_reads) OVER () = 0)
      THEN (100)
      ELSE (100 * plan_table.last_disk_reads / SUM(deltas.delta_disk_reads) OVER ())
    END AS last_percentage_disk_reads
 
  FROM
 
    plan_table,
    execution_sequence,
    deltas
 
  WHERE
 
    plan_table.id = execution_sequence.id
    AND plan_table.id = deltas.id
 
  -- Order the results for cosmetic purposes
  ORDER BY plan_table.id
 
)
 
--------------------------------------------------------------------------------
 
-- Begin THE Graphviz program
 
SELECT
 
  'digraph EnhancedPlan {'
  || 'graph[ordering="out"];'
  || 'node[fontname=Arial fontsize=8];' AS command
 
FROM DUAL
 
--------------------------------------------------------------------------------
 
-- Label the nodes
 
UNION ALL SELECT
 
  '"' || id || '" [label="'
 
  -- Line 1: Execution Sequence # and Id
 
  || 'Step ' || execution_sequence#
  || ' (Id ' || id || ')'
  || '\n'
 
  -- Line 2: Operations, options, object name, and starts
 
  || operation
 
  || CASE
       WHEN (options IS NULL)
       THEN ('')
       ELSE (' ' || options)
     END
 
  || CASE
       WHEN (object_name IS NULL)
       THEN ('')
       ELSE (' ' || object_name)
     END
 
  || CASE
       WHEN (last_starts > 1)
       THEN (' (Starts = ' || last_starts || ')')
       ELSE ('')
     END
 
  || '\n'
 
  -- Line 3: Delta elapsed time and cumulative elapsed time
 
  || 'Delta Elapsed = '
  || CASE
       WHEN (delta_elapsed_time IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(delta_elapsed_time, '999,999,990.00')) || 's')
     END
 
  || ' ('
  || CASE
       WHEN (delta_percentage_elapsed_time IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(delta_percentage_elapsed_time, '990')) || '%')
     END
  || ')'
 
  || ' Cum Elapsed = '
  || CASE
       WHEN (last_elapsed_time IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(last_elapsed_time, '999,999,990.00')) || 's')
     END
 
  || ' ('
  || CASE
       WHEN (last_percentage_elapsed_time IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(last_percentage_elapsed_time, '990')) || '%')
     END
  || ')'
 
  || '\n'
 
  -- Line 4: Delta buffer gets and cumulative buffer gets
 
  || 'Delta Buffer Gets = '
  || CASE
       WHEN (delta_buffer_gets IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(delta_buffer_gets, '999,999,999,999,990')))
     END
 
  || ' ('
  || CASE
       WHEN (delta_percentage_buffer_gets IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(delta_percentage_buffer_gets, '990')) || '%')
     END
  || ')'
 
  || ' Cum Buffer Gets = '
  || CASE
       WHEN (last_buffer_gets IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(last_buffer_gets, '999,999,999,999,990')))
     END
 
  || ' ('
  || CASE
       WHEN (last_percentage_buffer_gets IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(last_percentage_buffer_gets, '990')) || '%')
     END
  || ')'
 
  || '\n'
 
  -- Line 5: Delta disk reads and cumulative disk reads
 
  || 'Delta Disk Reads = '
  || CASE
       WHEN (delta_disk_reads IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(delta_disk_reads, '999,999,999,999,990')))
     END
 
  || ' ('
  || CASE
       WHEN (delta_percentage_disk_reads IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(delta_percentage_disk_reads, '990')) || '%')
     END
  || ')'
 
  || ' Cum Disk Reads = '
  || CASE
       WHEN (last_disk_reads IS NULL)
       THEN ('?')
       ELSE (TRIM(TO_CHAR(last_disk_reads, '999,999,999,999,990')))
      END
 
  || ' ('
  || CASE
       WHEN (last_percentage_disk_reads IS NULL)
        THEN ('?')
       ELSE (TRIM(TO_CHAR(last_percentage_disk_reads, '990')) || '%')
     END
  || ')'
 
  || '\n'
 
  -- Line 6: Estimated rows and actual rows
 
  || 'Estimated Rows = '
  || CASE
       WHEN (cardinality IS NULL)
       THEN '?'
       ELSE (TRIM(TO_CHAR(cardinality, '999,999,999,999,990')))
     END
 
  || ' Actual Rows = '
  || CASE
       WHEN (last_output_rows IS NULL)
       THEN '?'
       ELSE (TRIM(TO_CHAR(last_output_rows, '999,999,999,999,990')))
     END
 
  || '\n'
 
  || '", shape=plaintext];' AS command
 
FROM enhanced_plan_table
 
--------------------------------------------------------------------------------
 
-- Connect the nodes
 
UNION ALL SELECT '"' || parent_id || '"->"' || id || '" [dir=back];' AS command
FROM plan_table
START WITH parent_id = 0
CONNECT BY parent_id = PRIOR id
 
--------------------------------------------------------------------------------
 
-- End THE Graphviz program
 
UNION ALL SELECT '}' AS command
FROM DUAL;
 
--------------------------------------------------------------------------------
 
SPOOL off