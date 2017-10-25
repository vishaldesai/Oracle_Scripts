store set sqlplus_settings.bak replace

accept key      prompt 'Please enter the value for Key if known       : '
accept sid      prompt 'Please enter the value for Sid if known       : '
accept sqlid   prompt 'Please enter the value for sql_id if known    : '

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
  and sql_id = nvl('&sqlid',sql_id)
  and sql_text is not null
order by sql_exec_start desc;

set heading off
set pages 0

accept inst_id1        prompt 'Enter instance number		  :'
accept sql_exec_id1    prompt 'Enter sql_exec_id              :'
accept sql_exec_start1 prompt 'Enter sql_exec_start           :'
 
DEF _dbenv="--"
COL oraenv NOPRINT NEW_VALUE _dbenv
COL tmenv  NOPRINT NEW_VALUE tmenvs
SET TERMOUT OFF
--SELECT  '&sql_id' || ' on instance ' || &&inst || '@' || host_name oraenv 
SELECT  '&sqlid' || ' on instance ' || &&inst || '@' || d.name   oraenv 
FROM v$instance i, v$database d;

select to_char(sysdate,'MMDDYY_HH24MMSS') tmenv
FROM dual;

SET TERMOUT ON

SET TERM OFF HEA OFF LIN 32767 NEWP NONE PAGES 0 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;
PRO

SPO logs\getplan_realsqlmonitor_tree_&tmenvs..html;
PRO <html>
PRO <head>
PRO <title>Plan Tree</title>
PRO <style type="text/css">
PRO body          {font:10pt Arial,Helvetica,Geneva,sans-serif; color:black; background:white;}
PRO h1            {font-size:16pt; font-weight:bold; color:#336699; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;}
PRO h2            {font-size:14pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO h3            {font-size:12pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO pre           {font:8pt monospace;Monaco,"Courier New",Courier;}
PRO a             {color:#663300;}
PRO table         {font-size:8pt; border_collapse:collapse; empty-cells:show; white-space:nowrap; border:1px solid #cccc99;}
PRO li            {font-size:8pt; color:black; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO th            {font-weight:bold; color:white; background:#0066CC; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO tr            {color:black; background:#fcfcf0;}
PRO tr.main       {color:black; background:#fcfcf0;}
PRO td            {vertical-align:top; border:1px solid #cccc99;}
PRO td.c          {text-align:center;}
PRO font.n        {font-size:8pt; font-style:italic; color:#336699;}
PRO font.f        {font-size:8pt; color:#999999; border-top:1px solid #cccc99; margin-top:30pt;}
PRO </style>
PRO <script type="text/javascript" src="https://www.google.com/jsapi"></script>
PRO <script type="text/javascript">
PRO google.load("visualization", "1", {packages:["orgchart"]})
PRO google.setOnLoadCallback(drawChart)
PRO function drawChart() {
PRO var data = google.visualization.arrayToDataTable([
PRO ['Step', 'Parent Step','Tooltip' ]


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
    sql_id             = '&sqlid'
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
		--max(plan_operation || ' ' ||  plan_options)				 plan_operation,
		max(plan_operation)										 plan_operation,
		max(plan_options)										 plan_options,
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
    sql_id             = '&sqlid'
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
	plan_table.plan_options,
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
-- Label the nodes
SELECT
	',[{v: '''||plan_line_id||''',f: '''||plan_operation||' '||plan_options||'<br>'||plan_object_name||
	'<br>' || '                  '  ||
	'<div style="color:brown; font-style:italic">' || 'Plan Cardinality :'   || plan_cardinality 			|| '</div>' ||
	'<div style="color:brown; font-style:italic">' || 'Output Rows      :'   || output_rows 				|| '</div>' ||
	'<div style="color:brown; font-style:italic">' || 'Starts           :'   || starts 					 || '</div>' ||
	'<div style="color:blue; font-style:italic">' || 'Phy Read Reqs    :'   || physical_read_requests 	 || '</div>' ||
	'<div style="color:blue; font-style:italic">' || 'Phy Read Bytes   :'   || physical_read_bytes    	 || '</div>' ||
	'<div style="color:blue; font-style:italic">' || 'Phy Write Reqs   :'   || physical_write_requests 	 || '</div>' ||
	'<div style="color:blue; font-style:italic">' || 'Phy Write Bytes  :'   || physical_write_bytes      || '</div>' ||
	'<div style="color:' || decode(elapsed_ind,1,'red;',0,'green;') || ' font-style:italic">' || 'Timeline(s)  :'       || duration                  || '</div>' ||
	'<div style="color:green; font-style:italic">' || 'First Active(s)   :'   || first_active            || '</div>' ||
	'''}' || ','
	|| '''' || plan_parent_id || '''' || ',' 
	|| '''' || 'Step ID: ' || plan_line_id            			
	        --|| ' <br> '
	        --|| 'Plan Cardinality' || plan_cardinality 			|| ' <br> '
			--|| 'Output Rows'      || output_rows      			|| ' <br> '
			--|| 'Phy Read Reqs'    || physical_read_requests		|| ' <br> '
			--|| 'Phy Read Bytes'	|| physical_read_bytes		    || ' <br> '
			--|| 'Phy Write Reqs'	|| physical_write_requests      || ' <br> '
			--|| 'Phy Write Bytes'  || physical_write_bytes		    || ' <br> '
	|| ''''
	|| ']'
FROM enhanced_plan_table
ORDER BY plan_line_id
;

/*
SELECT
	',[{v: '''||plan_line_id||''',f: '''||plan_operation||' '||plan_options||'<br>'||plan_object_name||'''}' || ','
	|| '''' || plan_parent_id || '''' || ',' 
	|| '''' || 'Step ID: ' || plan_line_id || '''' 
	|| ']'
FROM enhanced_plan_table
ORDER BY plan_line_id
;
*/

 
PRO ]);
PRO var options = {
PRO backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1},
PRO title: 'Plan Tree',
PRO titleTextStyle: {fontSize: 16, bold: false},
PRO legend: {position: 'none'},
PRO allowHtml:true, allowCollapse:true,
PRO tooltip: {textStyle: {fontSize: 14}}
PRO }

PRO var chart = new google.visualization.OrgChart(document.getElementById('orgchart'))
PRO chart.draw(data, options)
PRO }
PRO </script>
PRO </head>
PRO <body>
PRO <h1>Plan Tree from v$sql_monitor for &sqlid</h1>

PRO <br>
PRO <div id="orgchart"></div>
PRO <pre>
--L
PRO </pre>
PRO <br>
PRO <font class="f">&&report_foot_note.</font>
PRO </body>
PRO </html>
SPO OFF;

@sqlplus_settings.bak

host start chrome C:\Users\U267399\Desktop\Tools\scripts\logs\getplan_realsqlmonitor_tree_&tmenvs..html