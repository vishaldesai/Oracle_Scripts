
Rem $Header: awrrpt.sql 24-oct-2003.12:04:53 pbelknap Exp $
Rem
Rem awrrpt.sql
Rem
Rem Copyright (c) 1999, 2003, Oracle Corporation.  All rights reserved.  
Rem
Rem    NAME
Rem      awrrpt.sql
Rem
Rem    DESCRIPTION
Rem      This script defaults the dbid and instance number to that of the
Rem      current instance connected-to, then calls awrrpti.sql to produce
Rem      the Workload Repository report.
Rem
Rem    NOTES
Rem      Run as select_catalog privileges.  
Rem      This report is based on the Statspack report.
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      see the 'customer-customizable report settings' section in
Rem      awrrpti.sql
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    pbelknap    10/24/03 - swrfrpt to awrrpt 
Rem    pbelknap    10/14/03 - moving params to rpti 
Rem    pbelknap    10/02/03 - adding non-interactive mode cmnts 
Rem    mlfeng      09/10/03 - heading on 
Rem    aime        04/25/03 - aime_going_to_main
Rem    mlfeng      01/27/03 - mlfeng_swrf_reporting
Rem    mlfeng      01/13/03 - Update comments
Rem    mlfeng      07/08/02 - swrf flushing
Rem    mlfeng      06/12/02 - Created
Rem

--
-- Get the current database/instance information - this will be used 
-- later in the report along with bid, eid to lookup snapshots

set echo off heading on underline on;
column inst_num  heading "Inst Num"  new_value inst_num  format 99999;
column inst_name heading "Instance"  new_value inst_name format a12;
column db_name   heading "DB Name"   new_value db_name   format a12;
column dbid      heading "DB Id"     new_value dbid      format 9999999999 just c;

prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~

select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v$database d,
       v$instance i;

@@awrrpti

undefine num_days;
undefine report_type;
undefine report_name;
undefine begin_snap;
undefine end_snap;
--
-- End of file





