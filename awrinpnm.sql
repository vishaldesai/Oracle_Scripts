Rem
Rem $Header: awrinpnm.sql 05-jan-2005.14:23:20 adagarwa Exp $
Rem
Rem awrinpnm.sql
Rem
Rem Copyright (c) 2004, 2005, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      awrinpnm.sql - AWR INput NaMe
Rem
Rem    DESCRIPTION
Rem      SQL*Plus command file to query the user for the name of the
Rem      report file to be generated. The script generates a default
Rem      name based on the instance number, begin snap id, end snap id
Rem      and the type of report to be generated (text or html). This
Rem      code is used for the SWRF reports, SQL Reports and ADDM reports.
Rem
Rem    NOTES
Rem      This script could leave a few other SQL*Plus substitution and/or
Rem      bind variables defined at the end.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    adagarwa    01/05/05 - adagarwa_awr_sql_rpt
Rem    adagarwa    11/22/04 - Created
Rem

clear break compute;
repfooter off;
ttitle off;
btitle off;

set heading on;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 60 linesize 80 newpage 1 recsep off;
set trimspool on trimout on define "&" concat "." serveroutput on;
set underline on;

-- Script Parameters:
--   First Param (&1) : file prefix e.g. 'awrrpt_'
--   Second Param (&2) : file extension e.g. '.html', '.lst'
--     **** IMPORTANT - the second parameter must be non-null, or else SQL plus
--          adds an awkward prompt when we try to use it

-- After executing, this module leaves the substitution variable
-- &report_name defined.  Issue the command spool &report_name to
-- spool your report to a file, and then undefine report_name when you're
-- done with it.

--
-- Use report name if specified, otherwise prompt user for output file
-- name (specify default), then begin spooling
--
set termout off;
column dflt_name new_value dflt_name noprint;
select '&&1'||:inst_num||'_'||:bid||'_'||:eid||'&&2' dflt_name from dual;
set termout on;

prompt
prompt Specify the Report Name
prompt ~~~~~~~~~~~~~~~~~~~~~~~
prompt The default report file name is &dflt_name..  To use this name,
prompt press <return> to continue, otherwise enter an alternative.
prompt

set heading off;
column report_name new_value report_name noprint;
select 'Using the report name ' || nvl('&&report_name','&dflt_name')
     , nvl('&&report_name','&dflt_name') report_name
  from sys.dual;

set heading off;
set pagesize 50000;
set echo off;
set feedback off;

undefine dflt_name

undefine 1
undefine 2

