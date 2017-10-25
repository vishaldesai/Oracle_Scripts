Rem
Rem $Header: awrrpti.sql 11-apr-2005.19:28:21 mlfeng Exp $
Rem
Rem awrrpti.sql
Rem
Rem Copyright (c) 2001, 2005, Oracle. All rights reserved.
Rem
Rem    NAME
Rem      awrrpti.sql - Workload Repository Report Instance
Rem
Rem    DESCRIPTION
Rem      SQL*Plus command file to report on differences between
Rem      values recorded in two snapshots.
Rem
Rem      This script requests the user for the dbid and instance number
Rem      of the instance to report on, before producing the standard
Rem      Workload Repository report.
Rem
Rem    NOTES
Rem      Run as SYSDBA.  Generally this script should be invoked by awrrpt,
Rem      unless you want to pick a database other than the default.
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      without executing the script through awrrpt, then
Rem      do something similar to the following:
Rem
Rem      define  inst_num     = 1;
Rem      define  num_days     = 3;
Rem      define  inst_name    = 'Instance';
Rem      define  db_name      = 'Database';
Rem      define  dbid         = 4;
Rem      define  begin_snap   = 10;
Rem      define  end_snap     = 11;
Rem      define  report_type  = 'text';
Rem      define  report_name  = /tmp/swrf_report_10_11.txt
Rem      @@?/rdbms/admin/awrrpti
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    mlfeng      04/11/05 - move the warning for timed_statistics into the
Rem                           procedure
Rem    pbelknap    08/04/04 - make awr html types bigger
Rem    mlfeng      05/17/04 - default to prompt users for num_days
Rem    pbelknap    12/11/03 - spelling fix
Rem    pbelknap    10/28/03 - changing swrf to awr
Rem    pbelknap    10/24/03 - swrfrpt to awrrpt
Rem    pbelknap    10/14/03 - moving params to rpti
Rem    pbelknap    10/06/03 - changing final comment
Rem    pbelknap    10/02/03 - changing swrfinput to awrinput
Rem    pbelknap    10/02/03 - adding non-interactive mode cmnts
Rem    pbelknap    10/02/03 - adding filename echo at end of report
Rem    veeve       10/01/03 - moved back some SWRF specific variables
Rem    pbelknap    10/01/03 - unifying parameter code into input module
Rem    pbelknap    09/25/03 - removing spaces from top of report
Rem    pbelknap    09/22/03 - changing call to swrf_report for html table upd
Rem    pbelknap    09/10/03 - updating since HTML moved to prvtswrf, new
Rem                           swrf_report proto
Rem    mlfeng      09/04/03 - parameter# -> parameter_hash
Rem    mlfeng      08/11/03 - add options
Rem    mlfeng      08/04/03 - add instance number to default report name
Rem    mlfeng      07/23/03 - bind var logic
Rem    mlfeng      06/28/03 - convert to PL/SQL interface
Rem    mlfeng      06/05/03 - sqltext fix
Rem    mlfeng      05/16/03 - convert hash to sql_id
Rem    aime        04/25/03 - aime_going_to_main
Rem    mlfeng      03/04/03 - Changing column format to prevent overflow
Rem    mlfeng      02/13/03 - change event logic to include event class
Rem    mlfeng      01/27/03 - mlfeng_swrf_reporting
Rem    mlfeng      01/16/03 - Adding top SQL and top Segment reporting logic
Rem                           to use statistics deltas.
Rem    mlfeng      01/13/03 - Update reporting for SWRF
Rem    mlfeng      07/08/02 - swrf flushing
Rem    mlfeng      06/12/02 - Created
Rem

set echo off;

-- ***************************************************
--   Customer-customizable report settings
--   Change these variables to run a report on different statistics
-- ***************************************************
-- The default number of days of snapshots to list when displaying the
-- list of snapshots to choose the begin and end snapshot Ids from.
--
--   List all snapshots
-- define num_days = '';
--
--   List no (i.e. 0) snapshots
-- define num_days = 0;
--
-- List past 3 day's snapshots
-- define num_days = 3;
--
-- Reports can be printed in text or html, and you must set the report_type
-- in addition to the report_name
--
-- Issue Report in Text Format
--define report_type='text';
--
-- Issue Report in HTML Format
--define report_type='html';

-- Optionally, set the snapshots for the report.  If you do not set them,
-- you will be prompted for the values.
--define begin_snap = 545;
--define end_snap   = 546;

-- Optionally, set the name for the report itself
--define report_name = 'awrrpt_1_545_546.html'

-- ***************************************************
--   End customer-customizable settings
-- ***************************************************


-- *******************************************************
--  The report_options variable will be the options for
--  the AWR report.
--
--  Currently, only one option is available.
--
--  NO_OPTIONS -
--    No options. Setting this will not show the ADDM
--    specific portions of the report.
--    This is the default setting.
--
--  ENABLE_ADDM -
--    Show the ADDM specific portions of the report.
--    These sections include the Buffer Pool Advice,
--    Shared Pool Advice, PGA Target Advice, and
--    Wait Class sections.
--

set veri off;
set feedback off;

variable rpt_options number;

-- option settings
define NO_OPTIONS   = 0;
define ENABLE_ADDM  = 8;

-- set the report_options. To see the ADDM sections,
-- set the rpt_options to the ENABLE_ADDM constant.
begin
  :rpt_options := &NO_OPTIONS;
end;
/

--
-- Find out if we are going to print report to html or to text
prompt
prompt Specify the Report Type
prompt ~~~~~~~~~~~~~~~~~~~~~~~
prompt Would you like an HTML report, or a plain text report?
prompt Enter 'html' for an HTML report, or 'text' for plain text
prompt  Defaults to 'html'

column report_type new_value report_type;
set heading off;
select 'Type Specified: ',lower(nvl('&&report_type','html')) report_type from dual;
set heading on;

set termout off;
-- Set the extension based on the report_type
column ext new_value ext;
select '.html' ext from dual where lower('&&report_type') <> 'text';
select '.txt' ext from dual where lower('&&report_type') = 'text';
set termout on;

-- Get the common input!
-- awrinput will set up the bind variables we need to call the PL/SQL procedure
@@awrinput.sql
-- Get the name of the report.
@@awrinpnm.sql 'awrrpt_' &&ext

set termout off;
-- set report function name and line size
column fn_name new_value fn_name noprint;
select 'awr_report_text' fn_name from dual where lower('&report_type') = 'text';
select 'awr_report_html' fn_name from dual where lower('&report_type') <> 'text';

column lnsz new_value lnsz noprint;
select '80' lnsz from dual where lower('&report_type') = 'text';
select '1500' lnsz from dual where lower('&report_type') <> 'text';

set linesize &lnsz;
set termout on;
spool &report_name;

-- call the table function to generate the report
select output from table(dbms_workload_repository.&fn_name( :dbid,
                                                            :inst_num,
                                                            :bid, :eid,
                                                            :rpt_options ));

spool off;

prompt Report written to &report_name.

set termout off;
clear columns sql;
ttitle off;
btitle off;
repfooter off;
set linesize 78 termout on feedback 6 heading on;
-- Undefine report name (created in awrinput.sql)
undefine report_name

undefine report_type
undefine ext
undefine fn_name
undefine lnsz

undefine NO_OPTIONS
undefine ENABLE_ADDM

undefine top_n_events
undefine num_days
undefine top_n_sql
undefine top_pct_sql
undefine sh_mem_threshold
undefine top_n_segstat

whenever sqlerror continue;
--
--  End of script file;
