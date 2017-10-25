store set sqlplus_settings.bak replace

-- Help URL http://jsfiddle.net/asgallant/GTpgA/11/

accept inst             default 0                   prompt 'Enter instance number (0 or 1,2,3..)	: '
accept sql_id           default "as300f5d2wx0k"     prompt 'Enter sql id				: '
--accept sql_id           default "6qsu5us7yzurp"     prompt 'Enter sql id			: '
accept days_history     default 30				    prompt 'Enter number of days			: '
accept interval_hours   default 24					prompt 'Enter interval in hours (1,2...)	: '

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
DEF report_title = "&_dbenv";
DEF report_abstract_1 = "";
DEF report_abstract_2 = "";
DEF report_abstract_3 = "";
DEF report_abstract_4 = "";
DEF chart_title = "";
DEF xaxis_title = "Date";
DEF vaxis_title = "Time(s)";
--DEF vaxis_title = "";
--DEF vaxis_title = "&sql_id";
--DEF vaxis_baseline = ", baseline:10";
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
--DEF chart_foot_note_2 = "<br>2) Some other note.";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "";
PRO
SPO logs\awr_sqlid_perf_trend_gline_&tmenvs..html;

PRO <html>
PRO <head>
PRO <title>awr_sqlid_perf_trend_gline.html</title>
PRO
PRO <style type="text/css">
PRO body   {font:10pt Arial,Helvetica,Geneva,sans-serif; color:black; background:white;}
PRO h1     {font-size:16pt; font-weight:bold; color:#336699; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;}
PRO h2     {font-size:14pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO h3     {font-size:12pt; font-weight:bold; color:#336699; margin-top:4pt; margin-bottom:0pt;}
PRO pre    {font:8pt monospace;Monaco,"Courier New",Courier;}
PRO a      {color:#663300;}
PRO table  {font-size:8pt; border_collapse:collapse; empty-cells:show; white-space:nowrap; border:1px solid #cccc99;}
PRO li     {font-size:8pt; color:black; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO th     {font-weight:bold; color:white; background:#0066CC; padding-left:4px; padding-right:4px; padding-bottom:2px;}
PRO td     {color:black; background:#fcfcf0; vertical-align:top; border:1px solid #cccc99;}
PRO td.c   {text-align:center;}
PRO font.n {font-size:8pt; font-style:italic; color:#336699;}
PRO font.f {font-size:8pt; color:#999999; border-top:1px solid #cccc99; margin-top:30pt;}
PRO </style>
PRO
PRO <script type="text/javascript" src="https://www.google.com/jsapi"></script>
PRO <script type="text/javascript">
PRO google.load("visualization", "1", {packages:["corechart"]})
PRO google.setOnLoadCallback(drawChart)
PRO
PRO function drawChart() {
PRO var data = google.visualization.arrayToDataTable([
/* add below more columns if needed (modify 3 places) */
PRO ['Date Column', 'CPU', { role: "style" } ,'IO' , { role: "style" } ,'CLUSTER', { role: "style" } ,'APPLICATION', { role: "style" } ,'CONCURRENCY', { role: "style" } ,'PLSQL', { role: "style" } ,'JAVA', { role: "style" }, 'EXECUTIONS', {role: "style" } ]
/****************************************************************************************/
select 
    --hss.instance_number inst,
	', [new Date(' || 
           to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'YYYY') || /* year */
	',' || to_char(to_number(to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'MM'))-1) || /* month */
	',' || to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'DD') || /* day */
	',' || to_char(trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24,'HH24') || /* hour */
	')' ||
    ','||  round(sum(hss.cpu_time_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3)        || ',"Green"' ||
    ','||  round(sum(hss.iowait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3)          || ',"Blue"'  ||
    ','||  round(sum(hss.clwait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3)          || ',"Gray"' ||
    ','||  round(sum(hss.apwait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3)          || ',"Maroon"' ||
    ','||  round(sum(hss.ccwait_delta)/1000000/decode(sum(hss.executions_delta),0,1,sum(hss.executions_delta)),3)          || ',"Brown"' ||
    ','||  round(sum(hss.plsexec_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3) || ',"Purple"' ||
    ','|| round(sum(hss.javexec_time_delta)/1000000/decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)),3)  || ',"Pink"' || 
	','|| decode(sum(hss.executions_delta),0,null,sum(hss.executions_delta)) || ',"Black"' ||  ']'
from dba_hist_sqlstat hss, dba_hist_snapshot hs
where hss.sql_id in ('&sql_id')
    and hss.snap_id=hs.snap_id
    and hss.instance_number=hs.instance_number
	and hs.instance_number = decode(&&inst,0,hs.instance_number,&&inst)
    and hs.end_interval_time>=trunc(sysdate)-&days_history+1
group by trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24
order by trunc(sysdate-&days_history+1)+trunc((cast(hs.end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_hours))*(&interval_hours)/24;
/****************************************************************************************/
PRO ]);
PRO
PRO var countVAxis = 9;
PRO var options = {
PRO backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1},
PRO explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.1},
PRO title: '&&chart_title.',
--PRO titleTextStyle: {fontSize: 16, bold: false},
--PRO focusTarget: 'category',
--PRO legend: {position: 'right', textStyle: {fontSize: 12}},
PRO tooltip: {textStyle: {fontSize: 14}},
PRO hAxis: {title: '&&xaxis_title.', gridlines: {count: -1}, slantedTextAngle: 90, format:'MMM d, y'},
--PRO hAxis: {slantedTextAngle: -90},
--PRO vAxis: {title: '&&vaxis_title.' &&vaxis_baseline., gridlines: {count: 0}},
--RO vAxis: {gridlines: {count: -1}}
--PRO width: 1300,
--PRO height: 900,
PRO chartArea: {width: '85%', height: '90%'},
PRO legend: { position: 'top', maxLines: 3 },
PRO bar: { groupWidth: 30 },
PRO colors: ['Green','Blue','Gray','Maroon','Brown','Purple','Pink','Black'],
PRO isStacked: true,
PRO vAxes: { 
PRO            0:{
PRO				  title: "Time(s)",
PRO				  format: '###.###',
PRO               titleTextStyle:  {color: 'black', fontName: '"Arial"', fontSize: '16'}
PRO            },
PRO            1: {
PRO				  title: "Executions",
PRO               titleTextStyle:  {color: 'black', fontName: '"Arial"', fontSize: '16'}
PRO            }
PRO        }, 
PRO        seriesType: "bars",
PRO        series: {
PRO            7: {
PRO                type: "line",
PRO                targetAxisIndex: 1 // use the right vAxis
PRO            }
PRO        }
PRO }
PRO
PRO var chart = new google.visualization.ColumnChart(document.getElementById('chart_div'))
PRO chart.draw(data, options)
PRO }
PRO </script>
PRO </head>
PRO <body>
PRO <h1>&&report_title.</h1>
PRO &&report_abstract_1.
PRO &&report_abstract_2.
PRO &&report_abstract_3.
PRO &&report_abstract_4.
PRO <div id="chart_div" style="width: 1200px; height: 850px;"></div>
PRO <font class="n">Notes:</font>
PRO <font class="n">&&chart_foot_note_1.</font>
PRO <font class="n">&&chart_foot_note_2.</font>
PRO <font class="n">&&chart_foot_note_3.</font>
PRO <font class="n">&&chart_foot_note_4.</font>
PRO <pre>
--L
PRO </pre>
PRO <br>
PRO <font class="f">&&report_foot_note.</font>
PRO </body>
PRO </html>
SPO OFF;
SET HEA ON LIN 80 NEWP 1 PAGES 14 FEED ON ECHO OFF VER ON LONG 80 LONGC 80 WRA ON TRIMS OFF TRIM OFF TI OFF TIMI OFF ARRAY 15 NUM 10 NUMF "" SQLBL OFF BLO ON RECSEP WR;

@sqlplus_settings.bak

host start chrome C:\Users\U267399\Desktop\Tools\scripts\logs\awr_sqlid_perf_trend_gline_&tmenvs..html
