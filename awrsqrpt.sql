Rem
Rem $Header: awrsqrpt.sql 05-jan-2005.14:23:21 adagarwa Exp $
Rem
Rem awrsqrpt.sql
Rem
Rem Copyright (c) 2004, 2005, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      awrsqrpt.sql
Rem
Rem    DESCRIPTION
Rem      Script defaults the dbid and instance number to that of
Rem      the current intance connected-to and then calls awrsqrpi.sql
Rem      to produce a Workload report for a particular sql statement.      
Rem
Rem    NOTES
Rem      This report is based on the statspack sql report.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    adagarwa    01/05/05 - adagarwa_awr_sql_rpt
Rem    adagarwa    09/07/04 - Created
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

@@awrsqrpi.sql

undefine num_days;
undefine report_type;
undefine report_name;
undefine begin_snap;
undefine end_snap;
--
-- End of file

