store set sqlplus_settings.bak replace

accept sqlid   prompt 'Enter the value for sql_id if known    : '
accept phv	   prompt 'Enter value for plan hash value        :'

 
DEF _dbenv="--"
COL oraenv NOPRINT NEW_VALUE _dbenv
COL tmenv  NOPRINT NEW_VALUE tmenvs
SET TERMOUT OFF
--SELECT  '&sql_id' || ' on instance ' || &&inst || '@' || host_name oraenv 
SELECT  '&sql_id' || ' on instance ' || &&inst || '@' || d.name   oraenv 
FROM v$instance i, v$database d;

select to_char(sysdate,'MMDDYY_HH24MMSS') tmenv
FROM dual;

SET TERMOUT ON

SET TERM OFF HEA OFF LIN 32767 NEWP NONE PAGES 0 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;
PRO

SPO logs\getplan_awr_tree_&tmenvs..html;
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

SELECT
	',[{v: '''||id||''',f: '''||operation||' '||options||'<br>'||object_name||
	'''}' || ','
	|| '''' || parent_id || '''' || ',' 
	|| '''' || 'Step ID: ' || id            			
	|| ''''
	|| ']'
FROM dba_hist_sql_plan
WHERE plan_hash_value =  &phv
AND sql_id = '&sqlid'
order by id
;

 
PRO ]);
PRO var options = {
PRO backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1},
PRO title: 'Plan Tree',
PRO titleTextStyle: {fontSize: 16, bold: false},
PRO legend: {position: 'none'},
PRO allowHtml:true,
PRO tooltip: {textStyle: {fontSize: 14}}
PRO }

PRO var chart = new google.visualization.OrgChart(document.getElementById('orgchart'))
PRO chart.draw(data, options)
PRO }
PRO </script>
PRO </head>
PRO <body>
PRO <h1>Plan Tree for &sqlid from DBA_HIST_SQL_PLAN  </h1>

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

host start chrome C:\Users\U267399\Desktop\Tools\scripts\logs\getplan_awr_tree_&tmenvs..html