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
--SET heading off
SET feedback off
SET verify off
SET time off
SET timing off
SET sqlblanklines on

accept key      prompt 'Please enter the value for Key if known       : '
accept sid      prompt 'Please enter the value for Sid if known       : '
accept sql_id1   prompt 'Please enter the value for sql_id if known    : '



column key format 999999999999999
column username format a10 trunc
column module format a20 trunc
column program format a15 trunc
column sql_exec_start format a20 trunc
column sql_text format a20

set heading on
set pages 999


select inst_id,sid,sql_exec_id,to_char(sql_exec_start,'MM/DD/YY HH24:MI:SS') as sql_exec_start,sql_id,key,status,username,module,program,
substr(sql_text,1,20)  as sql_text
from gv$sql_monitor
where sid = nvl('&sid',sid)
  and key = nvl('&key',key)
  and sql_id = nvl('&sql_id1',sql_id)
  and sql_text is not null
order by sql_exec_start desc;

set heading off
set pages 0



accept inst_id1        prompt 'Enter instance number	: '
accept sql_exec_id1    prompt 'Enter sql_exec_id              :'
accept sql_exec_start1 prompt 'Enter sql_exec_start           :'
--accept key1      prompt 'Please enter Key from above             : '
 
SPOOL plan.dot

--------------------------------------------------------------------------------
 
-- First retrieve the basic data from V$SQL_PLAN_STATISTICS_ALL.
-- Modify this subquery if you want data from a different source.

WITH plan_table0 AS
( SELECT 
     round(max(elapsed_time)/1000000) elapsed_time,
	 round(max(cpu_time)/1000000) cpu_time
  FROM
    gv$sql_monitor
  WHERE
    sql_id             = '&sql_id1'
    AND sql_exec_id    = '&sql_exec_id1'
	AND to_char(sql_exec_start,'MM/DD/YY HH24:MI:SS') = '&sql_exec_start1'
),
plan_table AS
(
 
  SELECT
	distinct
		plan_line_id,
		max(plan_parent_id)                                      plan_parent_id,
		max(plan_object_owner || '.' || plan_object_name) 		 plan_object_name,
		max(plan_operation || ' ' ||  plan_options)				 plan_operation,
		max(round((FIRST_CHANGE_TIME-SQL_EXEC_START)*3600*24)) 	 first_active,
		max(round((last_change_time-first_change_time)*3600*24)) duration,
		max(plan_cardinality)                                    plan_cardinality,
		sum(starts) 										     starts,
		sum(output_rows) 									     output_rows,
		sum(physical_read_requests)							     physical_read_requests,
		sum(physical_read_bytes)							     physical_read_bytes,
		sum(physical_write_requests)						     physical_write_requests,
		sum(physical_write_bytes)							     physical_write_bytes,
		max(plan_table0.elapsed_time)                            elapsed_time
  FROM
    gv$sql_plan_monitor,
	plan_table0
  WHERE
    sql_id             = '&sql_id1'
    AND sql_exec_id    = '&sql_exec_id1'
	AND to_char(sql_exec_start,'MM/DD/YY HH24:MI:SS') = '&sql_exec_start1'
  GROUP BY
    plan_line_id
  ORDER BY 1,2
),
 
--------------------------------------------------------------------------------
 
-- Determine the order in which steps are actually executed
 
execution_sequence AS
 
(
 
  SELECT
 
    plan_line_id,
    ROWNUM AS execution_sequence#
 
  FROM
 
    plan_table pt1
 
  START WITH
 
    -- Start with the leaf nodes
    NOT EXISTS (
      SELECT *
      FROM plan_table pt2
      WHERE pt2.plan_parent_id = pt1.plan_line_id
    )
 
  CONNECT BY
 
    -- Connect to the parent node
    pt1.plan_line_id = PRIOR pt1.plan_parent_id
    -- if the prior node was the oldest sibling
    AND PRIOR pt1.plan_line_id >= ALL(
      SELECT pt2.plan_line_id
      FROM plan_table pt2
      WHERE pt2.plan_parent_id = pt1.plan_line_id
    )
 
  -- Process the leaf nodes from left to right
  ORDER SIBLINGS BY pt1.plan_line_id
 
),
 
enhanced_plan_table AS
 
(
 
  SELECT
 
    -- Items from the plan_table subquery
 
    plan_table.plan_line_id,
    plan_table.plan_parent_id,
    plan_table.plan_object_name,
    plan_table.plan_operation ,
    plan_table.starts,
    plan_table.plan_cardinality,
    plan_table.output_rows,
	plan_table.physical_read_requests,
	plan_table.physical_read_bytes,
	plan_table.physical_write_requests,
	plan_table.physical_write_bytes,
	plan_table.first_active,
	CASE when plan_table.duration>=(plan_table.elapsed_time*10/100) then
	     1
	ELSE
	     0
	END AS elapsed_ind,
	plan_table.duration,
	CASE when plan_table.output_rows>0 and plan_table.starts>0 and plan_table.plan_cardinality>0 then
	output_rows/starts/plan_cardinality
	ELSE
	0
	END AS c1,
 
    -- Items from the execution_sequence subquery
 
    execution_sequence.execution_sequence#
 

  FROM
 
    plan_table,
    execution_sequence
 
  WHERE
 
    plan_table.plan_line_id = execution_sequence.plan_line_id
 
  -- Order the results for cosmetic purposes
  ORDER BY plan_table.plan_line_id
 
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
 
  '"' || plan_line_id || '" [label="'
 
  -- Line 1: Execution Sequence # and Id
 
  || 'Step ' || execution_sequence#
  || ' (Id ' || plan_line_id || ')'
  || '\n'
 
  -- Line 2: Operations, options, object name, and starts
 
  || plan_operation

  || CASE
       WHEN (plan_object_name IS NULL)
       THEN ('')
       ELSE (' ' || plan_object_name)
     END

  || '\n'
  || 'First Active =' || first_active
  || '\n'
  || 'Duration = ' || duration 
  -- Line 6: Estimated rows and actual rows
  || '\n'
  || 'Estimated Rows = '
  || CASE
       WHEN (plan_cardinality IS NULL)
       THEN '?'
       ELSE (TRIM(TO_CHAR(plan_cardinality, '999,999,999,999,990')))
     END
  || '\n'
  || 'Starts = '
  || starts
  || '\n'
  || ' Actual Rows = '
  || CASE
       WHEN (output_rows IS NULL)
       THEN '?'
       ELSE (TRIM(TO_CHAR(output_rows, '999,999,999,999,990')))
     END
 
  || '\n'
  || 'Physical Reads      :' || physical_read_requests || '\n'
  || 'Physical Read Bytes :' || round(physical_read_bytes/1024/1024) || ' MB \n'
  || 'Physical Writes     :' || physical_write_requests || '\n'
  || 'Physical Write Bytes:' || round(physical_write_bytes/1024/1024) || ' MB \n'
  || '", shape=box,color=' || CASE WHEN (c1 >2 and c1 <=5 ) THEN 'pink'
                                   WHEN (c1 >5)             THEN 'red'
								   ELSE 'blue'
							  END || 
							  CASE WHEN elapsed_ind=1 THEN ',style=filled, fillcolor=grey'
							  END || ' ];' AS command
 
FROM enhanced_plan_table
 
--------------------------------------------------------------------------------
 
-- Connect the nodes
 
UNION ALL SELECT '"' || plan_parent_id || '"->"' || plan_line_id || '" [dir=back];' AS command
FROM plan_table
START WITH plan_parent_id = 0
CONNECT BY plan_parent_id = PRIOR plan_line_id
 
--------------------------------------------------------------------------------
 
-- End THE Graphviz program
 
UNION ALL SELECT '}' AS command
FROM DUAL;
SELECT '                                                                 ' FROM DUAL;
SELECT 'OPEN Graphfiz and copy paste above output to generate Visual Plan' FROM DUAL;
 
--------------------------------------------------------------------------------
 
SPOOL off

edit plan.dot