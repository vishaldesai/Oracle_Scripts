store set sqlplus_settings.bak replace

accept inst             prompt 'Enter instance number (1,2,3..)		: '
accept event_name        prompt 'Enter event name			: '
accept days_history     prompt 'Enter number of days			: '
accept interval_minutes prompt 'Enter interval in minutes (60,120...)	: '

DEF _dbenv="--"
COL oraenv NOPRINT NEW_VALUE _dbenv
SET TERMOUT OFF
SELECT  '&event_name' || ' on ' || instance_name || '@' || host_name oraenv 
FROM v$instance;
SET TERMOUT ON

SET TERM OFF HEA OFF LIN 32767 NEWP NONE PAGES 0 FEED OFF ECHO OFF VER OFF LONG 32000 LONGC 2000 WRA ON TRIMS ON TRIM ON TI OFF TIMI OFF ARRAY 100 NUM 20 SQLBL ON BLO . RECSEP OFF;
PRO
DEF report_title = "Avg Wait Time in ms for &_dbenv";
DEF report_abstract_1 = "";
DEF report_abstract_2 = "";
DEF report_abstract_3 = "";
DEF report_abstract_4 = "";
DEF chart_title = "";
DEF xaxis_title = "Date";
--DEF vaxis_title = "";
--DEF vaxis_title = "Avg Wait in ms";
DEF vaxis_title = "Avg Wait time in ms for &event_name";
DEF vaxis_baseline = ", baseline:100";
DEF chart_foot_note_1 = "<br>1) Drag to Zoom, and right click to reset Chart.";
--DEF chart_foot_note_2 = "<br>2) Some other note.";
DEF chart_foot_note_3 = "";
DEF chart_foot_note_4 = "";
DEF report_foot_note = "";
PRO
SPO awr_wait_trend_gline.html;
PRO <html>
PRO <!-- $Header: awr_wait_trend_gline.sql 2014-07-27 carlos.sierra $ -->
PRO <head>
PRO <title>awr_wait_trend_gline.html</title>
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
PRO ['Date Column', '&event_name']
/****************************************************************************************/
WITH
  inter AS
  (
    SELECT
      extract(DAY FROM 24*60*snap_interval) inter_val
    FROM
      dba_hist_wr_control
  )
  ,
  snap AS
  (
    SELECT
      INSTANCE_NUMBER,
      MIN(snap_id) SNAP_ID,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24 END_INTERVAL_TIME
    FROM
      dba_hist_snapshot
    WHERE
      begin_interval_time>=TRUNC(sysdate)- &days_history +1
    AND  instance_number = decode(&inst,0,instance_number,&inst)
    GROUP BY
      instance_number,
    trunc(sysdate-&days_history+1)+trunc((cast(end_interval_time as date)-(trunc(sysdate-&days_history+1)))*24/(&interval_minutes/60))*(&interval_minutes/60)/24
    ORDER BY
      3
  )
  ,
  base_line AS
  (
    SELECT
      snp.instance_number,
      sst.snap_id,
      snp.end_interval_time end_time,
      sst.total_waits,
      sst.time_waited_micro
    FROM
      snap snp,
      DBA_HIST_SYSTEM_EVENT sst
    WHERE
      sst.instance_number = snp.instance_number
    AND sst.snap_id       = snp.snap_id
    AND sst.event_name    = '&event_name'
  )
/****************************************************************************************/
/* no need to modify the date column below, but you may need to add some number columns */
SELECT ', [new Date('||
       --TO_CHAR(b2.end_time-30,'YYYY,MM,DD,HH24') ||
       TO_CHAR(b2.end_time, 'YYYY')|| /* year */
       ','||(TO_NUMBER(TO_CHAR(b2.end_time, 'MM'))-1)|| /* month - 1 */
       ','||TO_CHAR(b2.end_time, 'DD')|| /* day */
       ','||TO_CHAR(b2.end_time, 'HH24')|| /* hour */
       --','||TO_CHAR(q.date_column, 'MI')|| /* minute */
       --','||TO_CHAR(q.date_column, 'SS')|| /* second */
	   ')'||
       ','|| to_number(round((b2.time_waited_micro - b1.time_waited_micro)/(b2.total_waits - b1.total_waits)/1000,1)) || 
       ']'
  FROM 	base_line b1,
		base_line b2,
		inter
WHERE
		b1.instance_number = b2.instance_number
AND 	b1.snap_id + &interval_minutes/inter.inter_val = b2.snap_id
ORDER BY b2.end_time
/
/****************************************************************************************/
PRO ]);
PRO
PRO var options = {
PRO backgroundColor: {fill: '#fcfcf0', stroke: '#336699', strokeWidth: 1},
PRO explorer: {actions: ['dragToZoom', 'rightClickToReset'], maxZoomIn: 0.1},
PRO title: '&&chart_title.',
PRO titleTextStyle: {fontSize: 16, bold: false},
PRO focusTarget: 'category',
PRO legend: {position: 'right', textStyle: {fontSize: 12}},
PRO tooltip: {textStyle: {fontSize: 14}},
PRO hAxis: {title: '&&xaxis_title.', gridlines: {count: -1}},
PRO vAxis: {title: '&&vaxis_title.' &&vaxis_baseline., gridlines: {count: -1}}
PRO }
PRO
PRO var chart = new google.visualization.LineChart(document.getElementById('chart_div'))
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
PRO <div id="chart_div" style="width: 1200px; height: 800px;"></div>
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

host start chrome C:\Users\U267399\Desktop\Tools\scripts\awr_wait_trend_gline.html