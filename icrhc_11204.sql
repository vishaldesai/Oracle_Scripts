REM
REM This healthcheck script is for use on Oracle11gR2 (11.2.0.4) databases only.  
REM 
REM
REM This script should be run by  SYS on the instance running the integrated extract, 
REM or the goldengate administrator with full privileges, or a user with DBA role
REM When run as SYS, queries on internal dictionary tables will produce output and summary overview
REM information will be available 
REM
REM  It  is recommended to run with markup html ON (default is on) and generate an HTML file for web viewing.
REM  Please provide the output in HTML format when Oracle (support or development) requests healthcheck output.
REM  To convert output to a text file viewable with a text editor,
REM    change the HTML ON to HTML OFF in the set markup command
REM  Remember to set up a spool file to capture the output
REM

--connect / as sysdba
define hcversion = 'V2.1.25';
set truncate off
set numwidth 15
set markup HTML ON entmap off spool on
alter session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';
alter session set nls_language=american;
set heading off
set feedback off

select 'Oracle GoldenGate Integrated Extract/Replicat Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;
set heading on timing off


prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  



prompt
prompt ====================================================
prompt =====================<a name="Summary"><b>Summary</b></a> ==============================
prompt ====================================================
prompt
prompt
prompt ++ Summary Overview ++
prompt
COL NAME HEADING 'Name'
col platform_name format a30 wrap
col current_scn format 99999999999999999
col host Heading 'Host'
col version heading 'Version'
col startup_time heading 'Startup|Time'
col database_role Heading 'Database|Role'
col DB_Edition heading 'Database|Edition' format a10

SELECT db.DBid,db.name, db.platform_name  ,i.HOST_NAME HOST, i.VERSION,
      DECODE(regexp_substr(v.banner, '[^ ]+', 1, 4),'Edition','Standard',regexp_substr(v.banner, '[^ ]+', 1, 4)) DB_Edition,  
      i.instance_number instance,db.database_role,db.current_scn, db.min_required_capture_change# 
   from v$database db,v$instance i, v$version v
   where banner like 'Oracle%';
prompt


prompt
prompt Summary of GoldenGate Integrated Extracts configured in database  (<a href="#Capture Processes">ConfigDetails</a>  <a href="#Capture Statistics">StatsDetails</a>)
prompt
set lines 180
col extract_name format a12 heading 'Extract|Name'
col capture_name format a20 heading 'Capture|Name'
col capture_type format a10 heading 'Capture|Type'
col real_time_mine format a8 heading 'RealTime|Mine?'
col protocol format a8 heading 'OGG|Capture|Protocol'
col status Heading 'Status'
col state format a50 Heading 'Current|Capture|State'
col capture_user format a12 Heading 'Capture|User'
col inst_id Heading 'Instance'
col version format a12 Heading 'Capture|Version'
col required_checkpoint_scn format 999999999999999999 heading 'Required|Checkpoint|SCN'
col startup_time heading 'Process|Startup|Time'
col mined_MB Heading 'Redo|Mined|MB'   format 99999999.999
col sent_MB Heading 'Sent to|Extract|Mb'   format 99999999.999
col STATE_CHANGED_TIME  Heading 'Last |State Changed|Time'
col Current_time Heading 'Current|Time'
col capture_lag Heading 'Capture|Lag|seconds'
col registered Heading 'Registered'
col last_ddl_time Heading 'Last DDL|Time'

select  SYSDATE Current_time, c.client_name extract_name,c.capture_name, 
   c.capture_user,
   c.capture_type, 
   decode(cp.value,'N','NO', 'YES') Real_time_mine,
   c.version,
   c.required_checkpoint_scn,
   (case 
     when g.sid=g.server_sid and g.serial#=g.server_serial# then 'V2'
     else '<b>V1</b>'
    end) protocol,
   c.logminer_id,
   o.created registered,
   o.last_ddl_time,
   c.status,
   DECODE (g.STATE,'WAITING FOR CLIENT REQUESTS','<b><a href="#Performance Checks">'||g.state||'</a></b>',
                'WAITING FOR INACTIVE DEQUEUERS','<b><a href="#Notification">'||g.state||'</a></b>',
                'WAITING FOR TRANSACTION;WAITING FOR CLIENT','<b><a href="#Performance Checks">'||g.state||'</a></b>',
                g.state) State,
   (SYSDATE- g.capture_message_create_time)*86400 capture_lag,
   g.bytes_of_redo_mined/1024/1024 mined_MB,
   g.bytes_sent/1024/1024 sent_MB,
   g.startup_time,
   g.inst_id
from dba_capture c, dba_objects o,
     gv$goldengate_capture g,
     dba_capture_parameters cp
where
  c.capture_name=g.capture_name
  and c.capture_name=cp.capture_name and cp.parameter='DOWNSTREAM_REAL_TIME_MINE'
  and c.status='ENABLED' 
  and c.capture_name = o.object_name
  and c.capture_name=g.capture_name
union all
select  SYSDATE Current_time,  c.client_name extract_name,c.capture_name,
   c.capture_user,  
   c.capture_type, 
   decode(cp.value, 'N','NO', 'YES') Real_time_mine,
   c.version,
   c.required_checkpoint_scn,
   'Unavailable',
   c.logminer_id,
   o.created registered,
   o.last_ddl_time,
   c.status,
   'Unavailable',
   NULL,
   NULL,
   NULL,
   NULL,
   NULL
from dba_capture c, dba_objects o,
     dba_capture_parameters cp
where
  c.status in ('DISABLED','ABORTED') and c.purpose='GoldenGate Capture'
  and c.capture_name=cp.capture_name and cp.parameter='DOWNSTREAM_REAL_TIME_MINE'
  and c.capture_name = o.object_name
order by extract_name;
prompt
prompt
prompt Integrated Extract key parameters  (<a href="#CapParameters">Details</a>)
prompt
prompt

col parallelism format a20
col max_sga_size format a12
col excludetag format a20
col excludeuser format a20
col getapplops format a10
col getreplicates format a13
col checkpoint_frequency format a20

select cp.capture_name,substr(cp.capture_name,9,8) extract_name,
                  max(case when parameter='PARALLELISM' then value end) parallelism
                 ,max(case when parameter='MAX_SGA_SIZE' then value end) max_sga_size
                 ,max(case when parameter='EXCLUDETAG' then value end) excludetag
                 ,max(case when parameter='EXCLUDEUSER' then value end) excludeuser
                 ,max(case when parameter='GETAPPLOPS' then value end) getapplops
                 ,max(case when parameter='GETREPLICATES' then value end) getreplicates 
                 ,max(case when parameter='_CHECKPOINT_FREQUENCY' then value end) checkpoint_frequency                  
                 from dba_capture_parameters cp, dba_capture c where c.capture_name=cp.capture_name
                  and c.purpose='GoldenGate Capture'
                 group by cp.capture_name;
prompt
prompt Integrated Extract/Logminer session info  (<a href="#LogmnrDetails">Details</a>)
prompt
col session_name Heading 'Capture|Name'
col available_txn Heading 'Available|Chunks'
col delivered_txn Heading 'Delivered|Chunks'
col difference Heading 'Ready to Send|Chunks'
col builder_work_size Heading 'Builder|WorkSize'
col prepared_work_size Heading 'Prepared|WorkSize'
col used_memory_size  Heading 'Used|Memory'
col max_memory_size   Heading 'Max|Memory'
col used_mem_pct Heading 'Used|Memory|Percent'

select session_name, available_txn, delivered_txn,
             available_txn-delivered_txn as difference,
             builder_work_size, prepared_work_size,
            used_memory_size , max_memory_size,
             (used_memory_size/max_memory_size)*100 as used_mem_pct
      FROM gv$logmnr_session order by session_name; 

prompt

prompt
prompt Summary of GoldenGate Integrated Replicats configured in this database(<a href="#Apply Processes">ConfigDetails</a>  <a href="#Apply Statistics">StatsDetails</a>)
prompt
set lines 180
col replicat_name format a8 heading 'Replicat|Name'
col server_name format a20 heading 'Server|Name'
col status Heading 'Status'
col state format a30 Heading 'Current|Coordinator|State'
col rcvstate format a32 Heading 'Current|Receiver|State'
col active_server_count Heading 'Active|Server|Count'
col inst_id Heading 'Instance'
col unassigned_complete_txns Heading 'Unassigned|Complete|Txns'
col apply_user format a12 Heading 'Apply|User'
col startup_time heading 'Process|Startup|Time'
col lwm heading 'Low Watermark|Message|Create Time'
col hwm heading 'High Watermark|Message|Create Time'

select sysdate Current_time, ib.replicat_name replicat_name,ib.server_name, 
   ib.apply_user,
   ib.status,
   o.created registered,
   o.last_ddl_time,
  DECODE (r.STATE,'Waiting for memory','<b><a href="#Memory"> Waiting for memory</a></b>',    
                r.state) rcvstate,
   g.state,
   g.active_server_count,
   g.unassigned_complete_txns,
   g.lwm_message_create_time lwm,
   g.hwm_message_create_time hwm,
   g.startup_time,
   g.inst_id
from dba_goldengate_inbound ib, dba_objects o,
     gv$gg_apply_coordinator g, gv$gg_apply_receiver r
where
  ib.server_name=g.apply_name
  and ib.status='ATTACHED' 
  and ib.server_name = o.object_name
  and ib.server_name = g.apply_name
  and ib.server_name = r.apply_name
union all
select  sysdate Current_time, ib.replicat_name replicat_name,ib.server_name, 
   ib.apply_user,
   ib.status,
   o.created registered,
   o.last_ddl_time,
   'Unavailable',
   null,
   null,
   null,
   null,
   null,
   null,
   null
from dba_goldengate_inbound ib, dba_objects o
where
  ib.status !='ATTACHED' 
  and ib.server_name=o.object_name
order by replicat_name;

prompt
prompt Integrated Replicat key parameters   (<a href="#AppParameters">Details</a>)
prompt
col max_parallelism format a20
col commit_serialization format a20
col optimize_progress_table format a25

select apply_name,substr(apply_name,5,8) replicat_name,
                  max(case when parameter='PARALLELISM' then value end) parallelism
                 ,max(case when parameter='MAX_PARALLELISM' then value end) max_parallelism
                 ,max(case when parameter='COMMIT_SERIALIZATION' then value end) commit_serialization
                 ,max(case when parameter='EAGER_SIZE' then value end) eager_size
                 ,max(case when parameter='_DML_REORDER' then value end) batchsql              
                 ,max(case when parameter='BATCHSQL_MODE' then value end) batch_sql_mode 
                 ,max(case when parameter='MAX_SGA_SIZE' then value end) max_sga_size  
                 ,max(case when parameter='OPTIMIZE_PROGRESS_TABLE' then value end) optimize_progress_table
                 from dba_apply_parameters ap, dba_goldengate_inbound ib where ib.server_name=ap.apply_name
                 group by apply_name;
prompt
prompt  ++ <a name="Bundle">Replication Bundled Patch Information</a> 
prompt

select * from sys.props$ where name = 'REPLICATION_BUNDLE';

set feedback on
set serveroutput on size unlimited
DECLARE

exabp      varchar2(128);
propsvalue varchar2(128);
paramcount number;
bpvalue    varchar2(128);
appname    varchar2(128);
RepBP      varchar2(128);
bp2        varchar2(128);
comments   varchar2(128);
dbpsu      boolean;
exadatapsu boolean;
cursor   reghist is select * from dba_registry_history where namespace='SERVER' and action='APPLY' and  rownum <2 order by action_time desc ;
  bp02_not_installed EXCEPTION;
  PRAGMA
  EXCEPTION_INIT ( bp02_not_installed,-26667);
  no_OGG_apply  EXCEPTION;
  PRAGMA
  EXCEPTION_INIT (no_OGG_apply, -23605);
BEGIN
--   Bundled Patch always starts as BP0   
   bpvalue := 'BP0 - cannot determine if a bundled patch is installed';
   select  'PROPS$ version:  ' || value$ into RepBP from sys.props$ where name = 'REPLICATION_BUNDLE';
   dbms_output.put_line(RepBP );
 
  For rec in reghist  loop

-- dbms_output.put_line('1 record action, namespace, bundle_series, id: '||rec.action||', '|| rec.namespace||', '|| rec.bundle_series||', '|| rec.id);

     IF rec.bundle_series = 'PSU' then
-- DB PSU      
        if (rec.id=2 ) THEN
            bpvalue := 'BP1 replicat only';
        end if;
        if (rec.id=3 ) THEN
            bpvalue := 'BP1';
        end if;
     ELSIF rec.bundle_series='EXA' then
--  EXADATA PSU 
        if (rec.id=5 ) THEN
            bpvalue := 'BP1 replicat only';
        end if;
        if (rec.id=6 ) THEN
            bpvalue := 'BP1 replicat only';
        end if;

        if (rec.id=7 ) THEN
            bpvalue := 'BP1 replicat only';
        end if;

        if (rec.id=8 ) THEN
            bpvalue := 'BP1';
        end if;
     ELSE
       dbms_output.put_line('record action, namespace, bundle_series, id: '||rec.action||', '|| rec.namespace||', '|| rec.bundle_series||', '|| rec.id);
   
     END IF;
    End Loop;

   select count(*) into paramcount from dba_apply_parameters ap, dba_apply a where a.apply_name = ap.apply_name and a.purpose='GoldenGate Apply' and parameter = 'BATCHSQL_MODE' ;
   IF paramcount>0 then
       bpvalue := 'BP2' ;
   ELSE
       select apply_name into appname from dba_apply where purpose ='GoldenGate Apply' and rownum < 2;
       dbms_apply_adm.set_parameter(appname, 'batchsql_mode',null);
       select count(*) into paramcount from dba_apply_parameters ap, dba_apply a where a.apply_name = ap.apply_name and a.purpose='GoldenGate Apply' and parameter = 'BATCHSQL_MODE' ;
       if paramcount>0 then
            bpvalue := 'BP2' ;
       end if;
    END IF;  
   
   
   dbms_output.put_line('Derived bundled patch: ' || bpvalue );
   dbms_output.put_line(' ');
   EXCEPTION WHEN bp02_not_installed then

            dbms_output.put_line('Derived bundled patch: ' || bpvalue );
            dbms_output.put_line('');
--            dbms_output.put_line('+ <b>INFO</b>: 11.2.0.4 OGG/RDBMS Bundled Patch 2 is not installed in this database');

      WHEN NO_DATA_FOUND then
            dbms_output.put_line('Derived bundled patch: ' || bpvalue );
--          dbms_output.put_line('+ <b>INFO</b>: Cannot derive existence of Bundled Patch 2 because there are no OGG Integrated Delivery processes configured');
            dbms_output.put_line('');


      WHEN OTHERS then

            dbms_output.put_line('Derived bundled patch: ' || bpvalue );
            
            dbms_output.put_line('Error encountered: '||SQLCODE ||' ' || SQLERRM);

   end;
/

prompt

prompt
prompt  +++ Outstanding alerts     (<a href="#Alerts">Details</a>)
prompt
set feedback on

select message_type,creation_time,reason, suggested_action,
     module_id,object_type,
     instance_name||' (' ||instance_number||' )' Instance,
     time_suggested
from dba_outstanding_alerts 
   where creation_time >= sysdate -10 and rownum < 11
   order by creation_time desc;
prompt  Count of Capture and Apply processes configured in database by purpose 
prompt

set feedback on

col nmbr heading 'Count'
col type heading 'Process|Type'
select purpose,count(*) nmbr, 'CAPTURE' type from dba_capture group by purpose
union all
select purpose, count(*) nmbr, 'APPLY' type from dba_apply group by purpose 
order by purpose;

prompt
set feedback off

-- note:  this function is vulnerable to SQL injection, please do not copy it
create or replace function get_parameter(
  param_name        IN varchar2,
  param_value       IN OUT varchar2,
  table_name        IN varchar2,
  table_param_name  IN varchar2,
  table_value       IN varchar2
) return boolean is
  statement varchar2(4000);
begin
  -- construct query 
  statement :=  'select ' || table_value || ' from ' || table_name || ' where ' 
                || table_param_name || '=''' || param_name || '''';

  begin
    execute immediate statement into param_value;
  exception when no_data_found then
    -- data is not found, so return FALSE
    return FALSE;
  end;
  -- data found, so return TRUE
  return TRUE;
end get_parameter;
/

create or replace procedure verify_init_parameter( 
  param_name         IN varchar2, 
  expected_value     IN varchar2,
  verbose            IN boolean,
  more_info          IN varchar2 := NULL,
  more_info2         IN varchar2 := NULL,
  at_least           IN boolean := FALSE,
  is_error           IN boolean := FALSE,
  use_like           IN boolean := FALSE,
  -- may not be necessary
  alert_if_not_found IN boolean := TRUE
) 
is
  current_val_num  NUMBER;
  expected_val_num NUMBER;
  current_value    varchar2(512);
  prefix           varchar2(25);
  matches          boolean := FALSE;
  comparison_str   varchar2(20);
begin
  -- Set prefix as warning or error
  if is_error then
    prefix := '+  <b>ERROR:</b>  ';
  else
    prefix := '+  <b>WARNING:</b>  ';
  end if;

  -- Set comparison string
  if at_least then
    comparison_str := ' at least ';
  elsif use_like then
    comparison_str := ' like ';
  else
    comparison_str := ' set to ';
  end if;

  -- Get value
  if get_parameter(param_name, current_value, 'v$parameter', 'name', 'value') = FALSE 
     and alert_if_not_found then
    -- Value isn't set, so output alert
    dbms_output.put_line(prefix || 'The parameter ''' || param_name || ''' should be'
                         || comparison_str || '''' || expected_value 
                         || ''', instead it has been left to its default value.'); 
    if verbose and more_info is not null then
      dbms_output.put_line(more_info);
      if more_info2 is not null then
        dbms_output.put_line(more_info2);
      end if;
    end if;
    dbms_output.put_line('+');
    return;
  end if;

  -- See if the expected value is what is actually set
  if use_like then
    -- Compare with 'like'
    if current_value like '%'||expected_value||'%' then
      matches := TRUE;
    end if;
  elsif at_least then
    -- Do at least
    current_val_num := to_number(current_value);
    expected_val_num := to_number(expected_value);
    if current_val_num >= expected_val_num then
      matches := TRUE;
    end if;
  else
    -- Do normal comparison
    if current_value = expected_value then
      matches := TRUE;
    end if;
  end if;
  
  if matches = FALSE then
    -- The values don't match, so alert
    dbms_output.put_line(prefix || 'The parameter ''' || param_name || ''' should be'
                         || comparison_str || '''' || expected_value 
                         || ''', instead it has the value ''' || current_value || '''.'); 
    if verbose and more_info is not null then
      dbms_output.put_line(more_info);
      if more_info2 is not null then
        dbms_output.put_line(more_info2);
      end if;
    end if;
    dbms_output.put_line('+');
  end if;

end verify_init_parameter;
/


prompt
prompt  ++
prompt  ++  <a name="Notification"><b>Notifications</b></a> ++
prompt  ++

prompt  
set serveroutput on size unlimited
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose                      boolean := TRUE;
  
  row_count number;
  days_old number;
  failed boolean;
  streams_pool_usage number;
  streams_pool_size varchar2(512);

  
 
  cursor locked_admin is select username,account_status from dba_users 
  where
    username in  (select capture_user from dba_capture where purpose like 'GoldenGate%' union select apply_name from dba_apply  where purpose like 'GoldenGate%' union select username from dba_goldengate_privileges)  
    and account_status != 'OPEN'
order by 1;

begin
  --  Check for LOCKED GoldenGate Admin Users
  for rec in locked_admin   loop
    dbms_output.put_line('+  <b>ERROR</b>:  GoldenGate Admin ' || rec.username ||' account is '||rec.account_status );
  end loop;
    dbms_output.put_line('+');

end;
/

prompt
prompt  ++  <a name="CAP Notification"> Extract Notifications</a> ++
prompt  ++
prompt  
set serveroutput on size unlimited
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose                      boolean := TRUE;
 
  -- By default a streams pool usage above 95% will result in output
  streams_pool_usage_threshold number := 95;  
  -- The total number of registered archive logs to have before reporting an error
  registered_logs_threshold    number := 1000;
  -- The total number of days old the oldest archived log should be before reporting an error
  registered_age_threshold     number := 60;  -- days
  log_mode                     varchar2(20);

  row_count number;
  days_old number;
  failed boolean;
  streams_pool_usage number;
  streams_pool_size varchar2(512);

  
  cursor aborted_capture is 
    select capture_name, error_number, error_message from dba_capture where status='ABORTED';
 
    cursor disabled_capture is select capture_name from dba_capture where status='DISABLED' and purpose = 'GoldenGate Capture';
  cursor  unattached_extract is select capture_name, substr(capture_name,9,8) extract_name from gv$goldengate_capture where state='WAITING FOR INACTIVE DEQUEUERS';
  
  cursor classic_capture is select capture_name from dba_capture where capture_name like 'OGG%$%' and purpose='Streams';
--  check if state_changed_time is older than 3 minutes  (approx .00211 * 86400)
  cursor  old_state_time is select capture_name,state,state_changed_time,to_char( (SYSDATE- state_changed_time)*1440,'99990.99') mins from gv$goldengate_capture where (SYSDATE - state_changed_time ) >.00211;
  
  cursor ckpt_retention_time is select capture_name,client_name extract_name,
                                DECODE(checkpoint_retention_time,60,'<b>WARNING</b>: Checkpoint Retention time is set too high (60 days) for extract ',
                                                                  7,'<b>INFO</b>: Checkpoint Retention time set to OGG default of 7 days for extract ',
                                                                    '<b>INFO</b>: Checkpoint Retention time set to '||checkpoint_retention_time||' days by extract ') msg
              from dba_capture  where purpose='GoldenGate Capture';

  cursor cap_param_maxsga is select cp.capture_name, substr(cp.capture_name,9,8) extract_name, value       
                            from dba_capture_parameters cp, dba_capture c where c.capture_name=cp.capture_name and purpose = 'GoldenGate Capture' and cp.parameter = 'MAX_SGA_SIZE';

  

begin
 

  -- Check for aborted capture processes
  for rec in aborted_capture loop
    dbms_output.put_line('+  <b>ERROR</b>:  Capture ''' || rec.capture_name || ''' has aborted with message ' || 
                         rec.error_message);
    dbms_output.put_line('+');
  end loop;


  -- Check for disabled capture processes
  for rec in disabled_capture loop
    dbms_output.put_line('+  <b>WARNING</b>:  Capture ''' || rec.capture_name || ''' is disabled');
  end loop;

  dbms_output.put_line('+');

 
   -- Check for classic capture processes
  for rec in classic_capture loop
    dbms_output.put_line('+  <b>INFO</b>:  Capture ''' || rec.capture_name || ''' is Oracle GoldenGate classic capture with LOGRETENTION enabled');
  end loop;
 dbms_output.put_line('+');

  --- capture is started but extract is not attached
   for rec in unattached_extract loop
       dbms_output.put_line('+  <b>WARNING</b>:  Extract '''||rec.extract_name||''' is not attached to capture '''||rec.capture_name||'''. State is WAITING FOR INACTIVE DEQUEUERS');
       dbms_output.put_line('+  In GGSCI, use this command to start the extract process: START extract '||rec.extract_name);
      dbms_output.put_line('+');
   end loop;
 dbms_output.put_line('+');

 --- capture state has not changed for at least 3 minutes 
   for rec in old_state_time loop
       dbms_output.put_line('+  <b>WARNING</b>:  Capture State for  '||rec.capture_name||' has not changed for over '|| rec.mins||' minutes.');
       dbms_output.put_line('+     Last Capture state change timestamp is '||rec.state_changed_time||' State is '||rec.state);
   end loop;
  dbms_output.put_line('+');



   for rec in ckpt_retention_time loop
       dbms_output.put_line('+ '''||rec.msg||rec.extract_name);
   end loop;
       if verbose then
       dbms_output.put_line('+  You can set this parameter to a lower value by including or modifying the following line in the extract parameter file ');
       dbms_output.put_line('    TRANLOGOPTIONS CHECKPOINTRETENTIONTIME number_of_days  ');
       dbms_output.put_line('+    where number_of_days is the number of days the extract logmining server will retain checkpoints. The default is 7 days');
       end if;
   dbms_output.put_line('+ ');
   
   for rec in cap_param_maxsga loop
        if rec.value = 'INFINITE' then
          dbms_output.put_line('+ <b>WARNING</b>:  Extract '||rec.extract_name||' has not set the memory size parameter for capture '||rec.capture_name);
          dbms_output.put_line('+  Include the following line in the extract parameter file:');
          dbms_output.put_line('TRANLOGOPTIONS INTEGRATEDPARAMS( MAX_SGA_SIZE 1000)');
          dbms_output.put_line('+ ');
        else 
          dbms_output.put_line('+ <b>INFO</b>:  Extract '||rec.extract_name||' memory size  for capture '||rec.capture_name||' is configured as '||rec.value||' Megabytes');
          dbms_output.put_line('+ ');
        end if;
   end loop;
    

  -- Check for too many registered archive logs

    failed := FALSE;
    select count(*) into row_count from dba_registered_archived_log where purgeable = 'NO';
    select (sysdate - min(modified_time)) into days_old from dba_registered_archived_log where purgeable = 'NO';
    if row_count > registered_logs_threshold then 
      failed := TRUE;
      dbms_output.put_line('+  <b>WARNING</b>:  ' || row_count || ' archived logs registered for extracts/captures.');
    end if;
    if days_old > registered_age_threshold then
      failed := TRUE;
      dbms_output.put_line('+  <b>WARNING</b>:  The oldest archived log is ' || round(days_old) || ' days old!');
    end if;
    select count(*) into row_count from dba_registered_archived_log where purgeable = 'YES';
    if row_count > registered_logs_threshold/2 then
      dbms_output.put_line('+  <b>WARNING</b>:  There are '|| row_count ||' archived logs ready to be purged from disk.');
      dbms_output.put_line('+          Use the following select to identify unneeded logfiles:');
      dbms_output.put_line('+          select name from dba_registered_archived_log where purgeable = "YES"  ');
    end if;
    
    if failed then
      dbms_output.put_line('+    A restarting Capture process must mine through each registered archive log.');
      dbms_output.put_line('+    To speedup Capture restart, reduce the amount of disk space taken by the archived');
      dbms_output.put_line('+    logs, and reduce Capture metadata, consider moving the first_scn automatically by  ');
      dbms_output.put_line('+    altering the checkpoint_retention_time capture parameter to a lower value  by including the following line in the extract parameter file ');
      dbms_output.put_line('    TRANLOGOPTIONS CHECKPOINTRETENTIONTIME number_of_days  ');
      dbms_output.put_line('+    where number_of_days is the number of days the extract logmining server will retain checkpoints.');
      dbms_output.put_line('+    For more information, see the Oracle GoldenGate for Windows and UNIX Reference Guide ');
      dbms_output.put_line('+    Note that once the first scn is increased, Capture will no longer be able to mine before');
      dbms_output.put_line('+    this new scn value.');
      dbms_output.put_line('+    Successive moves of the first_scn will remove unneeded registered archive');
      dbms_output.put_line('+    logs only if the files have been removed from disk');
    end if;
      dbms_output.put_line('+ ');
 
 end;
/

prompt
prompt  ++  <a name="APP Notification">Replicat Notifications</a> ++
prompt  
set serveroutput on size unlimited
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose                      boolean := TRUE;
  -- By default any errors in dba_apply_error will result in output
  apply_error_threshold        number := 0;          
  -- By default a streams pool usage above 95% will result in output
  streams_pool_usage_threshold number := 95;  
  -- The total number of registered archive logs to have before reporting an error
  log_mode                     varchar2(20);

  row_count number;
  failed boolean;
  streams_pool_usage number;
  streams_pool_size varchar2(512);

  cursor apply_error is select distinct apply_name from dba_apply_error;
  cursor aborted_apply is 
    select apply_name, error_number, error_message from dba_apply where status='ABORTED' and purpose ='GoldenGate Apply';
 
  cursor disabled_apply is select apply_name from dba_apply where status='DISABLED' and purpose ='GoldenGate Apply';
  
  cursor apply_parameters is select apply_name,substr(apply_name,5,8) replicat_name,
                  max(case when parameter='PARALLELISM' then value end) parallelism
                 ,max(case when parameter='MAX_PARALLELISM' then value end) max_parallelism
                 ,max(case when parameter='COMMIT_SERIALIZATION' then value end) commit_serialization
                 ,max(case when parameter='EAGER_SIZE' then value end) eager_size
                 ,max(case when parameter='_DML_REORDER' then value end) batchsql              
                 ,max(case when parameter='BATCHSQL_MODE' then value end) batchsql_mode 
                 ,max(case when parameter='_BATCHTRANSOPS' then value end) batchtransops
                 ,max(case when parameter='MAX_SGA_SIZE' then value end) max_sga_size  
                 ,max(case when parameter='OPTIMIZE_PROGRESS_TABLE' then value end) optimize_progress_table
                 from dba_apply_parameters ap, dba_goldengate_inbound ib where ib.server_name=ap.apply_name
                 group by apply_name order by apply_name;
 
    

 begin
 

  -- Check for aborted apply processes
  for rec in aborted_apply loop
    dbms_output.put_line('+  <b>ERROR</b>:  Apply ''' || rec.apply_name || ''' has aborted with message ' || 
                         rec.error_message);
    if verbose then
      -- Try to give some suggestions
      -- TODO:  include other errors, suggest how to recover
      if rec.error_number = 26714 then
        dbms_output.put_line('+    This apply aborted because a non-fatal user error has occurred and the ''disable_on_error'' parameter is ''Y''.');
        dbms_output.put_line('+    Please resolve the errors and restart the replicat.');
        dbms_output.put_line('+');
      elsif rec.error_number = 26688 then
        dbms_output.put_line('+    This apply aborted because a column value in a particular change record belonging to a key column was not found. ');
        dbms_output.put_line('+    A column value in a particular change record belonging to a key column was not found. ');
        dbms_output.put_line('+    For more information, search the trace files for ''26688'' and view the relevant trace file.');
        dbms_output.put_line('+    Check that the extract parameter file includes LOGALLSUPCOLS command.');
        dbms_output.put_line('+    Also confirm that OGG 12.1.2 (or above) ADD TRANDATA or ADD SCHEMATRANDATA have been performed at source database.'); 
        dbms_output.put_line('+');
      end if;
    end if;
  end loop;


  -- Check for apply errors in the error queue
  for rec in apply_error loop
    select count(*) into row_count from dba_apply_error where rec.apply_name = apply_name;
    if row_count > apply_error_threshold then
      dbms_output.put_line('+  <b>ERROR</b>:  Apply ''' || rec.apply_name || ''' has placed ' || 
                           row_count || ' transactions in the error queue!  Please check the dba_apply_error view.');
    end if;
  end loop;

  dbms_output.put_line('+');

 

  -- Check for disabled apply processes
  for rec in disabled_apply loop
    dbms_output.put_line('+  <b>WARNING</b>:  Apply ''' || rec.apply_name || ''' is disabled');
  end loop;

  dbms_output.put_line('+');


  for rec in apply_parameters loop
       if rec.max_sga_size <> 'INFINITE' then
        if rec.max_sga_size < 1024 then
          dbms_output.put_line('+  <b>WARNING</b>:     Apply memory from streams pool set to '||rec.max_sga_size||'MB for Integrated Replicat '||rec.replicat_name );
          dbms_output.put_line('+                      Specify at least 1024 MB for MAX_SGA_SIZE when using Integrated Replicat');
        else 
          dbms_output.put_line('+  <b>INFO</b>:     Apply memory from streams pool set to '||rec.max_sga_size||'MB for Integrated Replicat '||rec.replicat_name );
        end if;
      end if;


      if rec.optimize_progress_table = 'Y' then
         select  LOG_MODE into log_mode from v$database;
         if log_mode<>'ARCHIVELOG' then
           dbms_output.put_line('+ <b>WARNING</b>: Progress table maintenance configured via redo has been specified, but database is not in ARCHIVELOG mode for Integrated Replicat '||rec.replicat_name);
           dbms_output.put_line('+          The progress table maintenance will not be performed via redo.  Optimize_progress_table setting is ignored for Integrated Replicat '||rec.replicat_name);
         else         
           dbms_output.put_line('+ <b>INFO</b>:    Progress table maintenance configured via redo for Integrated Replicat '||rec.replicat_name);
         end if;
      end if;
     dbms_output.put_line('+ ');
     
      if rec.parallelism=1 then
        dbms_output.put_line('+  <b>INFO</b>:     Parallelism and autotuning are disabled for Integrated Replicat '||rec.replicat_name);
      end if;
      if rec.parallelism=rec.max_parallelism and rec.parallelism>1 then
        dbms_output.put_line('+  <b>INFO</b>:     Parallelism is enabled but autotuning is disabled for Integrated Replicat '||rec.replicat_name);
      end if;
      if rec.parallelism<>rec.max_parallelism and rec.parallelism>1  then
        dbms_output.put_line('+  <b>INFO</b>:     Both Parallelism and autotuning are enabled for Integrated Replicat '||rec.replicat_name);
      end if;
      if rec.commit_serialization='FULL' then
        dbms_output.put_line('+  <b>INFO</b>:     Apply parallelism restricted to source commit order for Integrated Replicat '||rec.replicat_name);
      end if;
     if rec.batchsql is not null  then
        dbms_output.put_line('+  <b>INFO</b>:     BATCHSQL is enabled for Integrated Replicat '||rec.replicat_name);
        if rec.batchsql_mode is not null then
          dbms_output.put_line('+  <b>INFO</b>:     Batching is '||rec.batchsql_mode);
        end if;
        if rec.batchtransops is null then
          dbms_output.put_line('+  <b>INFO</b>:     Default BATCHTRANSOPS value is 50 for Integrated Replicat '||rec.replicat_name);
          if rec.batchsql_mode <> 'DEPENDENT' then
             dbms_output.put_line('+          Use GoldenGate BATCHTRANSOPS parameter to change this setting.  Tune this parameter down to reduce the amount of WAIT DEPENDENCY  state between apply servers');
          else
             dbms_output.put_line('+          Use GoldenGate BATCHTRANSOPS parameter to change this setting.  Tune this parameter up or down to modify the batch grouping size.');
          end if;
        else 
          dbms_output.put_line('+  <b>INFO</b>:     BATCHTRANSOPS value is set to '||rec.batchtransops||' for Integrated Replicat '||rec.replicat_name);
          if rec.batchsql_mode <> 'DEPENDENT' then
             dbms_output.put_line('+          Use GoldenGate BATCHTRANSOPS parameter to change this setting.  Tune this parameter down to reduce the amount of WAIT DEPENDENCY  state between apply servers');
          else
             dbms_output.put_line('+          Use GoldenGate BATCHTRANSOPS parameter to change this setting.  Tune this parameter up or down to modify the batch grouping size.');
          end if;
        end if;
          
      end if;


  end loop;
end;
/

prompt
prompt  ++
prompt  ++  <a name="SYSCheck"><b>SYS Checks</b></a>
prompt  ++
prompt
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose                      boolean := TRUE;
    -- By default a streams pool usage above 85% will result in output
  streams_pool_usage_threshold number := 85;  
  
  row_count number;
  days_old number;
  failed boolean;
  streams_pool_usage number;
  streams_pool_size varchar2(512);

     cursor unrecovered_queue is select queue_schema,queue_name from x$buffered_queues where flags=1;
     cursor v1_capture is select capname_knstcap, substr(capname_knstcap,9,8) extract_name from x$knstcap x , dba_capture c where bitand(x.flags_knstcap,64) <> 64 and  x.capname_knstcap=c.capture_name and c.purpose = 'GoldenGate Capture' and bitand(flags_knstcap,64) <>64;


begin
--   report v1 capture
  
  for rec in v1_capture loop
     dbms_output.put_line('+ <b>WARNING</b>:  Extract '''||rec.extract_name||''' is using V1 protocol');
       dbms_output.put_line('+           Verify that you are using Oracle GoldenGate release above 11.2.1.0.4.');
       dbms_output.put_line('+         To convert to V2 protocol (the default for newly created extract) do the following:');
       dbms_output.put_line('+         1.  Make sure that all outstanding bounded recovery  (BR) transactions have been applied');
       dbms_output.put_line('+         2.  In GGSCI issue the following command:  Stop extract '||rec.extract_name);
       dbms_output.put_line('+         3.  Add the following line to the parameter file for '||rec.extract_name);
       dbms_output.put_line('             TRANLOGOPTIONS _LCRCAPTUREPROTOCOL V2');
       dbms_output.put_line('+         4.  In GGSCI issue the following command:  Start extract '||rec.extract_name);
       dbms_output.put_line('+');
 
  end loop;



 -- Check high streams pool usage
  begin 
    select FRUSED_KWQBPMT into streams_pool_usage from x$kwqbpmt;
    select value into streams_pool_size from v$parameter where name = 'streams_pool_size';
    if streams_pool_usage > streams_pool_usage_threshold then
      dbms_output.put_line('+  <b>WARNING</b>:  Streams pool usage for this instance is ' || streams_pool_usage ||
                           '% of ' || streams_pool_size || ' bytes!');
      dbms_output.put_line('+    If this system is processing a typical workload, and no ' ||
                           'other errors exist, consider increasing the streams pool size.');
    end if;
  exception when others then null;
  end;


  dbms_output.put_line('+');

-- Check unrecovered queues
  
    for rec in unrecovered_queue loop
    dbms_output.put_line('+  <b>ERROR</b>: Queue ''' || rec.queue_schema || '.'||rec.queue_name||' has not been recovered normally ' );
    dbms_output.put_line('+         Force recovery by altering the queue ownership to another instance. ');
    dbms_output.put_line('+         Use the DBMS_AQADM.ALTER_QUEUE_TABLE procedure to specify a different instance.');
  end loop;

  dbms_output.put_line('+');

end;
/


prompt
prompt  ++
prompt  ++ init.ora checks ++
prompt  ++
declare
  -- Change the variable below to FALSE if you just want the warnings and errors, not the advice
  verbose            boolean := TRUE;
  dbvers             number;
  row_count          number;
  num_downstream_cap number;
  capture_procs      number;
  apply_procs        number;
  newline            varchar2(1) := '
';
begin
  -- Error checks first
  
        verify_init_parameter('enable_goldengate_replication', 'TRUE', verbose, 
                        '+    To use Oracle GoldenGate with Oracle Database 11g Release 2 (11.2.0.4), '||  
                        'this parameter should be set to TRUE in the init.ora or spfile','+    This parameter can be set dynamically using: ALTER SYSTEM set enable_goldengate_replication=true;',is_error=>true);
  

 

  
  -- Then warnings

         verify_init_parameter('compatible','11.2.0.4', verbose,
                        '+    To use full features of GoldenGate 12c Integrated Capture (including triggerless DDL), '||  
                        'this parameter should be set to at least 11.2.0.4 at the source database ',
                        use_like => TRUE);


-- explictly check if aq_tm_processes has been manually set to 0.  If so, raise error.
 declare
   mycheck number;
 begin
   select 1 into mycheck from v$parameter where name = 'aq_tm_processes' and value = '0'
     and (ismodified <> 'FALSE' OR isdefault='FALSE');
   if mycheck = 1 then
     dbms_output.put_line('+  <b>ERROR</b>:  The parameter ''aq_tm_processes'' should not be explicitly set to 0!');
     dbms_output.put_line('+          Queue monitoring is disabled for all queues.');
     dbms_output.put_line('+    To resolve this problem, set the value to 1 using:  ALTER SYSTEM SET AQ_TM_PROCESSES=1;  ');
   end if;
   exception when no_data_found then null;
 end;

-- explictly check if aq_tm_processes has been manually set to 10.  If so, raise error.
 declare
   mycheck number;
 begin
   select 1 into mycheck from v$parameter where name = 'aq_tm_processes' and isdefault = 'FALSE'
     and value = '10';
   if mycheck = 1 then
     dbms_output.put_line('+  <b>ERROR</b>:  The parameter ''aq_tm_processes'' should not be explicitly set to 10!');
     dbms_output.put_line('+          With this setting, queue monitoring is disabled for buffered queues.');
     dbms_output.put_line('+    To resolve this problem, set the value to 1 using:  ALTER SYSTEM SET AQ_TM_PROCESSES=1;  ');
   end if;
   exception when no_data_found then null;
 end;

  verify_init_parameter('streams_pool_size', '0', TRUE, 
                        '+    If this parameter is 0 and sga_target is non-zero, then autotuning of the streams pool is implied.'||newline||
                        '+    If the sga_target parameter is set to 0 and streams_pool_size is 0,'|| newline||
                        '+    10% of the shared pool will be used for Streams.' || newline ||
                        '+    If sga_target is 0, the minimum recommendation for streams_pool_size is 200M.'|| newline||
                        '+      Note you must bounce the database if changing the ',
                        '+    value from zero to a nonzero value.  But if simply increasing this' || newline ||
                        '+    value from an already nonzero value, the database need not be bounced.',
                        at_least=> TRUE);
end;
/

prompt
prompt  ++
prompt  ++ <a name="Configuration checks"><b>Configuration checks</b></a> ++
prompt  ++
declare
  current_value varchar2(4000);

  cursor propagation_latency is
  select propagation_name, latency from dba_propagation, dba_queue_schedules 
   where schema = source_queue_owner and qname = source_queue_name and destination = destination_dblink 
     and latency >= 60  and message_delivery_mode = 'BUFFERED';
  cursor multiqueues is
   select c.capture_name capture_name, a.apply_name apply_name, 
          c.queue_owner queue_owner, c.queue_name queue_name
     from dba_capture c, dba_apply a
    where c.queue_name = a.queue_name and c.queue_owner = a.queue_owner
      and c.capture_type != 'DOWNSTREAM' and a.purpose ='STREAMS APPLY' and c.capture_name not like 'CDC$%';

  cursor nonlogged_tables is 
    select table_owner owner,table_name name from dba_capture_prepared_tables t
     where table_owner in
        (select distinct(table_owner) from dba_capture_prepared_tables where 
           supplemental_log_data_pk='NO' and supplemental_log_data_fk='NO' and 
           supplemental_log_data_ui='NO' and
           supplemental_log_data_all='NO'
        minus
          select schema_name from dba_capture_prepared_schemas)
     and not exists
       (select 'X' from dba_log_groups l where t.table_owner = l.owner and t.table_name = l.table_name
       UNION
       select 'x' from dba_capture_prepared_database);


  cursor overlapping_rules is
   select a.streams_name sname, a.streams_type stype, 
          a.rule_set_owner rule_set_owner, a.rule_set_name rule_set_name, 
          a.rule_owner owner1, a.rule_name name1, a.streams_rule_type type1, 
          b.rule_owner owner2, b.rule_name name2, b.streams_rule_type type2
     from dba_streams_rules a, dba_streams_rules b
    where a.rule_set_owner = b.rule_set_owner 
      and a.rule_set_name = b.rule_set_name
      and a.streams_name = b.streams_name and a.streams_type = b.streams_type
      and a.rule_type = b.rule_type
      and (a.subsetting_operation is null or b.subsetting_operation is null)
      and (a.rule_owner != b.rule_owner or a.rule_name != b.rule_name)
      and ((a.streams_rule_type = 'GLOBAL' and b.streams_rule_type 
            in ('SCHEMA', 'TABLE') and a.schema_name = b.schema_name)
       or (a.streams_rule_type = 'SCHEMA' and b.streams_rule_type = 'TABLE' 
           and a.schema_name = b.schema_name)
       or (a.streams_rule_type = 'TABLE' and b.streams_rule_type = 'TABLE' 
           and a.schema_name = b.schema_name and a.object_name = b.object_name
           and a.rule_name < b.rule_name)
       or (a.streams_rule_type = 'SCHEMA' and b.streams_rule_type = 'SCHEMA' 
           and a.schema_name = b.schema_name and a.rule_name < b.rule_name)
       or (a.streams_rule_type = 'GLOBAL' and b.streams_rule_type = 'GLOBAL' 
           and a.rule_name < b.rule_name))
       order by a.rule_name;

  cursor spilled_apply is
  select a.apply_name
    from dba_apply_parameters p, dba_apply a, gv$buffered_queues q
   where a.queue_owner = q.queue_schema and a.queue_name = q.queue_name
     and a.apply_name = p.apply_name and p.parameter = 'PARALLELISM' 
     and p.value > 1 and (q.cspill_msgs/DECODE(q.cnum_msgs, 0, 1, q.cnum_msgs) * 100) > 25;

  cursor bad_source_db is
   select rule_owner||'.'||rule_name Rule_name, source_database from dba_streams_rules where source_database not in 
             (select global_name from system.logmnrc_dbname_uid_map);


  cursor qtab_too_long is
     select queue_table name, length(queue_table) len from dba_queues q , dba_apply a where 
        length(queue_table)>24 and q.owner=a.queue_owner and q.name=a.queue_name;

  cursor reginfo_invalid is
     select comp_id,status from dba_registry where comp_id in ('CATALOG','CATPROC') and status not in ('VALID','UPDATED');

  cursor version_diff is
     select i.version inst_version,r.version reg_version from v$instance i, dba_registry r where 
        r.comp_id  in ('CATALOG','CATPROC') and i.version <> r.version;

  cursor cparallel is
     select p.capture_name, c.client_name  from dba_capture_parameters p, dba_capture c where c.capture_name=p.capture_name and c.purpose = 'GoldenGate Capture' and p.parameter='PARALLELISM' and to_number(p.value)= 0;

  cursor ogg_cap_privs is select distinct capture_user username from dba_capture where purpose = 'GoldenGate Capture'
				minus
			select distinct username from dba_goldengate_privileges where privilege_type in ('*','CAPTURE');

  cursor ogg_app_privs is select distinct apply_user username from dba_goldengate_inbound 
				minus
			select distinct username from dba_goldengate_privileges where privilege_type in ('*','APPLY');

  row_count     number := 0;
  min_count     number;
  max_count     number;
  capture_count number;
  local_capture_count number := 0;
  verbose       boolean := TRUE;
  overlap_rules boolean := FALSE;
  latency       number;
begin
  
  -- Check  Registry Info STATUS
  for rec in reginfo_invalid loop
     dbms_output.put_line('+  <b>ERROR</b>:  The DBA_REGISTRY status information for component '''||rec.comp_id||
      ''' requires attention.  Status is '||rec.status||
                          '. Please recompile the component ');
     dbms_output.put_line('+');
  end loop;                

  -- Check consistent Instance and Registry Info
  for rec in version_diff loop
     dbms_output.put_line('+  <b>ERROR</b>:  The ORACLE_HOME software is '''||rec.inst_version||''' but the database catalog is '||rec.reg_version||
                          '.  CATPATCH must be run successfully to complete the upgrade');
     dbms_output.put_line('+');
  end loop;                

 --  OGG Administrator privilege checks

  for rec in ogg_cap_privs loop
       dbms_output.put_line('+  <b>WARNING</b>:  '''||rec.username||''' has not been granted OGG administrator privileges for CAPTURE');
       dbms_output.put_line('+            To grant appropriate privileges, use  ');
       dbms_output.put_line(' exec dbms_goldengate_auth.grant_admin_privilege('''||rec.username||''',PRIVILEGE_TYPE=>''*'',GRANT_SELECT_PRIVILEGES=>true);');
       dbms_output.put_line('+');
  end loop;

  for rec in ogg_app_privs loop
       dbms_output.put_line('+  <b>WARNING</b>:  '''||rec.username||''' has not been granted OGG administrator privileges for APPLY');
       dbms_output.put_line('+            To grant appropriate privileges, use  ');
       dbms_output.put_line(' exec dbms_goldengate_auth.grant_admin_privilege('''||rec.username||''',PRIVILEGE_TYPE=>''*'',GRANT_SELECT_PRIVILEGES=>true);');
       dbms_output.put_line('+');
  end loop;

  -- Separate queues for capture and apply
  for rec in multiqueues loop
    dbms_output.put_line('+  <b>WARNING</b>:  the Capture process ''' || rec.capture_name ||
                         ''' and Apply process ''' || rec.apply_name || '''');
    dbms_output.put_line('+    share the same queue ''' || rec.queue_owner || '.' 
                         || rec.queue_name || '''.  If the Apply process is receiving changes');
    dbms_output.put_line('+    from a remote site, a separate queue should be created for'
                         || ' the Apply process.');
  end loop;

  dbms_output.put_line('+');

  -- Make sure it is in archivelog mode
   select count(*) into capture_count from (select c.capture_name,cp.value  from dba_capture c, dba_capture_parameters cp where cp.capture_name=c.capture_name and cp.parameter = 'DOWNSTREAM_REAL_TIME_MINE' and cp.value = 'Y');
  select count(*) into row_count from v$database where log_mode = 'NOARCHIVELOG';
  if row_count > 0 and capture_count > 0 then
    dbms_output.put_line('+  <b>ERROR</b>:  ARCHIVELOG mode must be enabled for this database.');
    if verbose then
      dbms_output.put_line('+    For a Capture process to function correctly, it'
                           || ' must be able to read the archive logs.');
      dbms_output.put_line('+    Please refer to the database documentation to restart the database'
                           || ' in ARCHIVELOG format.');
      dbms_output.put_line('+');
    end if;
  end if;


  --  Make sure that downstream capture in real time mode has standby redo logs configured
     select count(*) into capture_count from (select c.capture_name,cp.value  from dba_capture c, dba_capture_parameters cp where cp.capture_name=c.capture_name  and c.capture_type = 'DOWNSTREAM' and cp.parameter = 'DOWNSTREAM_REAL_TIME_MINE' and cp.value = 'Y');
     select count(*),min(bytes), max(bytes) into row_count,min_count,max_count from v$standby_log;
     if row_count>0 and capture_count > 0 then
        dbms_output.put_line('+  <b>INFO</b>: Number of standby redo logs configured is '||row_count);
        if min_count != max_count then
	    dbms_output.put_line('+  <b>INFO</b>: Standby redo logs have different sizes, ranging in bytes from '||min_count||' to '||max_count);
        end if;
      dbms_output.put_line('+');
    end if;

    
  -- Basic supplemental logging checks
  -- #1.  If minimal supplemental logging is not enabled, this is an error
  select count(*) into row_count from v$database where SUPPLEMENTAL_LOG_DATA_MIN = 'NO';
  select count(*) into local_capture_count from dba_capture where capture_type = 'LOCAL';
  if row_count > 0 and local_capture_count > 0 then
    dbms_output.put_line('+  <b>ERROR</b>:  Minimal supplemental logging not enabled.');
    if verbose then 
      dbms_output.put_line('+    For a Capture process to function correctly, at'
                           || ' least minimal supplemental logging should be enabled.');
      dbms_output.put_line('+    Execute ''ALTER DATABASE ADD SUPPLEMENTAL LOG DATA'''
                           || ' to fix this issue.  Note you may need to specify further');
      dbms_output.put_line('+    levels of supplemental logging, see the documentation'
                           || ' for more details.');
      dbms_output.put_line('+');
    end if;
  end if;

  -- #2.  If Primary key database level logging not enabled, there better be some 
  -- log data per prepared table
  select count(*) into row_count from v$database where SUPPLEMENTAL_LOG_DATA_PK = 'NO';
  if row_count > 0 and local_capture_count > 0 then
    for rec in nonlogged_tables loop
      dbms_output.put_line('+  <b>ERROR</b>:  No supplemental logging specified for table '''
                           || rec.owner || '.' || rec.name || '''.');
      if verbose then 
        dbms_output.put_line('+    In order for Replication to work properly, it must' ||
                             ' have key information supplementally logged');
        dbms_output.put_line('+    for each table whose changes are being captured.  ' ||
                             'This system does not have database level primary key information ');
        dbms_output.put_line('logged, thus for each interested table manual logging '
                             || 'must be specified.  Please see the documentation for more info.');
        dbms_output.put_line('+');
      end if;
    end loop;
  end if;

  -- Rules checks
  -- TODO:  intergrate existing rules checks found above     
  for rec in overlapping_rules loop
    overlap_rules := TRUE;
    dbms_output.put_line('+  <b>WARNING</b>:  The rule ''' || rec.owner1 || '''.''' || rec.name1 
                         || ''' and ''' || rec.owner2 || '''.''' || rec.name2 
                         || ''' from rule set ''' || rec.rule_set_owner || '''.''' 
                         || rec.rule_set_name || ''' overlap.');
  end loop;

  if overlap_rules and verbose then
    dbms_output.put_line('+    Overlapping rules are a problem especially when rule-based transformations exist.');
    dbms_output.put_line('+    No guarantee is made as to which rule in a rule set will evaluate to TRUE,');
    dbms_output.put_line('+    thus overlapping rules will cause inconsistent behavior, and should be avoided.');
  end if;
  dbms_output.put_line('+');

  --
  -- Suggestions.  These might help speedup performance.
  --

  if verbose then 
    
  
-- Check capture parallelism is not zero (0)
  for rec in cparallel loop
    dbms_output.put_line('+  <b>WARNING</b>:  the Capture process ''' || rec.capture_name ||' for extract '||rec.client_name||' has parallelism set to 0!');
    dbms_output.put_line('+ For Oracle Database Enterprise Edition, include the following line in the extract parameter file');
    dbms_output.put_line('+    TRANLOGOPTIONS INTEGRATEDPARAMS(PARALLELISM 2)');
    dbms_output.put_line('+ For Oracle Database Standard Edition, include the following line in the extract parameter file');
    dbms_output.put_line('+    TRANLOGOPTIONS INTEGRATEDPARAMS(PARALLELISM 1)'); 
    dbms_output.put_line('+');
  end loop;


    -- Apply has parallelism 1
    select count(*) into row_count from dba_apply_parameters p where  p.apply_name in (select apply_name from dba_apply where purpose = 'GoldenGate Apply')
       and p.parameter='PARALLELISM' 
       and to_number(value) = 1;
    if row_count > 0 then 
      dbms_output.put_line('+  <b>INFO</b>:  One or more Apply processes have parallelism 1');
      dbms_output.put_line('+    If your workload consists of many independent transactions');
      dbms_output.put_line('+    and the apply is the bottleneck of your Enterprise Edition database, ');
      dbms_output.put_line('+    Review the following:');
      dbms_output.put_line('+     Set PARALLELISM to at least 4 using the following command in the replicat parameter file');
      dbms_output.put_line('+        DBOPTIONS INTEGRATEDPARAMS(PARALLELISM 4)');
      dbms_output.put_line('+     To limit the maximum number of apply server processes to 30 on the database, use the MAX_PARALLELISM parameter');
      dbms_output.put_line('+        DBOPTIONS INTEGRATEDPARAMS(MAX_PARALLELISM 30)');
      dbms_output.put_line('+ For Oracle Database Standard Edition, include the following line in the replicat parameter file');
      dbms_output.put_line('+    DBOPTIONS INTEGRATEDPARAMS(PARALLELISM 1, MAX_PARALLELISM 1)'); 
      dbms_output.put_line('+');
    end if;

   
   -- General  dml handlers defined for apply
    select count(*) into row_count from 
           dba_apply_dml_handlers d
     where 
       d.apply_name is null and 
        d.error_handler = 'N';

    if row_count > 0 then 
      dbms_output.put_line('+  <b>INFO</b>:  One or more General DML handlers are configured in this database (<a href="#DMLHandler">Handler Details</a>)');
      dbms_output.put_line('+   A general DML handler is configured for a particular table and operation, for ALL Apply processes');
      dbms_output.put_line('+');
    end if;

    -- General  error handlers defined for apply
    select count(*) into row_count from 
           dba_apply_dml_handlers d
     where 
       d.apply_name is null and
        d.error_handler = 'Y';

    if row_count > 0 then 
      dbms_output.put_line('+  <b>INFO</b>:  One or more General Error handlers are configured in this database (<a href="#DMLHandler">Handler Details</a>)');
      dbms_output.put_line('+   A general Error handler is configured for a particular table and operation, for ALL Apply processes');
      dbms_output.put_line('+');
    end if;


    -- Database-level supplemental logging defined but only a few tables replicated
    select count(*) into row_count from v$database where supplemental_log_data_pk = 'YES';
    select count(*) into capture_count from dba_capture_prepared_tables;
    if row_count > 0 and capture_count < 10 and local_capture_count > 0 then
      dbms_output.put_line('+  <b>INFO</b>:  Database-level supplemental logging enabled but only a few tables');
      dbms_output.put_line('+    prepared for capture.  Database-level supplemental logging could write more');
      dbms_output.put_line('+    information to the redo logs for every update statement in the system.');
      dbms_output.put_line('+    If the number of tables you are interested in is small, you might consider');
      dbms_output.put_line('+    specifying supplemental logging of keys and columns on a per-table basis.');
      dbms_output.put_line('+    See the documentation for more information on per-table supplemental logging.');
      dbms_output.put_line('+');
    end if;
  end if;  
end;
/

prompt
prompt  ++
prompt  ++ <a name="Performance Checks"><b>Performance Checks</b></a> ++
prompt  ++
prompt  ++ Note:  Performance only checked for enabled  processes!
prompt  ++        Aborted and disabled processes will not report performance warnings!
prompt
declare
  verbose boolean := TRUE;

  -- how far back capture must be before we generate a warning
  capture_latency_threshold    number := 300;  -- seconds
-- how long logminer can spend spilling before generating a warning
  logminer_spill_threshold     number := 30000000;  -- microseconds 

  -- how far back the apply reader must be before we generate a warning
  applyrdr_latency_threshold   number := 600;  -- seconds
  -- how far back the apply coordinator's LWM must be before we generate a warning
  applylwm_latency_threshold   number := 1200;  -- seconds
  -- how many messages should be unconsumed before generating a warning
  unconsumed_msgs_threshold    number := 300000;
  

  complex_rules boolean := FALSE;
  slow_clients boolean := FALSE;

cursor capture_latency (threshold NUMBER) is 
   select capture_name, 86400 *(available_message_create_time - capture_message_create_time) latency
     from gv$goldengate_capture 
    where 86400 *(available_message_create_time - capture_message_create_time) > threshold;

  cursor logminer_spill_time (threshold NUMBER) is
  select c.capture_name, l.name, l.value from gv$goldengate_capture c, gv$logmnr_stats l
   where c.logminer_id = l.session_id 
     and name = 'microsecs spent in pageout' and value > threshold;  

  cursor apply_reader_latency (threshold NUMBER) is 
   select apply_name, 86400 *(dequeue_time - dequeued_message_create_time) latency
     from gv$gg_apply_reader
    where 86400 *(dequeue_time - dequeued_message_create_time) > threshold;

  cursor apply_lwm_latency (threshold NUMBER) is 
   select r.apply_name, 86400 *(r.dequeue_time - c.lwm_message_create_time) latency
     from gv$gg_apply_reader r, gv$gg_apply_coordinator c
    where r.apply# = c.apply# and r.apply_name = c.apply_name 
      and 86400 *(r.dequeue_time - c.lwm_message_create_time) > threshold;

  cursor queue_stats is
  select queue_schema, queue_name, num_msgs, cnum_msgs, 
           86400 *(sysdate - startup_time) alive
    from gv$buffered_queues;


 cursor client_slow is
    select c.capture_name, c.extract_name, c.state,l.available_txn-l.delivered_txn difference from 
         gv$goldengate_capture c, 
         gv$logmnr_session l 
        where c.capture_name = l.session_name 
           and c.state in ('WAITING FOR CLIENT REQUESTS', 'WAITING FOR TRANSACTION;WAITING FOR CLIENT');

begin
  
  for rec in client_slow loop
     dbms_output.put_line('+   <b>WARNING</b>:  Extract '||rec.extract_name||' is slow to request changes ('||rec.difference||' chunks available) from capture '||rec.capture_name);
      dbms_output.put_line('+  Use the following command to obtain Extract wait statistics');
      dbms_output.put_line('SEND extract '||rec.extract_name||', LOGSTATS ');
      dbms_output.put_line('+  Output of above command is written to extract report file');
      dbms_output.put_line('+ ');
     slow_clients := TRUE;
  end loop;
    if  slow_clients then
       dbms_output.put_line('+  The  WAITING FOR CLIENT REQUESTS state is an indicator to investigate the extract process rather than the logmining server when there are chunks available from capture.');
       dbms_output.put_line('+  If OGG version is 11.2.1.0.7 thru 11.2.1.0.12, upgrade to  version 11.2.1.0.13 or above  ( My Oracle Support article 1589437.1 )' );
       dbms_output.put_line('+');
       dbms_output.put_line('+  If Integrated Extract is V2 and wait statistics from SEND extract... LOGSTATS are high, ');
       dbms_output.put_line('+  add the following line to the extract parameter file and restart extract:');
       dbms_output.put_line('TRANLOGOPTIONS _READAHEADCOUNT 64');
       dbms_output.put_line('+');
       dbms_output.put_line('+  See My Oracle Support article 1063123.1 for instructions on additional troubleshooting of the extract process, if needed.'); 
       dbms_output.put_line('+');
    end if;

      
  for rec in capture_latency(capture_latency_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  The latency of the Capture process ''' || rec.capture_name
                         || ''' is ' || to_char(rec.latency, '99999999') || ' seconds!');
    if verbose then
      dbms_output.put_line('+    This measurement shows how far behind the Capture process is in processing the');
      dbms_output.put_line('+    redo log.  ');
      dbms_output.put_line('+  If OGG version is 11.2.1.0.7 thru 11.2.1.0.12, upgrade to  version 11.2.1.0.13 or above  ( My Oracle Support article 1589437.1 )' );
       dbms_output.put_line('+');
      dbms_output.put_line('+ If this latency is chronic and not due');
      dbms_output.put_line('+    to errors or OGG version, consider the above suggestions for improving Capture Performance');
      dbms_output.put_line('+');
    end if;
  end loop;

  -- logminer spill time
  for rec in logminer_spill_time(logminer_spill_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  Excessive spill time for Capture process ''' 
                          || rec.capture_name || '''!');
    if verbose then
      dbms_output.put_line('+    Spill time implies that the Logminer component used by Capture ');
      dbms_output.put_line('+    does not have enough memory allocated to it.  This condition ');
      dbms_output.put_line('+    occurs when the system workload contains many DDLs and/or LOB');
      dbms_output.put_line('+    transactions.  Consider increasing the size of memory allocated to the');
      dbms_output.put_line('+    Capture process by increasing the ''MAX_SGA_SIZE'' extract parameter TRANLOGOPTIONS INTEGRATEDPARAMS.');
    end if;
    dbms_output.put_line('+');
  end loop;

  for rec in apply_reader_latency(applyrdr_latency_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  The latency of the reader process for Apply ''' || rec.apply_name
                         || ''' is ' || to_char(rec.latency, '99999999') || ' seconds!');
    if verbose then
      dbms_output.put_line('+    This measurement shows how far behind the Apply reader is from when the message was');
      dbms_output.put_line('+    created, which in the normal case is by a Capture process.  In other words, ');
      dbms_output.put_line('+    the time between message creation and message dequeue by the Apply reader is too large.');
      dbms_output.put_line('+    If this latency is chronic and not due to errors, consider the above suggestions ');
      dbms_output.put_line('+    for improving Extract and/or Pump performance.');
      dbms_output.put_line('+');
    end if;
  end loop;

  for rec in apply_lwm_latency(applylwm_latency_threshold) loop
    dbms_output.put_line('+  <b>WARNING</b>:  The latency of the coordinator process for Apply ''' || rec.apply_name
                         || ''' is ' || to_char(rec.latency, '99999999') || ' seconds!');
    if verbose then
      dbms_output.put_line('+    This measurement shows how far behind the low-watermark of the Apply process is');
      dbms_output.put_line('+    from when the message was first created, which in the normal case is by a Extract/Capture process.');
      dbms_output.put_line('+    The low-watermark is the most recent transaction (in terms of SCN) that has been');
      dbms_output.put_line('+    successfully applied, for which all previous transactions have also been applied.');
      dbms_output.put_line('+    A high latency can be due to long-running tranactions, many dependent transactions,');
      dbms_output.put_line('+    or slow/down Extract, Pump, or Replicat processes.');
      dbms_output.put_line('+');
    end if;
  end loop;

end;
/

prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


set lines 180
set numf 9999999999999999999
set pages 9999
col apply_database_link HEAD 'Database Link|for Remote|Apply' format a15
set feedback on

prompt ============================================================================================
prompt
prompt ++ <a name="Database"><b>DATABASE INFORMATION</b></a> ++

COL MIN_LOG FORMAT A7
COL PK_LOG FORMAT A6
COL UI_LOG FORMAT A6
COL FK_LOG FORMAT A6
COL ALL_LOG FORMAT A6
col PROC_LOG FORMAT A6
COL FORCE_LOG FORMAT A10
col archive_change# format 999999999999999999
col archivelog_change# format 999999999999999999
COL NAME HEADING 'Name'
col platform_name format a30 wrap
col current_scn format 99999999999999999

SELECT DBid,name,created,
SUPPLEMENTAL_LOG_DATA_MIN MIN_LOG,SUPPLEMENTAL_LOG_DATA_PK PK_LOG,
SUPPLEMENTAL_LOG_DATA_UI UI_LOG, 
SUPPLEMENTAL_LOG_DATA_FK FK_LOG,
SUPPLEMENTAL_LOG_DATA_ALL ALL_LOG,
SUPPLEMENTAL_LOG_DATA_PL PROC_LOG,
 FORCE_LOGGING FORCE_LOG, 
resetlogs_time,log_mode, archive_change#,
open_mode,database_role,archivelog_change# , current_scn, min_required_capture_change#, 
platform_id, platform_name from v$database;

prompt
col banner heading 'Database Edition'
select * from v$version where banner like 'Oracle%';


prompt ============================================================================================
prompt
prompt ++ INSTANCE INFORMATION ++
col host format a20 wrap 
col blocked heading 'Blocked?'  format a8
col shutdown_pending Heading 'Shutdown|Pending?' format a8
col parallel Heading 'Parallel' format a8
col archiver Heading 'Archiver'
col active_state Heading 'Active|State' 
col instance heading 'Instance'
col name heading 'Name'
col host Heading 'Host'
col version heading 'Version'
col startup_time heading 'Startup|Time'
col status Heading 'Status'
col logins Heading 'Logins'
col instance_role Heading 'Instance|Role'
col instance_mode Heading 'Instance|Mode'




select instance_number INSTANCE, instance_name NAME, HOST_NAME HOST, VERSION,
STARTUP_TIME, STATUS, PARALLEL, ARCHIVER, LOGINS, SHUTDOWN_PENDING, INSTANCE_ROLE, ACTIVE_STATE, BLOCKED  from gv$instance;

prompt
prompt ============================================================================================

prompt +++  Current Database Incarnation   +++
prompt

col incarnation# HEADING 'Current|Incarnation' format 9999999999999999
col resetlogs_id HEADING 'ResetLogs|Id'  format 9999999999999999
col resetlogs_change# HEADING 'ResetLogs|Change Number' format 9999999999999999

Select Incarnation#, resetlogs_id,resetlogs_change#  from v$database_incarnation where status = 'CURRENT';

prompt ============================================================================================
prompt
prompt ++ REGISTRY INFORMATION ++
col comp_id format a10 wrap Head 'Comp_ID'
col comp_name format a35 wrap Head 'Comp_Name'
col version format a10 wrap Head Version
col schema format a10 Head Schema
col modified Head Modified

select comp_id, comp_name,version,status,modified,schema from DBA_REGISTRY;

prompt +++ REGISTRY HISTORY +++
prompt
select * from dba_registry_history;
prompt

prompt ============================================================================================
prompt
prompt ++ NLS DATABASE PARAMETERS ++
col parameter format a30 wrap
col value format a30 wrap

select * from NLS_DATABASE_PARAMETERS;

prompt ============================================================================================
prompt
prompt ++ GLOBAL NAME ++


select global_name from global_name;

prompt
prompt ============================================================================================
prompt
prompt ++ Key Init.ORA parameters ++
prompt
col name HEADING 'Parameter|Name' format a30
col value HEADING 'Parameter|Value' format a15
col description HEADING 'Description' format a60 word

select name,value,description from v$parameter where name in
   ('aq_tm_processes', 'archive_lag_target', 
    'job_queue_processes','_job_queue_interval',
    'shared_pool_size', 'sga_max_size', 
    'memory_max_target','memory_target',
    'sga_target','streams_pool_size',
    'global_names', 'compatible','log_parallelism',
    'logmnr_max_persistent_sessions', 
    'processes', 'sessions',
    'control_file_record_keep_time',
    'enable_goldengate_replication'
    );



prompt ============================================================================================
prompt
prompt ++ <a name="Administrators"><b>GoldenGate Administrators IN DATABASE</b></a> ++
prompt
column username heading 'Administrator|Name' format a30
column priv_type Heading 'Privilege|Type' format a16
column priv_model Heading 'Privilege|Model' format a20
column create_time Heading 'Created' format a30
prompt
prompt Non-default configuration is displayed in <b>bold</b>
prompt The privilege type default is '*' (Capture + Apply) for 11.2.0.4 and up. 
prompt Trusted privilege model is the default privilege model with Oracle 11.2.0.4 and up.
prompt
prompt Trusted privilege model administrators typically use DBA and V$ views to monitor the configuration
prompt Untrusted privilege model administrators use ALL and V$ views to monitor the configuration
prompt



select username,decode(privilege_type,'CAPTURE','<b>CAPTURE</b>','APPLY','<b>APPLY</b>','*','CAPTURE + APPLY',NULL) priv_type,decode(grant_select_privileges,'YES','Trusted (full)','NO','<b>Untrusted (minimum)</b>',null) priv_model, create_time  from DBA_goldengate_privileges;



prompt
prompt ============================================================================================
prompt
prompt ++  Streams Administrator  ++
column username heading 'Administrator|Name'
column local_privileges Heading 'Local|Privileges' format a10
column access_from_remote Heading 'Remote|Access' format a10


select * from dba_streams_administrator;

prompt
prompt  ++ Database User information for GoldenGate Administrators
prompt
col password noprint

select username,user_id,DECODE(account_status,'OPEN',account_status,'<b>'||account_status||'</b>') account_status,created, lock_date,expiry_date,default_tablespace,
       profile, initial_rsrc_consumer_group, 
       password_versions, editions_enabled, authentication_type,
       external_name
  from dba_users 
  where
    username in  (select capture_user from dba_capture where purpose like 'GoldenGate%' union select apply_name from dba_apply  where purpose like 'GoldenGate%' union select username from dba_goldengate_privileges)  
order by 1;

prompt ============================================================================================

prompt 
prompt ++ <a name="Queues in Database">QUEUES IN DATABASE</a> ++
prompt ==========================================================================================

prompt
prompt  Queues are configured mainly for subscriber information
prompt  OGG configurations typically do not store data in the queue.
prompt
COLUMN OWNER HEADING 'Owner' FORMAT A10
COLUMN NAME HEADING 'Queue Name' FORMAT A30
COLUMN QUEUE_TABLE HEADING 'Queue Table' FORMAT A30
COLUMN ENQUEUE_ENABLED HEADING 'Enqueue|Enabled' FORMAT A7
COLUMN DEQUEUE_ENABLED HEADING 'Dequeue|Enabled' FORMAT A7
COLUMN USER_COMMENT HEADING 'Comment' FORMAT A20
COLUMN PRIMARY_INSTANCE HEADING 'Primary|Instance|Owner'FORMAT 999999
column SECONDARY_INSTANCE HEADING 'Secondary|Instance|Owner' FORMAT 999999
COLUMN OWNER_INSTANCE HEADING 'Owner|Instance' FORMAT 999999
column NETWORK_NAME HEADING 'Network|Name' FORMAT A30

SELECT q.OWNER, q.NAME, t.QUEUE_TABLE, q.enqueue_enabled, 
  q.dequeue_enabled,t.primary_instance,t.secondary_instance, t.owner_instance,network_name, q.USER_COMMENT
  FROM DBA_QUEUES q, DBA_QUEUE_TABLES t
  WHERE t.OBJECT_TYPE = 'SYS.ANYDATA' AND
        q.QUEUE_TABLE = t.QUEUE_TABLE AND
        q.OWNER       = t.OWNER
    order by owner,queue_table,name;
prompt

prompt
prompt  +++   Queue Subscribers   ++
prompt

column subscriber HEADING 'Subscriber' format a35 wrap
column name HEADING 'Queue|Name' format a35 wrap
column delivery_mode HEADING 'Delivery|Mode' format a23
column queue_to_queue HEADING 'Queue to|Queue' format a5
column protocol clear
column protocol HEADING 'Protocol' 
SELECT qs.owner||'.'||qs.queue_name name, qs.queue_table, 
       NVL2(qs.consumer_name,'CONSUMER: ','ADDRESS : ') ||
       NVL(qs.consumer_name,qs.address) Subscriber,
       qs.delivery_mode,qs.queue_to_queue,qs.protocol
FROM dba_queue_subscribers qs, dba_queue_tables qt
WHERE  qt.OBJECT_TYPE = 'SYS.ANYDATA'  AND
       qs.QUEUE_TABLE = qt.QUEUE_TABLE AND
       qs.OWNER = qt.OWNER
ORDER BY qs.owner,qs.queue_name;


prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  





prompt
prompt  ++ <a name="Extract"><b>INTEGRATED EXTRACT CONFIGURATION IN DATABASE</b></a> ++  
col start_scn format 9999999999999999
col applied_scn format 9999999999999999
col capture_name HEADING 'Capture|Name' format a30 wrap
col status HEADING 'Status' format a10 wrap

col QUEUE HEADING 'Queue' format a25 wrap
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col capture_type HEADING 'Capture|Type' format a10 wrap
col error_message HEADING 'Capture|Error Message' format a60 word
col logfile_assignment HEADING 'Logfile|Assignment'
col checkpoint_retention_time HEADING 'Days to |Retain|Checkpoints'
col Status_change_time HEADING 'Status|Timestamp'
col error_number HEADING 'Error|Number'
col version HEADING 'Version'
col purpose HEADING 'Purpose'
col extract_mode HEADING 'Extract|Mode'format a10 wrap

prompt  ++ EXTRACT INFORMATION: Client  ++
col capture_name HEADING 'Capture|Name' format a30 wrap
col status HEADING 'Capture|Status' format a10 wrap
col client_name HEADING 'Extract|Name' format a30 wrap
col Client_status HEADING 'Client|Status' format a15 wrap


SELECT client_name ,
DECODE(client_status,'ATTACHED',client_status,'<b><a href="#Notification">'||client_status||'</a></b>') client_status, 
capture_name, status,  
decode(purpose, 'GoldenGate Capture','Integrated Capture','Streams', 'Classic Capture','*',NULL) extract_mode 
,error_number, status_change_time, error_message 
FROM DBA_CAPTURE where purpose like 'GoldenGate%' or capture_name like 'OGG%$%' order by capture_name;

prompt
prompt  ++ Integrated Capture Version  ++
prompt

col capture_name Heading 'Capture Name' format a20
col version  Heading 'Version'format a7

select capname_knstcap capture_name, decode(bitand(flags_knstcap,64), 64,'V2','<b> <a href="#SYSCheck">V1</a> </b>') version from x$knstcap order by version, capture_name;


prompt
prompt  ++ <a name="Capture Processes">CAPTURE PROCESSES IN DATABASE</a> ++  

prompt 
col checkpoint HEADING 'Checkpoint|Retention|Time (days)'
col capture_user Heading 'Capture|User' format a15 wrap

 
SELECT capture_name, queue_owner||'.'||queue_name QUEUE, capture_type, purpose,status, capture_user,
rule_set_owner||'.'||rule_set_name RSN, negative_rule_set_owner||'.'||negative_rule_set_name RSN2, 
DECODE(checkpoint_retention_time,60,'<b><a href="#Notification">'||checkpoint_retention_time||'</a></b>',checkpoint_retention_time ) Checkpoint,
version, logfile_assignment,error_number, status_change_time, error_message 
FROM DBA_CAPTURE where purpose like 'GoldenGate%' or capture_name like 'OGG%$%' order by capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt  ++ CAPTURE PROCESS SOURCE INFORMATION ++  

col QUEUE HEADING 'Queue' format a25 wrap
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col capture_type HEADING 'Capture|Type' format a10 wrap
col source_database HEADING 'Source|Database' format a30 wrap
col filtered_scn HEADING 'Filtered|SCN'
col first_scn HEADING 'First|SCN' 
col start_scn HEADING 'Start|SCN'  
col captured_scn HEADING 'Captured|SCN'
col applied_scn HEADING 'Applied|SCN'
col last_enqueued_scn HEADING 'Last|Enqueued|SCN'
col required_checkpoint_scn HEADING 'Required|Checkpoint|SCN'
col max_checkpoint_scn HEADING 'Maximum|Checkpoint|SCN'

col source_dbid HEADING 'Source|Database|ID'
col source_resetlogs_scn HEADING 'Source|ResetLogs|SCN'
col logminer_id HEADING 'Logminer|Session|ID'
col source_resetlogs_time HEADING 'Source|ResetLogs|Time'


SELECT capture_name, capture_type, source_database,  
 captured_scn, applied_scn, last_enqueued_scn,
required_checkpoint_scn,
max_checkpoint_scn, filtered_scn,
first_scn, start_scn ||' ('||start_time||') ' start_scn, 
source_dbid, source_resetlogs_scn, 
source_resetlogs_time, logminer_id
FROM DBA_CAPTURE  where purpose like 'GoldenGate%' or capture_name like 'OGG%$%' order by capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt ++ <a name=CapParameters>CAPTURE PROCESS PARAMETERS</a> ++
prompt    Parameters set by Oracle GoldenGate Extract, including PARALLELISM
prompt
col CAPTURE_NAME  HEADING 'Capture|Name' format a30 wrap
col parameter HEADING 'Parameter|Name' format a28
col value HEADING 'Parameter|Value' format a20
col set_by_user HEADING 'Usr|Set?'format a3


select cp.* from dba_capture_parameters cp,dba_capture c   where c.purpose like 'GoldenGate%' and c.capture_name = cp.capture_name and (cp.set_by_user='YES' or cp.parameter='PARALLELISM') order by cp.capture_name,PARAMETER ; 
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt ============================================================================================
prompt
prompt ++ CAPTURE RULES  ++
col NAME Heading 'Capture|Name' format a25 wrap
col object format a45 wrap heading 'Object'

col source_database format a15 wrap
col rule_set_type heading 'Rule Set|Type'
col RULE format a45 wrap  heading 'Rule |Name'
col TYPE format a15 wrap heading 'Rule |Type'
col dml_condition format a40 wrap heading 'Rule|Condition'
col include_tagged_lcr heading 'Tagged|LCRs?' format a7
col same_rule_condition Head 'Rule Condition|Same as Orig?' format a14
prompt
prompt -- If OGG integrated capture is V2 protocol, only GLOBAL rules and PDB rules will show in the rules section
prompt -- Check runtime statistics to determine which protocol is being used.

select sr.streams_NAME NAME,sr.schema_name||'.'||sr.object_name OBJECT, 
sr.rule_set_type,
sr.SOURCE_DATABASE, 
sr.streams_RULE_TYPE ||' '||sr.Rule_type TYPE ,
sr.INCLUDE_TAGGED_LCR, sr.same_rule_condition, 
sr.rule_owner||'.'||sr.rule_name RULE
from dba_streams_rules sr, dba_capture c where sr.streams_type = 'CAPTURE' 
and c.capture_name=sr.streams_name and c.purpose like 'GoldenGate%'
order by name,object, sr.source_database, sr.rule_set_type,rule;




prompt
prompt ++ CAPTURE RULES BY RULE SET ++
col capture_name format a25 wrap  heading 'Capture|Name'
col RULE_SET format a25 wrap heading 'Rule Set|Name'
col RULE_NAME format a25 wrap heading 'Rule|Name'
col condition format a50 wrap heading 'Rule|Condition'
set long 4000 
REM break on rule_set

select c.capture_name, rsr.rule_set_owner||'.'||rsr.rule_set_name RULE_SET ,rsr.rule_owner||'.'||rsr.rule_name RULE_NAME, 
r.rule_condition CONDITION from
dba_rule_set_rules rsr, DBA_RULES r ,DBA_CAPTURE c
where rsr.rule_name = r.rule_name and rsr.rule_owner = r.rule_owner  and 
rsr.rule_set_owner=c.rule_set_owner and rsr.rule_set_name=c.rule_set_name  and rsr.rule_set_name in 
(select rule_set_name from dba_capture where c.purpose like 'GoldenGate%') order by rsr.rule_set_owner,rsr.rule_set_name;

prompt  +** CAPTURE RULES IN NEGATIVE RULE SET **+
prompt
select c.capture_name, rsr.rule_set_owner||'.'||rsr.rule_set_name RULE_SET ,rsr.rule_owner||'.'||rsr.rule_name RULE_NAME, 
r.rule_condition CONDITION from
dba_rule_set_rules rsr, DBA_RULES r ,DBA_CAPTURE c
where rsr.rule_name = r.rule_name and rsr.rule_owner = r.rule_owner and 
rsr.rule_set_owner=c.negative_rule_set_owner and rsr.rule_set_name=c.negative_rule_set_name 
 and rsr.rule_set_name in 
(select negative_rule_set_name rule_set_name from dba_capture where c.purpose like 'GoldenGate%') order by rsr.rule_set_owner,rsr.rule_set_name;




prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt
prompt ============================================================================================
prompt
prompt ++  Registered Log Files for Capture ++

COLUMN CONSUMER_NAME HEADING 'Capture|Process|Name' FORMAT A15
COLUMN SOURCE_DATABASE HEADING 'Source|Database' FORMAT A10
COLUMN SEQUENCE# HEADING 'Sequence|Number' FORMAT 999999
COLUMN NAME HEADING 'Archived Redo Log|File Name' format a35
column first_scn HEADING 'Archived Log|First SCN' 
COLUMN FIRST_TIME HEADING 'Archived Log Begin|Timestamp' 
column next_scn HEADING 'Archived Log|Last SCN' 
COLUMN NEXT_TIME HEADING 'Archived Log Last|Timestamp' 
COLUMN MODIFIED_TIME HEADING 'Archived Log|Registered Time'
COLUMN DICTIONARY_BEGIN HEADING 'Dictionary|Build|Begin' format A6
COLUMN DICTIONARY_END HEADING 'Dictionary|Build|End' format A6
COLUMN PURGEABLE HEADING 'Purgeable|Archive|Log' format a9

SELECT r.CONSUMER_NAME,
       r.SOURCE_DATABASE,
       r.thread#,
       r.SEQUENCE#, 
       r.NAME, 
       r.first_scn,
       r.FIRST_TIME,
       r.next_scn,
       r.next_time,
       r.MODIFIED_TIME,
       r.DICTIONARY_BEGIN, 
       r.DICTIONARY_END, 
       r.purgeable
  FROM DBA_REGISTERED_ARCHIVED_LOG r, DBA_CAPTURE c
  WHERE r.CONSUMER_NAME = c.CAPTURE_NAME and c.purpose like 'GoldenGate%'
  ORDER BY source_database, consumer_name, r.first_scn; 




prompt ============================================================================================
prompt


prompt ++  SCHEMAS PREPARED ALLKEY FOR GG CAPTURE ++
col allkey_suplog heading 'ALLKEY Logging' format a15
col allow_novalidate_Pk heading 'Allow Novalidate PK' format a20
select * from SYS.LOGMNR$SCHEMA_ALLKEY_SUPLOG order by 1;


prompt ============================================================================================
prompt
prompt ++  TABLES WITH SUPPLEMENTAL LOGGING  ++
col OWNER format a30 wrap
col table_name format a30 wrap

select distinct owner,table_name from dba_log_groups order by 1,2;

prompt ++ DATABASE PREPARED FOR CAPTURE ++
col SUPPLEMENTAL_LOG_DATA_PK head 'PK Logging' format a11
col SUPPLEMENTAL_LOG_DATA_UI head 'UI Logging' format a11
col SUPPLEMENTAL_LOG_DATA_FK head 'FK Logging' format a11
col SUPPLEMENTAL_LOG_DATA_ALL head 'ALL Logging' format a11
col TIMESTAMP head 'Timestamp'

select cp.* from dba_capture_prepared_database cp, dba_capture c where c.purpose like 'GoldenGate%';

prompt
prompt ++  TABLE LEVEL SUPPLEMENTAL LOG GROUPS ENABLED FOR CAPTURE ++
col object format a40 wrap
col column_name format a30 wrap
col log_group_name format a25 wrap

select owner||'.'||table_name OBJECT, log_group_name, log_group_type,   decode(always,'ALWAYS','Unconditional','CONDITIONAL','Conditional',NULL,'Conditional') ALWAYS, generated from dba_log_groups order by 1,2;

prompt ++ SUPPLEMENTALLY LOGGED COLUMNS ++
col logging_property heading 'Logging|Property' format a9
prompt Skipping query for supplementally logged columns
REM select owner||'.'||table_name OBJECT, log_group_name, column_name,position,LOGGING_PROPERTY from dba_log_group_columns order by 1,2;







prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt
prompt
prompt ============================================================================================

prompt
prompt ++ <a name="Outbound Server Processes">GoldenGate CONFIGURATION</a> ++


prompt
col source_database format a40 wrap Heading 'Source|Database'
COLUMN SERVER_NAME HEADING 'Server|Name' 
COLUMN CAPTURE_NAME HEADING 'Capture|Process' 
COLUMN CAPTURE_USER HEADING 'Capture|User'
COLUMN committed_data_only HEADING 'Committed|Data Only'
COLUMN Start_scn Heading 'Start SCN' format 9999999999999999
COLUMN Connect_user Heading 'Connect|User'
Column Create_date Heading 'Create|Date'
Column Start_time Heading 'Start Time'

column queue_owner Heading 'Queue|Owner'
column queue_name Heading 'Queue|Name'
column apply_user Heading 'Apply|User'
column User_comment Heading 'User|Comment'




prompt

Select client_NAME, CAPTURE_USER, CAPTURE_NAME, SOURCE_DATABASE,  
START_SCN ||' ('|| START_TIME||')' as "Start_SCN(Start_Time)",  QUEUE_OWNER,
QUEUE_NAME
from dba_capture where purpose like 'GoldenGate%' or capture_name like 'OGG$%'; 

 

col apply_name format a25 wrap heading 'Outbound|Server Name'
col queue format a25 wrap heading 'Queue|Name'
col apply_tag format a7 wrap  heading 'Apply|Tag'
col ruleset format a25 wrap heading 'Rule Set|Name'
col apply_user format a15 wrap heading 'Apply|User'
col capture_user format a15 wrap heading 'Capture|User'
col apply_captured format a15 wrap heading 'Captured or|User Enqueued'
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col message_delivery_mode HEADING 'Message|Delivery' format a15
col apply_database_link HEADING 'Remote Apply|Database Link' format a25 wrap
col extract HEADING Extract|Name format a25

Select apply_name,status,replace(apply_name,'OGG$','') Extract, queue_owner||'.'||queue_name QUEUE,
 a.apply_user, apply_tag, rule_set_owner||'.'||rule_set_name RSN,
negative_rule_set_owner||'.'||negative_rule_set_name RSN2 
 from DBA_APPLY a where a.purpose like 'GoldenGate%' ;

prompt ++   PROCESS INFORMATION ++
col applied_scn HEADING 'Minimum Applied|Message Number' 
col error_message HEADING 'Capture|Error Message' format a60 wrap
prompt

select c.client_name, c.applied_scn,c.client_status, c.status_change_time,c.error_number,
case 
  when c.error_number =1013 then 'STOP EXTRACT command performed ( '||c.error_message||' )'
  when c.client_status='DETACHED' then 'Extract is not started'
  else c.error_message
end   error_message
  from    dba_capture c where c.purpose like 'GoldenGate%' ;







prompt
prompt =================================================================================
prompt




prompt
prompt 
prompt ++  OGG Integrated Capture Progress Table ++
prompt

col applied_low_position format a40 wrap
col applied_high_position format a40 wrap
col spill_position format a40 wrap

select capture_name,client_name,client_status,applied_scn processed_low_scn, oldest_scn From dba_capture where purpose like 'Golden%'  or capture_name like 'OGG%$%' order by capture_name;

prompt  ++  APPLY PROGRESS ++
prompt --  Integrated Capture does not update Apply Progress table

col oldest_message_number HEADING 'Oldest|Message|SCN'
col apply_time HEADING 'Apply|Timestamp'
select ap.* from dba_apply_progress ap, dba_apply a where a.purpose like 'GoldenGate%' and ap.apply_name=a.apply_name and a.purpose like 'Golden%';


prompt


prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  

prompt
prompt =================================================================================
prompt
prompt ++ <a name="Inbound Server Configuration"> <b>INBOUND SERVER CONFIGURATION<b> </a> ++
prompt
col source_database format a40 wrap Heading 'Source|Database'
COLUMN SERVER_NAME HEADING 'Server|Name' 
COLUMN CAPTURE_NAME HEADING 'Capture|Process' 
COLUMN CAPTURE_USER HEADING 'Capture|User'
COLUMN committed_data_only HEADING 'Committed|Data Only'
COLUMN Start_scn Heading 'Start SCN' format 9999999999999999
COLUMN Connect_user Heading 'Connect|User'
Column Create_date Heading 'Create|Date'
Column Start_time Heading 'Start Time'
column username heading 'Administrator|Name'
column local_privileges Heading 'Local|Privileges' format a10
column access_from_remote Heading 'Remote|Access' format a10
column queue_owner Heading 'Queue|Owner'
column queue_name Heading 'Queue|Name'
column apply_user Heading 'Apply|User'
column User_comment Heading 'User|Comment'
column status Heading 'Apply|Status'

prompt
prompt  ++  GoldenGate Inbound Servers ++
prompt

select * from dba_goldengate_inbound;

prompt
prompt
prompt ============================================================================================

prompt
prompt ++ <a name="Apply Processes">APPLY INFORMATION</a> ++

col apply_name format a25 wrap heading 'Apply|Name'
col queue format a25 wrap heading 'Queue|Name'
col apply_tag format a7 wrap  heading 'Apply|Tag'
col ruleset format a25 wrap heading 'Rule Set|Name'
col apply_user format a15 wrap heading 'Apply|User'
col apply_captured format a15 wrap heading 'Captured or|User Enqueued'
col RSN HEADING 'Positive|Rule Set' format a25 wrap
col RSN2 HEADING 'Negative|Rule Set' format a25 wrap
col message_delivery_mode HEADING 'Message|Delivery' format a15
col apply_database_link HEADING 'Remote Apply|Database Link' format a25 wrap
col purpose HEADING Purpose format a25

Select apply_name,purpose,status,queue_owner||'.'||queue_name QUEUE,
DECODE(APPLY_CAPTURED,
                'YES', 'Captured',
                'NO',  'User-Enqueued') APPLY_CAPTURED, 
apply_user, apply_tag, rule_set_owner||'.'||rule_set_name RSN,
negative_rule_set_owner||'.'||negative_rule_set_name RSN2, message_delivery_mode,
apply_database_link from DBA_APPLY 
where purpose = 'GoldenGate Apply';
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt ++  APPLY PROCESS INFORMATION ++
col max_applied_message_number HEADING 'Maximum Applied|Message Number' 
col error_message HEADING 'Apply|Error Message' format a60 wrap

select apply_name, max_applied_message_number,status, status_change_time,error_number, error_message from dba_apply
where purpose = 'GoldenGate Apply';
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
prompt ++ <a name="AppParameters"> APPLY PROCESS PARAMETERS</a> ++

col APPLY_NAME format a30
col parameter format a28
col value format a28
REM break on apply_name

select ap.* from dba_apply_parameters ap, dba_apply a
where a.purpose = 'GoldenGate Apply' and a.apply_name=ap.apply_name and 
 (ap.set_by_user='YES'OR ap.parameter in ('PARALLELISM','MAX_PARALLELISM'))
order by ap.apply_name,parameter;
prompt
prompt <a href="#Summary">Return to Summary</a>




prompt
prompt ============================================================================================
prompt
prompt ++ APPLY HANDLERS ++
col apply_name format a25 wrap
col message_handler format a25 wrap
col ddl_handler format a25 wrap

select apply_name, ddl_handler,  precommit_handler from dba_apply
where purpose = 'GoldenGate Apply';

prompt
prompt ++ <a name=DMLHandler> APPLY DML HANDLERS </a> ++
col object format a35 wrap
col user_procedure HEADING 'User |Procedure' format a40 wrap
col handler_name HEADING 'Stmt |Handler' format a40 wrap
col dblink Heading 'Apply|DBLink' format a15 wrap
col apply_database_link HEAD 'Database Link|for Remote|Apply' format a25 wrap
col operation_name HEADING 'Operation|Name' format a13
col typ  Heading 'Handler|Type' format a17 wrap
col lob_assemble HEADING 'Assemble|Lob?' format a8

select object_owner||'.'||object_name OBJECT, operation_name , 
handler_type TYP,
decode(assemble_lobs,'Y','Yes','N','No','UNKNOWN') lob_assemble,
apply_name, 
user_procedure,
handler_name,
APPLY_Database_link
from dba_apply_dml_handlers 
order by object_owner,object_name,apply_name;

prompt <a href="#Summary">Return to Summary</a>
prompt
prompt ++ DML STATEMENT HANDLER STATUS ++
prompt
col handler_name format a40 wrap
col handler_comment format a40 wrap

select * from dba_streams_stmt_handlers order by 1;
prompt <a href="#Summary">Return to Summary</a>
prompt
prompt ** DML Statement Handler Statements **
prompt

select * from dba_streams_stmts order by 1,2;
prompt <a href="#Summary">Return to Summary</a>
prompt
prompt ++ DML PROCEDURE HANDLER STATUS ++
prompt
col user_procedure format a40 wrap

 select o.owner||'.'||o.object_name OBJECT,    o.status,o.object_type,o.created, o.last_ddl_time from dba_objects o, 
   (select distinct user_procedure from dba_apply_dml_handlers where user_procedure is not null) h
 where
o.owner=replace(substr(h.user_procedure,1, instr(h.user_procedure,'.',1,1)-1),'"',null) 
   and  o.object_name = replace(substr(h.user_procedure,instr(h.user_procedure,'.',-1,1)+1),'"',null) order by 1;

prompt <a href="#Summary">Return to Summary</a>

prompt ============================================================================================



prompt

prompt ++ Conflict Detection Control ++
prompt

select * From dba_apply_table_columns order by 1,2,3;


prompt ============================================================================================
prompt
prompt ++ UPDATE CONFLICT RESOLUTION COLUMNS ++

col object format a25 wrap
col method_name heading 'Method' format a12
col resolution_column heading 'Resolution|Column' format a13
col column heading 'Column Name' format a30

select object_owner||'.'||object_name object, method_name,
resolution_column, column_name , apply_database_link
from dba_apply_conflict_columns order by object_owner,object_name;


prompt ============================================================================================
prompt
prompt ++ KEY COLUMNS SET FOR APPLY ++

select * from dba_apply_key_columns order by 1,2;


prompt
prompt ++  OGG CDR - DML Conflict Handlers Details  ++
prompt
select * from DBA_APPLY_DML_CONF_HANDLERS order by 1,2,3,4,5,6;
prompt
prompt  ++ OGG Handle Collisions Details ++
prompt
select * from DBA_APPLY_HANDLE_COLLISIONS order by 1,2,3,4;
prompt
prompt  ++ OGG Reperror  Handlers Details ++
prompt
select * from DBA_APPLY_REPERROR_HANDLERS order by 1,2,3,4,5,6;


prompt




prompt ============================================================================================
prompt
prompt ++ OBJECT DEPENDENCIES SET FOR APPLY ++

select * from dba_apply_object_dependencies;

prompt ============================================================================================
prompt
prompt ++ VALUE DEPENDENCIES SET FOR APPLY ++

select * from dba_apply_value_dependencies;






prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  



prompt ============================================================================================
prompt
prompt ++  <a name="Errors">ERROR QUEUE</a> ++
col source_commit_scn HEADING 'Source|Commit|Scn'
col message_number HEADING 'Message in| Txn causing|Error'
col message_count HEADING 'Total|Messages|in Txn'
col local_transaction_id HEADING 'Local|Transaction| ID'
col error_message HEADING 'Apply|Error|Message'
col ERROR_CREATION_TIME HEADING 'Error|Creation|Timestamp'
col source_transaction_id HEADING 'Source|Transaction| ID'

Select apply_name, source_database,source_commit_scn,
   message_number, message_count,
   local_transaction_id, error_type,
   error_message , error_creation_time, 
   source_transaction_id, source_commit_position
from DBA_APPLY_ERROR order by apply_name ,source_commit_scn ;

prompt  Error queue info with seq# and rba#
select p.apply_name, e.source_database, e.source_commit_scn,
       e.message_number, e.message_count,
       e.local_transaction_id,
       (case
          when (bitand(e.flags, 1) = 1) then 'EAGER ERROR'
          when (bitand(e.flags, 8) = 8) then
            (case
               when (bitand(e.flags, 2) = 2) then 'RECORD LCR'
               when (bitand(e.flags, 16) = 16) then 'RECORD TXN NO LCRS'
               else 'RECORD TXN WITH LCRS'
             end)
          when (bitand(e.flags, 16) = 16) then 'UNHANDLED ERROR NO LCRS'
          else NULL
          end) error_type,
       e.error_number,e.error_message,e.error_creation_time,
       e.error_seq#, error_rba,
       e.source_transaction_id, e.external_source_pos,
       e.start_seq#, e.start_rba,
       e.end_seq#, e.end_rba         
  from SYS."_DBA_APPLY_ERROR" e, sys.streams$_apply_process p
 where e.apply# = p.apply#(+)
 order by 1,3;


prompt ++ Tables by Error Type  ++
prompt

select m.error_number,object_owner,object_name, operation,count(*) from dba_apply_error_messages m group by m.error_number,object_owner,object_name,operation order by 1,2,3,4;

prompt




prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  

prompt
prompt ============================================================================================
prompt
prompt ++ INSTANTIATION SCNs for APPLY TABLES ++
col source_database format a25 wrap
col object HEADING 'Database|Object' format a45
col instantiation_scn format 9999999999999999
col apply_database_link HEAD 'Database Link|for Remote|Apply' format a25 wrap

select source_database, source_object_owner||'.'||source_object_name OBJECT, 
   ignore_scn,  instantiation_scn, apply_database_link DBLINK 
from dba_apply_instantiated_objects order by source_database, object;

prompt
prompt ++ INSTANTIATION SCNs for APPLY SCHEMA and  DATABASE  (DDL) ++
col source_database HEADING 'Source|Database' format a30
col OBJECT HEADING 'Database|Object' format a45
col DBLINK HEADING 'Database|Link'
col inst_scn HEADING 'Instantiation|SCN'
col global_flag HEADING 'Schema or |Database'

select source_database, source_schema OBJECT, 
    apply_database_link DBLINK, instantiation_Scn INST_SCN,
    'SCHEMA' global_flag from dba_apply_instantiated_schemas
UNION
select source_database, '' OBJECT, 
    apply_database_link DBLINK, instantiation_Scn INST_SCN,
    'GLOBAL' global_flag from dba_apply_instantiated_global order by source_database,object;

prompt   


prompt ============================================================================================
prompt
prompt ++ <a name="DBA OBJECTS"><b>DBA OBJECTS</b></a> - Rules, and Processes ++
prompt
col OBJECT format a45 wrap heading 'Object'

select owner||'.'||object_name OBJECT,
    object_id,object_type,created,last_ddl_time, status from
    dba_objects 
WHERE object_type in ('RULE','RULE SET','CAPTURE','APPLY')
    order by object_type, object;


prompt
prompt ============================================================================================
prompt

prompt ++  Check RECOVERABLE tables  ++
prompt     Automation from MAINTAIN_* scripts and SPLIT/MERGE jobs
prompt


set long 100
col progress format a28
select sysdate,rs.creation_time, 
rs.invoking_package||'.'||rs.invoking_procedure PROCEDURE,
rs.status, 
rs.done_block_num||' of '||rs.total_blocks||' Steps Completed' PROGRESS,
to_number(sysdate-rs.creation_time)*86400 ELAPSED_SECONDS,
rs.script_id,
rsb.forward_block CURRENT_STEP
from dba_recoverable_script rs, 
dba_recoverable_script_blocks rsb 
where rs.script_id = rsb.script_id and rsb.block_num = rs.done_block_num + 1;

prompt
prompt  ++ Check RECOVERABLE ERROR view ++
prompt

SELECT e.* FROM DBA_RECOVERABLE_SCRIPT_ERRORS e, dba_recoverable_script s where e.script_id = s.script_id order by e.script_id;

prompt 
prompt ++ Identify Current Script Blocks ++
prompt

set long 4000
select 
    b.script_id, b.block_num, b.status, 
    forward_block_dblink,forward_block 
  from dba_recoverable_script_blocks b, dba_recoverable_script s where b.script_id =s.script_id order by b.script_id, block_num ;


prompt
prompt  ++ History of Recoverable Scripts in last 30 days ++
prompt

set long 4000

select rs.creation_time, 
rs.invoking_package||'.'||rs.invoking_procedure PROCEDURE,
rs.status, 
rs.done_block_num||' of '||rs.total_blocks||' Steps Completed' PROGRESS,
rs.script_id,
rs.script_comment
from dba_recoverable_script_hist rs where sysdate-creation_time < 30
order by creation_time;

prompt
prompt  ++  Recoverable Script Parameters ++
prompt
set long 4000
select * from dba_recoverable_script_params order by 1,2,3;


prompt
prompt  ++ Defined Comparisons ++
prompt
select * from dba_comparison order by owner,comparison_name,comparison_mode;

prompt
prompt ++ Comparison Information ++
prompt
select * From dba_comparison_scan order by owner,comparison_name,parent_scan_id,scan_id;
prompt


prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt
prompt ++    <a name="History"> <b>History</b></a>   ++
prompt

col snap_id format 999999 HEADING 'Snap ID'
col BEGIN_INTERVAL_TIME format a28 HEADING 'Interval|Begin|Time'
col END_INTERVAL_TIME format a28 HEADING 'Interval|End|Time'
col INSTANCE_NUMBER HEADING 'Instance|Number'
col Queue format a28 wrap Heading 'Queue|Name'
col num_msgs    HEADING 'Current|Number of Msgs|in Queue'
col cnum_msgs   HEADING 'Cumulative|Total Msgs|for Queue'
col spill_msgs  HEADING 'Current|Spilled Msgs|in Queue'
col cspill_msgs HEADING 'Cumulative|Total Spilled|for Queue'
col dbid        HEADING 'Database|Identifier'
col total_spilled_msg HEADING 'Cumulative|Total Spilled|Messages'

prompt
prompt ++ Buffered Queue History for last day ++

select s.begin_interval_time,s.end_interval_time , 
   bq.snap_id, 
   bq.num_msgs, bq.spill_msgs, bq.cnum_msgs, bq.cspill_msgs,
   bq.queue_schema||'.'||bq.queue_name Queue,
   bq.queue_id, bq.startup_time,bq.instance_number,bq.dbid
from   dba_hist_buffered_queues bq, dba_hist_snapshot s 
where  bq.snap_id=s.snap_id   and s.end_interval_time >= systimestamp-1 
       and bq.instance_number =s.instance_number
order by bq.queue_schema,bq.queue_name,s.end_interval_time;


prompt
prompt ++ Buffered Subscriber History for last day ++

select s.begin_interval_time,s.end_interval_time , 
   bs.snap_id,bs.subscriber_id, 
   bs.num_msgs, bs.cnum_msgs, bs.total_spilled_msg,
   bs.subscriber_name,subscriber_address,
   bs.queue_schema||'.'||bs.queue_name Queue,
   bs.startup_time,bs.instance_number,bs.dbid
from   dba_hist_buffered_subscribers bs, dba_hist_snapshot s 
where    bs.snap_id=s.snap_id and s.end_interval_time >= systimestamp-1 
       and bs.instance_number =s.instance_number
order by    bs.queue_schema,bs.queue_name,bs.subscriber_id,s.end_interval_time;


prompt
prompt ++ Capture History for last day ++
column total_messages_created HEADING 'Total|Messages|Created'
column total_messages_enqueued HEADING 'Total Messages|Enqueued'
column lag HEADING 'Capture|Lag|(Seconds)' format 99999.99
column elapsed_capture HEADING 'Elapsed Time|Capture|(centisecs'
column elapsed_rule_time HEADING 'Elapsed Time|Rule Evaluation|(centisecs)'
column elapsed_enqueue_time HEADING 'Elapsed Time|Enqueuing Messages|(centisecs)'
column elapsed_lcr HEADING 'Elapsed Time|LCR Creation|(centisecs)'
column elapsed_redo_wait_time HEADING 'Elapsed Time|Redo Wait|(centisecs)'
column elapsed_Pause_time HEADING 'Elapsed Time|Paused|(centisecs)'



select s.begin_interval_time,s.end_interval_time , 
   sc.capture_name,sc.lag,
   sc.total_messages_captured,sc.total_messages_enqueued,
   sc.elapsed_pause_time,
   sc.elapsed_redo_wait_time, 
   sc.elapsed_rule_time, sc.elapsed_enqueue_time, 
   sc.startup_time,sc.instance_number,sc.dbid
from   dba_hist_streams_capture sc, dba_hist_snapshot s 
where  sc.capture_name in (select capture_name from dba_capture where purpose like 'GoldenGate%') and
sc.snap_id=s.snap_id       and s.end_interval_time >= systimestamp-1 
       and sc.instance_number =s.instance_number
order by sc.capture_name,s.end_interval_time;





prompt
prompt ++  Apply History for last day ++
col reader_total_messages_dequeued HEADING 'Reader|Total Msgs|Dequeued'
col reader_lag HEADING 'Reader|Lag|(Seconds)'
col coord_total_received HEADING 'Coordinator|Total Txn|Received'
col coord_total_applied HEADING 'Coordinator|Total Txn|Applied'
col coord_total_rollbacks HEADING 'Coordinator|Total Txn|Rollbacks'
col coord_total_wait_deps HEADING 'Coordinator|Total Txn|Wait-Dep'
col coord_total_wait_cmts HEADING 'Coordinator|Total Txn|Wait-Cmt'
col coord_lwm_lag HEADING 'Coordinator|LWM Lag|(seconds)'
col server_total_messages_applied HEADING 'Server|Total Msgs|Applied'
col server_elapsed_dequeue_time HEADING 'Server|Elapsed Dequeue|Time (cs)'
col server_elapsed_apply_time HEADING 'Server|Elapsed Apply|Time (cs)'



select s.begin_interval_time,s.end_interval_time , 
   sa.apply_name,sa.reader_lag,  
   sa.reader_total_messages_dequeued,
   sa.coord_lwm_lag,
   sa.coord_total_received,sa.coord_total_applied,
   sa.coord_total_rollbacks,
   sa.coord_total_wait_deps,sa.coord_total_wait_cmts,
   sa.server_total_messages_applied,
   sa.server_elapsed_dequeue_time, 
   sa.server_elapsed_apply_time, 
   sa.startup_time,sa.instance_number,sa.dbid
from    dba_hist_streams_apply_sum sa, dba_hist_snapshot s 
where  sa.apply_name in (select apply_name from dba_apply where purpose like 'GoldenGate%')  and
       sa.snap_id=s.snap_id and s.end_interval_time >= systimestamp-1 
       and sa.instance_number =s.instance_number
order by sa.apply_name,s.end_interval_time;







prompt
--   To improve time in getting constraint infocompute Stats on sys.APPLY$_SOURCE_OBJ ; SYS only

--   analyze table  SYS.APPLY$_SOURCE_OBJ compute statistics;

prompt ++ Check for CONSTRAINTS ON TABLES CONFIGURED IN for DB Objects  ++
prompt
col LAST_CHANGE format a11 word heading 'Last|Change'
col search_condition format a25 wrap heading 'Search|Condition'
col ref_constraint HEADING 'Reference|Constraint' format a62
col object format a62
col constraint_name format a30

select distinct object,constraint_name,constraint_type,
status, LAST_CHANGE, rely, Ref_constraint from 
(
select  c.owner||'.'||c.table_name object,c.constraint_name,c.constraint_type,
status, LAST_CHANGE, rely,r_owner||'.'||r_constraint_name Ref_constraint 
from dba_constraints c,dba_capture_prepared_tables p
where c.owner=p.table_owner
and c.table_name=p.table_name
and  c.constraint_type in ('P','U','R')
and  constraint_name not like 'SYS_IOT%' 
UNION ALL
select  c.owner||'.'||c.table_name object,c.constraint_name,c.constraint_type, 
    status, LAST_CHANGE, rely,
    r_owner||'.'||r_constraint_name Ref_constraint
   from dba_constraints c,dba_apply_instantiated_objects p where
    c.owner=p.source_object_owner and c.table_name=p.source_object_name and     c.constraint_type in ('P','U','R')
    and  constraint_name not like 'SYS_IOT%' order by object);

REM prompt ++ List INDEXES on TABLES ++
REM col object format a40 HEADING 'Table'
REM col index_name format a40
REM col funcidx_status format a10
REM col index_type format a10
REM col column_name format a30

REM select ic.table_owner||'.'||ic.table_name object, table_type, ic.column_name,i.uniqueness,i.index_type,funcidx_status 
REM   from dba_indexes i, dba_apply_instantiated_objects p, dba_ind_columns ic
REM    where 
REM          i.owner=p.source_object_owner and i.table_name=p.source_object_name  
REM          and ic.index_owner= i.owner and ic.index_name = i.index_name
REM          order by i.owner, i.table_name;
 
prompt
 

prompt  
prompt ++ TABLES NOT SUPPORTED BY GOLDENGATE Integrated Capture ++
prompt  Lists tables that can not be supported by OGG 

select * from DBA_GOLDENGATE_SUPPORT_MODE where support_mode = 'NONE';




prompt
prompt ++    DICTIONARY INFORMATION ++


col queue format a30 wrap heading 'Queue|Name'
col capture_name format a20 wrap heading 'Capture|Name'
col capture# format 9999 heading 'Capture|Number'
col ruleset format a30 wrap heading 'Positive|Rule Set'
col ruleset2 format a30 wrap heading 'Negative|Rule Set'
col first_scn heading 'First|SCN'

select capture_name,status,purpose, checkpoint_retention_time,logminer_id,capture_type,first_scn,
required_checkpoint_scn from dba_capture order by capture_name;

select capture_name,capture#,queue_owner||'.'||queue_name queue,
   version,first_scn,
   ruleset_owner||'.'||ruleset_name ruleset,
   negative_ruleset_owner||'.'||negative_ruleset_name ruleset2
   from sys.streams$_capture_process order by capture_name;



prompt
prompt    Apply processes defined on system
prompt
col apply_name format a20 wrap heading 'Apply|Name'
col apply# format 9999 heading 'Apply|Number'

select apply_name,status,purpose, apply_tag,apply_user,message_delivery_mode,error_number,error_message from dba_apply order by apply_name;

select apply_name,apply#,queue_owner||'.'||queue_name queue,
  ruleset_owner||'.'||ruleset_name  ruleset ,
  negative_ruleset_owner||'.'||negative_ruleset_name  ruleset2
  from sys.streams$_apply_process order by apply_name;



prompt
prompt    Rules defined on system
prompt
col nbr format 9999999999999999 heading 'Number of|Rules'
col streams_name HEADING 'Name' 
col streams_type HEADING 'Type'

select streams_name,streams_type,count(*) nbr From sys.streams$_rules group by streams_name,streams_type;
prompt

prompt
prompt ++  GoldenGate sessions order by action
prompt
prompt   SVR is server connection type:  DED=DEDICATED;  SHR=SHARED
prompt
col module format a30 wrap
col action format a40 wrap
col program format a30
col process format a15 wrap
col SVR format a3 Heading 'SVR'
col status heading 'Status'
col state heading 'State'


select inst_id,logon_time,sid,serial#,module,action,process, program,status,
decode(server,'DEDICATED','DED','SHR') SVR, state,  event From gv$session where (module = 'GoldenGate' or module like '%tream%' or module like 'OGG%')  
/

-- UNION ALL  
-- Select inst_id,logon_time,  s.sid, s.serial#, s.module type, action, process, program,  s.status, 
-- decode(server,'DEDICATED','DED','SHR') SVR, s.state, s.event FROM GV$SESSION s where (module like 'OGG-%') order by inst_id,module,action;

prompt
prompt  ++ Standby Redo Logs

select * from v$standby_log order by first_change#,thread#,sequence#;

prompt
prompt
prompt ++ 
prompt ++ <a name=LogmnrDetails><b>LOGMINER DATABASE MAP</b></a> ++
prompt    Databases with information in logminer tables
prompt
col global_name format a30 wrap heading 'Global|Name'
col logmnr_uid format 99999999  heading 'Logminer|Identifier';

select global_name,logmnr_uid,flags,'MAP' SRC from system.logmnrc_dbname_uid_map
union
select s.global_db_name,u.logmnr_uid,null,'UID$' SRC from system.logmnr_uid$ u , system.logmnr_session$ s
    where u.session#=s.session# order by 2;

REM    where u.session#=s.session# order by 2;

prompt    LOGMNR_UID$ table
prompt
select * from system.logmnr_uid$ order by 1, 2;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt    LOGMNR_SESSION$ table
prompt
prompt
select * from system.logmnr_session$;
prompt

prompt
prompt ++  Logminer Dictionary Load ++
prompt
col command format a30
select * from gv$logmnr_dictionary_load order by 1,2,3;
prompt
prompt     Logmnr_dictstate$
select * from system.logmnr_dictstate$;
prompt
prompt     logmnr_dictionary$
select * from system.logmnr_dictionary$;
prompt

prompt ++  LOGMINER PARAMETERS  ++
REM  select * from system.logmnr_parameter$;
   SELECT session#, type, scn, name, value
      FROM SYSTEM.logmnr_parameter$
      ORDER BY session#, name; 
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
prompt ++  LOGMINER STATISTICS  ++
prompt 
COLUMN NAME HEADING 'Name' FORMAT A32
COLUMN VALUE HEADING 'Value' FORMAT 99999999999999999


select c.capture_name, name, value from gv$goldengate_capture c, gv$logmnr_stats l
 where c.logminer_id = l.session_id 
   order by capture_name,name;  

col capture_name format a15
column name format a40
column value format a30 
select c.capture_name, x.name,x .value from x$krvxsv x, dba_capture c where value != '0' and c.logminer_id=x.session_id order by capture_name, name;
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt ++  LOGMINER SESSION STATISTICS  ++
prompt 
select * from  gv$logmnr_session 
   order by session_name;  
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
REM prompt   Ordered by session_name
prompt
REM select session_name, USED_MEMORY_SIZE, DELIVERED_TXN, AVAILABLE_TXN, BUILDER_WORK_SIZE, PREPARED_WORK_SIZE from gv$logmnr_session order by available_txn; 
prompt      calculate difference, order by session_name
select sysdate, session_name, available_txn, delivered_txn,
             available_txn-delivered_txn as difference,
             builder_work_size, prepared_work_size,
            used_memory_size , max_memory_size
      FROM v$logmnr_session order by session_name; 
prompt
prompt <a href="#Summary">Return to Summary</a>


prompt
prompt ++ LOGMINER CACHE OBJECTS ++
prompt     Objects of interest for capture/apply from each source database
prompt
col count(*) format 9999999999999999  heading 'Number of|Interesting|DB Objects';

select logmnr_uid, count(*) from system.logmnrc_gtlo group by logmnr_uid;

prompt
prompt     Intcol Verification
prompt  

select logmnr_uid, obj#, objv#, intcol#
      from system.logmnrc_gtcs
      group by logmnr_uid, obj#, objv#, intcol#
      having count(1) > 1
      order by 1,2,3,4;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
REM prompt     Segcol Verification  
REM prompt  Check bug 7033630 if rows returned

REM  removed 8/26/2013
REM select a.logmnr_uid,a.obj#,a.objv#,a.segcol#, a.intcol# from system.logmnrc_gtcs a
REM   where exists ( select 1 from system.logmnrc_gtcs b where
REM                           a.logmnr_uid = b.logmnr_uid and
REM                           a.obj# = b.obj# and
REM                           a.objv# = b.objv# and
REM                           a.segcol# = b.segcol# and
REM                           a.segcol# <> 0 and
REM                           a.intcol# <> b.intcol#);


prompt
prompt  ++ LCR Cache Information ++
prompt    Internal LCRs
select * from x$kngfl order by streams_name_kngfl,colcount_kngfl;
prompt
prompt    External LCRs
select * from x$kngfle order by streams_name_kngfl,colcount_kngfl;
prompt
prompt
prompt    ++ <a name="Memory"><b>Streams Pool Statistics By INSTANCE</b> </a> ++
prompt      <a href="#Memory">Streams Pool Usage by Instance</a>   <a href="#CAP Memory">By Capture Session </a>   <a href="#APP Memory">By Apply Session</a>

col total_memory_allocated Head 'Total Memory|Allocated'
col current_size  Head 'Streams Pool|Size'
col SGA_TARGET_VALUE Head 'SGA_TARGET|Value'
col used Head 'Total Memory|Allocated (MB)'
col max  Head 'Streams Pool|Size(MB)'
col pct Head 'Percent Memory|Used'
col shrink_phase Head 'Shrink|Phase'
col Advice_disabled Head 'Advice|Disabled'

select * from gv$streams_pool_statistics;

prompt 
prompt 
select inst_id, TOTAL_MEMORY_ALLOCATED/(1024*1024) as used_MB,  CURRENT_SIZE/(1024*1024) as  max_MB,  decode(current_size, 0,to_number(null),(total_memory_allocated/current_size)*100) as pct_Streams_pool from gv$streams_pool_statistics;

prompt
prompt  ++ Queue Memory and Flow Control Values ++
prompt         FLCP_KWQBPMT is percent of streams_pool_size in use
prompt
select * from x$kwqbpmt;
prompt
prompt  ++ Streams Pool memory Information ++
prompt
col name heading 'NAME'
col value heading 'VALUE'

select * from x$knlasg;


prompt  ++ <a name="CAP Memory">Streams Pool Statistics for capture session</a> ++
prompt      <a href="#Memory">Streams Pool Usage by Instance</a>    <a href="#CAP Memory">By Capture Session </a>    <a href="#APP Memory">By Apply Session</a>
prompt   .  capture memory includes logminer memory
prompt
set serveroutput on
col used Head 'Total Memory|Used (MB)'
col alloced  Head 'Total Memory|Allocated(MB)'
col pct Head 'Percent of Allocated|Memory Used'
col captured Head 'Total LCRs|Captured'
col enqueued Head 'Total LCRs|Enqueued'

select capture_name,sga_used/(1024*1024) as used, sga_allocated/(1024*1024) as alloced, (sga_used/sga_allocated)*100 as pct,total_messages_captured as msgs_captured, total_messages_enqueued as msgs_enqueued from gv$goldengate_capture order by capture_name;


prompt
prompt  ++ Memory Used by Logminer Sessions ++
col used Head 'Total Memory|Used (MB)'
col max  Head 'Total Memory|Allocated(MB)'
col pct Head 'Percent of Allocated|Memory Used'
select session_name, l.USED_MEMORY_SIZE/(1024*1024) as used_MB, l.MAX_MEMORY_SIZE/(1024*1024) as max_MB,  (l.USED_MEMORY_SIZE/l.MAX_MEMORY_SIZE)*100 as pct_logminer_mem_used, decode(s.current_size, 0,to_number(null),(l.max_memory_size/s.current_size)*100) pct_streams_pool from gv$logmnr_session l, gv$streams_pool_statistics s where l.inst_id=s.inst_id order by session_name;



prompt
prompt  ++ <a name="APP Memory">Streams Pool Statistics for apply sessions </a> ++
prompt      <a href="#Memory">Streams Pool Usage by Instance</a>  <a href="#CAP Memory">By Capture Session </a>  <a href="#APP Memory">By Apply Session</a>
   
set serveroutput on
prompt  Streams Pool SGA configured for Replicat  (MAX_SGA_SIZE parameter)
prompt
col sga_configured heading 'Parameter|MAX_SGA_SIZE'
select apply_name,value sga_configured from dba_apply_parameters where parameter='MAX_SGA_SIZE'  order by apply_name;
prompt
prompt  Streams Pool SGA usage for Replicat
prompt
select Inst_id, apply_name,sga_used/(1024*1024) as used_MB, sga_allocated/(1024*1024) as alloced_MB, (sga_used/sga_allocated)*100 as pct, 
       total_messages_dequeued as msgs_dequeued from gv$gg_apply_reader order by apply_name;
prompt

prompt      <a href="#Memory">Streams Pool Usage by Instance</a>    <a href="#CAP Memory">By Capture Session </a>    <a href="#APP Memory">By Apply Session</a>

prompt
prompt  ++  Cache statistics summary ++  
prompt     valid only if executed on instance running capture
set lines 180

select CAPNAME_KNSTCAPCACHE as capture, CACHENAME_KNSTCAPCACHE as cache, NUM_LCRS_KNSTCAPCACHE as lcrs, NUM_COLS_KNSTCAPCACHE as cols, TOTAL_MEM_KNSTCAPCACHE/(1024*1024) as mem from x$knstcapcache order by 1,2;
prompt
prompt  ++  Cache statistics  ++  
select * from x$knstcapcache;


prompt 
prompt  ++ PGA Memory  ++
prompt         
prompt
col value format 999999999999999999
select * from gv$pgastat;
prompt

prompt 
prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt
Prompt   ++ JOBS in Database ++
prompt
set recsep each
set recsepchar =
select instance,job,what,log_user,priv_user,schema_user
      ,total_time,broken,interval,failures
      ,last_date,last_sec,this_date,this_sec,next_date,next_sec     
  from dba_jobs;

Prompt   ++ Scheduler Jobs in Database ++
prompt
select OWNER,JOB_NAME,JOB_SUBNAME,JOB_STYLE,JOB_CREATOR
,PROGRAM_OWNER,PROGRAM_NAME,JOB_TYPE,JOB_ACTION
,NUMBER_OF_ARGUMENTS
,SCHEDULE_OWNER,SCHEDULE_NAME,SCHEDULE_TYPE
,START_DATE,REPEAT_INTERVAL,END_DATE
,JOB_CLASS
,ENABLED
,AUTO_DROP
,RESTARTABLE
,STATE
,JOB_PRIORITY
,RUN_COUNT,MAX_RUNS,FAILURE_COUNT,MAX_FAILURES,RETRY_COUNT
,LAST_START_DATE,LAST_RUN_DURATION,NEXT_RUN_DATE,SCHEDULE_LIMIT,MAX_RUN_DURATION
,LOGGING_LEVEL
,STOP_ON_WINDOW_CLOSE
,INSTANCE_STICKINESS
,RAISE_EVENTS
,SYSTEM
,JOB_WEIGHT
,SOURCE
,NUMBER_OF_DESTINATIONS
,DESTINATION_OWNER
,DESTINATION
,CREDENTIAL_OWNER
,CREDENTIAL_NAME
,INSTANCE_ID
,DEFERRED_DROP
,ALLOW_RUNS_IN_RESTRICTED_MODE
 from dba_scheduler_jobs;

set recsep off



prompt
prompt ++ Agents ++
prompt
select * from dba_aq_agents;
prompt


prompt
prompt ++ Agent Privileges ++
prompt
select * from dba_aq_agent_privs;


prompt
prompt  ++  Current Long Running Transactions ++  
prompt   Current Database transactions open for more than 20 minutes
prompt
col runlength HEAD 'Txn Open|Minutes' format 9999.99
col sid HEAD 'Session' format a13
col xid HEAD 'Transaction|ID' format a18
col terminal HEAD 'Terminal' format a10
col program HEAD 'Program' format a27 wrap

select t.inst_id, sid||','||serial# sid,xidusn||'.'||xidslot||'.'||xidsqn xid, 
(sysdate -  start_date ) * 1440 runlength ,terminal,
program from gv$transaction t, gv$session s 
where t.addr=s.taddr and (sysdate - start_date) * 1440 > 20 order by runlength desc;

prompt




prompt ++ <a name="Alerts"> <b> ALERTS History </b></a> ++
prompt
prompt  +++ Outstanding alerts 
prompt

select message_type,creation_time,reason, suggested_action,
     module_id,object_type,
     instance_name||' (' ||instance_number||' )' Instance,
     time_suggested
from dba_outstanding_alerts 
   where creation_time >= sysdate -10 and rownum < 11
   order by creation_time desc;

prompt
prompt  +++ Most recent GoldenGate alerts(max=10) occuring within last 10 days +++
prompt
column Instance Heading 'Instance Name|(Instance Number)'
select message_Type,creation_time, reason,suggested_action,
       module_id,object_type,                    host_id,
       instance_name||'   ( '||instance_number||' )' Instance,      
       resolution,time_suggested
from dba_alert_history where message_group ='GoldenGate'
      and creation_time >= sysdate -10 and rownum < 11
order by creation_time desc;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt
REM prompt  ++  Current Contents of the STREAMS Pool ++  
REM prompt   Applies only to versions 10.1.0.4+, and to this instance only
REM prompt   Do not use this query - can cause database to hang or crash

REM col comm HEAD 'Allocation Comment' format A18
REM col alloc_size HEAD 'Bytes Allocated' format 9999999999999999
REM select ksmchcom comm, sum(ksmchsiz) alloc_size from x$ksmsst group by ksmchcom order by 2 desc;

prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  



prompt
prompt   ++ init.ora parameters ++
Prompt  Key parameters are aq_tm_processes, job_queue_processes
prompt                     streams_pool_size, sga_max_size, global_name, compatible
prompt                     
col type heading 'TYPE'

show parameters

set serveroutput on 
prompt  ++  <a name="Statistics"> <b>STATISTICS</b></a>  ++
prompt
alter session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';
set heading off 
set feedback off
select 'Oracle GoldenGate Integrated Extract/Replicat Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;
set heading on
set feedback on

prompt =========================================================================================
prompt
prompt ++ <a name="Queue Statistics">MESSAGES IN BUFFER QUEUE</a> ++
prompt
prompt

col QUEUE format a50 wrap
col "Message Count" format 9999999999999999 heading 'Current Number of|Outstanding|Messages|in Queue'
col "Spilled Msgs" format 9999999999999999 heading 'Current Number of|Spilled|Messages|in Queue'
col "TOtal Messages" format 9999999999999999 heading 'Cumulative |Number| of Messages|in Queue'
col "Total Spilled Msgs" format 9999999999999999 heading 'Cumulative Number|of Spilled|Messages|in Queue'
col "Expired_Msgs" heading 'Current Number of|Expired|Messages|in Queue'


SELECT queue_schema||'.'||queue_name Queue, startup_time, num_msgs "Message Count", spill_msgs "Spilled Msgs", cnum_msgs "Total Messages", cspill_msgs "Total Spilled Msgs", expired_msgs  FROM  gv$buffered_queues order by 1;

prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt
prompt  ++ Integrated Capture Information
prompt

col capture_name Heading 'Capture Name' format a20
col version  Heading 'Version'format a7

select capname_knstcap capture_name, decode(bitand(flags_knstcap,64), 64,'V2','<b> <a href="#SYSCheck">V1</a> </b>') version from x$knstcap order by version, capture_name;

prompt ============================================================================================
prompt
prompt ++ <a name="Capture Statistics">GOLDENGATE CAPTURE STATISTICS</a> ++
COLUMN PROCESS_NAME HEADING "Capture|Process|Number" FORMAT A7
COLUMN CAPTURE_NAME HEADING 'Capture|Name' FORMAT A10
COLUMN SID HEADING 'Session|ID' FORMAT 99999999999999
COLUMN SERIAL# HEADING 'Session|Serial|Number' 
COLUMN STATE HEADING 'State' FORMAT A17
column STATE_CHANGED_TIME HEADING 'Last|State Change|Time'
COLUMN TOTAL_MESSAGES_CAPTURED HEADING 'Redo Entries|Scanned'  
COLUMN TOTAL_MESSAGES_ENQUEUED HEADING 'Total|LCRs|Enqueued'  
COLUMN TOTAL_MESSAGES_CREATED HEADING 'Total|Messages|Created'  
COLUMN CAPTURE_TIME HEADING 'Capture Update|Timestamp'
Column PURPOSE  HEADING 'Capture|Purpose'
column CCA Heading 'CCA?'
column SGA_USED  Heading 'Streams Pool|Used|MB'
column SGA_ALLOCATED Heading 'Streams Pool| Allocated|MB'
column BYTES_MINED Heading 'Redo|Mined|MB '
column SESSION_RESTART_SCN Heading 'SCN at |Startup'

COLUMN LATENCY_SECONDS HEADING 'Latency|Seconds' FORMAT 9999999999999999
COLUMN CREATE_TIME HEADING 'Event Creation|Time' FORMAT A19
COLUMN ENQUEUE_TIME HEADING 'Last|Enqueue |Time' FORMAT A19
COLUMN ENQUEUE_MESSAGE_NUMBER HEADING 'Last Queued|Message Number' FORMAT 9999999999999999
COLUMN ENQUEUE_MESSAGE_CREATE_TIME HEADING 'Last Queued|Message|Create Time'FORMAT A19
COLUMN CAPTURE_MESSAGE_CREATE_TIME HEADING 'Last Redo|Message|Create Time' FORMAT A19
COLUMN CAPTURE_MESSAGE_NUMBER HEADING 'Last Redo|Message Number' FORMAT 9999999999999999
COLUMN AVAILABLE_MESSAGE_CREATE_TIME HEADING 'Available|Message|Create Time' FORMAT A19
COLUMN AVAILABLE_MESSAGE_NUMBER HEADING 'Available|Message Number' FORMAT 9999999999999999
COLUMN STARTUP_TIME HEADING 'Startup Timestamp' FORMAT A19

COLUMN MSG_STATE HEADING 'Message State' FORMAT A13
COLUMN CONSUMER_NAME HEADING 'Consumer' FORMAT A30

COLUMN PROPAGATION_NAME HEADING 'Propagation' FORMAT A8
COLUMN START_DATE HEADING 'Start Date'
COLUMN PROPAGATION_WINDOW HEADING 'Duration' FORMAT 99999
COLUMN NEXT_TIME HEADING 'Next|Time' FORMAT A8
COLUMN LATENCY HEADING 'Latency|Seconds' FORMAT 99999999


-- ALTER session set nls_date_format='YYYY-MM-DD HH24:Mi:SS';

SELECT sysdate,SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME,
       c.CAPTURE_NAME,
       C.STARTUP_TIME,
       c.SID,
       c.SERIAL#,
       DECODE (c.STATE,'WAITING FOR CLIENT REQUESTS','<b><a href="#Performance Checks">'||c.state||'</a></b>',
                'WAITING FOR INACTIVE DEQUEUERS','<b><a href="#Notification">'||c.state||'</a></b>',
                'WAITING FOR TRANSACTION;WAITING FOR CLIENT','<b><a href="#Performance Checks">'||c.state||'</a></b>',
                c.state) State,
       c.state_changed_time,
       c.TOTAL_MESSAGES_CAPTURED,
       c.TOTAL_MESSAGES_ENQUEUED, 
       c.sga_used/1024/1024 sga_used,
       c.sga_allocated/1024/1024 sga_allocated,
       c.bytes_of_redo_mined/1024/1024 bytes_mined,
       c.session_restart_scn
  FROM gV$GOLDENGATE_CAPTURE c, gV$SESSION s
  WHERE c.SID = s.SID AND
        c.SERIAL# = s.SERIAL#   order by c.capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>



SELECT capture_name, 
   SYSDATE "Current Time",
   capture_time "Capture Process TS",
   capture_message_number,
   capture_message_create_time ,
   enqueue_time ,
   enqueue_message_number,
   enqueue_message_create_time ,
   available_message_number,
   available_message_create_time,
   session_restart_scn    
FROM gV$GOLDENGATE_CAPTURE  order by capture_name;
prompt
prompt <a href="#Summary">Return to Summary</a>


COLUMN processed_scn HEADING 'Logminer Last|Processed Message' FORMAT 9999999999999999
COLUMN AVAILABLE_MESSAGE_NUMBER HEADING 'Last Message|Written to Redo' FORMAT 9999999999999999
SELECT c.capture_name, l.processed_scn, c.available_message_number
FROM gV$LOGMNR_SESSION l, gv$GOLDENGATE_CAPTURE c
WHERE c.logminer_id = l.session_id order by c.capture_name;

COLUMN CAPTURE_NAME HEADING 'Capture|Name' FORMAT A15
COLUMN TOTAL_PREFILTER_DISCARDED HEADING 'Prefilter|Events|Discarded' FORMAT 9999999999999999
COLUMN TOTAL_PREFILTER_KEPT HEADING 'Prefilter|Events|Kept' FORMAT 9999999999999999
COLUMN TOTAL_PREFILTER_EVALUATIONS HEADING 'Prefilter|Evaluations' FORMAT 9999999999999999
COLUMN UNDECIDED HEADING 'Undecided|After|Prefilter' FORMAT 9999999999999999
COLUMN TOTAL_FULL_EVALUATIONS HEADING 'Full|Evaluations' FORMAT 9999999999999999

SELECT CAPTURE_NAME,
       TOTAL_PREFILTER_DISCARDED,
       TOTAL_PREFILTER_KEPT,
       TOTAL_PREFILTER_EVALUATIONS,
       (TOTAL_PREFILTER_EVALUATIONS - 
         (TOTAL_PREFILTER_KEPT + TOTAL_PREFILTER_DISCARDED)) UNDECIDED,
       TOTAL_FULL_EVALUATIONS
  FROM gV$GOLDENGATE_CAPTURE order by capture_name;

column elapsed_capture HEADING 'Elapsed Time|Capture|(centisecs)'
column elapsed_rule HEADING 'Elapsed Time|Rule Evaluation|(centisecs)'
column elapsed_enqueue HEADING 'Elapsed Time|Enqueuing Messages|(centisecs)'
column elapsed_lcr HEADING 'Elapsed Time|LCR Creation|(centisecs)'
column elapsed_redo HEADING 'Elapsed Time|Redo Wait|(centisecs)'
column elapsed_Pause HEADING 'Elapsed Time|Paused|(centisecs)'

SELECT CAPTURE_NAME, ELAPSED_CAPTURE_TIME elapsed_capture,  
       elapsed_rule_time elapsed_rule,        
       ELAPSED_ENQUEUE_TIME 
       elapsed_enqueue, 
       ELAPSED_LCR_TIME elapsed_lcr,
       ELAPSED_REDO_WAIT_TIME elapsed_redo, 
       ELAPSED_PAUSE_TIME elapsed_pause,       
       total_messages_created,    total_messages_enqueued,     total_full_evaluations 
  from gv$GOLDENGATE_capture order by capture_name;

prompt
prompt <a href="#Summary">Return to Summary</a>


prompt ============================================================================================
prompt
prompt ++ LOGMINER STATISTICS  ++
prompt ++ (pageouts imply logminer spill) ++
COLUMN CAPTURE_NAME HEADING 'Capture|Name' FORMAT A32
COLUMN NAME HEADING 'Statistic' FORMAT A32
COLUMN VALUE HEADING 'Value' FORMAT 9999999999999999

select c.capture_name, name, value from gv$goldengate_capture c, gv$logmnr_stats l
 where c.logminer_id = l.session_id 
   and name in ('bytes paged out', 'pageout time (seconds)', 
                'bytes of redo mined', 'bytes checkpointed',
                'checkpoint time (seconds)',
                'resume from low memory', 'distinct txns in queue'
                  )
   order by 1,2;  
prompt
prompt      Logminer Session Stats for logminer chunks available to be CONSUMED (DIFFERENCE)  and Memory 
select sysdate, session_name, available_txn, delivered_txn,
             available_txn-delivered_txn as DIFFERENCE,
             builder_work_size, prepared_work_size,
            used_memory_size , max_memory_size
      FROM v$logmnr_session order by session_name; 
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt
prompt ==========================================================================
prompt
prompt ++ <a name="XStream Outbound Server Statistics">  EXTRACT CAPTURE SERVER STATISTICS  </a> ++
prompt
prompt ==========================================================================
prompt 
prompt

col sid HEADING 'Session id'
col serial# HEADING 'Serial#'
col state HEADING 'State'
col spid HEADING 'Spid'
col total_messages_sent HEADING 'Total|Messages|Sent'
col Server_name HEADING 'Outbound|Server|Name' format a22 wrap
col total_messages_sent heading 'Total|Messages|Sent' FORMAT 9999999999999999
col MESSAGE_SEQUENCE Heading 'Message within|Current transaction' 
col message_sequence FORMAT 9999999999999999
col last_sent_message_create_time HEADING 'Last Sent Message|Creation|Time'
col last_sent_message_number HEADING 'Last Sent|Message|SCN'
col last_sent_position HEADING 'Last Sent|Position'
col commitscn  Heading 'Source|Commit|SCN'
col commit_position Heading 'Source|Commit|Position'
col bytes_sent Heading 'Total Bytes|Sent'
col committed_data_only Heading 'Committed|Data|Only'
col startup_time Heading 'Server|Startup|Time'
col elapsed_send_time HEADING 'Elapsed|Send|Time'
col Send_time Heading 'Send Time'

select inst_id,server_sid,server_serial#,server_spid,extract_name,capture_name,startup_time,state,total_messages_sent,
last_sent_message_number,last_sent_message_create_time,send_time, elapsed_send_time,
bytes_sent from gv$goldengate_capture   order by capture_name;

prompt 
prompt ++  Outbound Progress Table ++
prompt
col processed_low_position format a40  wrap HEAD 'Processed|Low Position'
col processed_low_time format a40 wrap HEAD 'Processed|Low Position|Time'
col oldest_position format a40 wrap  HEAD 'Oldest|Position'
col source_database format a40 wrap HEAD 'Source DB|GlobalName' 


select server_name, source_database,
    processed_low_position,
    processed_low_time,
    oldest_position
  From dba_xstream_outbound_progress order by server_name;

prompt  ++  APPLY PROGRESS ++
col oldest_message_number HEADING 'Oldest|Message|SCN'
col apply_time HEADING 'Apply|Timestamp'
select ap.* from dba_apply_progress ap, dba_apply a where a.purpose like 'GoldenGate%' and ap.apply_name=a.apply_name and a.purpose like 'Golden%';


prompt
prompt ++ BUFFERED PUBLISHERS ++
prompt    
prompt
select * from gv$buffered_publishers;


prompt
prompt ++ OPEN GOLDENGATE CAPTURE TRANSACTIONS ++
prompt
prompt   This information is not available for V2 Integrated Capture
prompt
prompt +**   Count    **+
select component_name, count(*) "Open Transactions",sum(cumulative_message_count) "Total LCRs" from gv$goldengate_transaction where component_type='CAPTURE' group by component_name;

prompt
prompt ++  OPEN GOLDENGATE CAPTURE TRANSACTION DETAILS  ++
select * from gv$goldengate_transaction where component_type='CAPTURE' order by 
component_name,first_message_number;

prompt


prompt

prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  



col sid HEADING 'Session id'
col serial# HEADING 'Serial#'
col state HEADING 'State'
col spid HEADING 'Spid'
col total_messages_sent HEADING 'Total|Messages|Sent'
col Server_name HEADING 'Outbound|Server|Name' format a22 wrap
col total_messages_sent heading 'Total|Messages|Sent' FORMAT 9999999999999999
col MESSAGE_SEQUENCE Heading 'Message within|Current transaction' 
col message_sequence FORMAT 9999999999999999
col last_sent_message_create_time HEADING 'Last Sent Message|Creation|Time'
col last_sent_message_number HEADING 'Last Sent|Message|SCN'
col last_sent_position HEADING 'Last Sent|Position'
col commitscn  Heading 'Source|Commit|SCN'
col commit_position Heading 'Source|Commit|Position'
col bytes_sent Heading 'Total Bytes|Sent'
col committed_data_only Heading 'Committed|Data|Only'
col startup_time Heading 'Server|Startup|Time'
col elapsed_send_time HEADING 'Elapsed|Send|Time'
col Send_time Heading 'Send Time'




col processed_low_position format a40 wrap
col oldest_position format a40 wrap



prompt
prompt ++ BUFFERED SUBSCRIBERS ++
prompt    
prompt

select * from gv$buffered_subscribers order by subscriber_name;



prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt  ===========================================================================
prompt
prompt ++ <a name="GoldenGate Inbound Server Statistics"> GoldenGate Inbound Server Statistics </a> ++
prompt
prompt ============================================================================
prompt
prompt  ++ GoldenGate Table Statistics summaries
col Total_Operations Heading 'Total|Operations'
col Total_Inserts Heading 'Total|Inserts'
col Total_Updates Heading 'Total|Updates'
col Total_Deletes Heading 'Total|Deletes'
col Insert_collisions  Heading 'Insert|Collisions'
col Update_collisions  Heading 'Update|Collisions'
col Delete_collisions  Heading 'Delete|Collisions'
col Reperror_Discards  Heading 'Reperror|Discards'
col Reperror_Ignores   Heading 'Reperror|Ignores'
col Wait_Dependencies  Heading 'Wait|Dependencies'
col CDR_Insert_Row_Exists   Heading 'CDR Insert|Row Exists'
col CDR_Update_Row_Exists   Heading 'CDR Update|Row Exists'
col CDR_Update_Row_Missing  Heading 'CDR Update|Row Missing'
col CDR_Delete_Row_Exists   Heading 'CDR Delete|Row Exists'
col CDR_Delete_Row_Missing  Heading 'CDR Delete|Row Missing'
col CDR_Successful_Resolutions   Heading 'CDR Successful|Resolutions'
col CDR_Failed_Resolutions  Heading 'CDR Failed|Resolutions'
col CDR_Total_Resolutions   Heading 'CDR Total|Resolutions'


select server_name, 
sum(total_inserts+total_updates+total_deletes),
sum(total_inserts),sum(total_updates),sum(total_deletes),
sum(insert_collisions),sum(update_collisions),sum(delete_collisions),
sum(reperror_records),sum(reperror_ignores),
sum(wait_dependencies),
sum(cdr_insert_row_exists), 
sum(cdr_update_row_exists),sum(cdr_update_row_missing),
sum(cdr_delete_row_exists),sum(cdr_delete_row_missing),
sum(cdr_successful_resolutions),sum(cdr_failed_resolutions),sum(cdr_successful_resolutions+cdr_failed_resolutions) cdr_total_resolutions
from gv$goldengate_table_stats group by  server_name order by 1,2;

prompt ++  GoldenGate  TABLE STATISTICS by TABLE  ++

prompt 
select server_name, 
source_table_owner,source_table_name,destination_table_owner,destination_table_name, 
sum(total_inserts+total_updates+total_deletes),
sum(total_inserts),sum(total_updates),sum(total_deletes),
sum(insert_collisions),sum(update_collisions),sum(delete_collisions),
sum(reperror_records),sum(reperror_ignores),
sum(wait_dependencies),
sum(cdr_insert_row_exists), 
sum(cdr_update_row_exists),sum(cdr_update_row_missing),
sum(cdr_delete_row_exists),sum(cdr_delete_row_missing),
sum(cdr_successful_resolutions),sum(cdr_failed_resolutions),sum(cdr_successful_resolutions+cdr_failed_resolutions) cdr_total_resolutions
from gv$goldengate_table_stats group by  server_name, source_table_owner,source_table_name,destination_table_owner,destination_table_name order by 1,2,3,4,5;

prompt

prompt


prompt **  GoldenGate Inbound Progress Table **
prompt
prompt
col applied_low_scn noprint

select * From dba_gg_inbound_progress order by server_name;


prompt
prompt ============================================================================
prompt
prompt ++ <a name="Apply Statistics">APPLY STATISTICS</a> ++
prompt
prompt ============================================================================================
prompt
prompt ++ APPLY Receiver Statistics ++
Column APPLY_NAME HEADING 'Apply|Name'  
column sid format 99999999999
column serial# format 99999999999

Select inst_id, sid, serial# , apply_name, startup_time,
       source_database_name,
       total_messages_received,
       total_available_messages,
       DECODE (STATE,'Waiting for memory','<b><a href="#APP Memory"> Waiting for memory</a></b>',    
           state) rcvstate,     
       last_received_msg_position,
       acknowledgement_position 
   from gv$gg_apply_receiver order by apply_name;




prompt
prompt ++ APPLY Reader Statistics ++
col oldest_scn_num HEADING 'Oldest|SCN'
col apply_name HEADING 'Apply Name'
col apply_captured HEADING 'Captured or|User-Enqueued LCRs'
col process_name HEADING 'Process'
col state HEADING 'STATE'
col total_messages_dequeued HEADING 'Total Messages|Dequeued'
col total_messages_spilled Heading 'Total Messages|Spilled'
col sga_used HEADING 'SGA Used|MB'
col sga_allocated HEADING 'SGA Allocated|MB'
col oldest_transaction_id HEADING 'Oldest|Transaction'
col total_lcrs_with_dep HEADING 'Total|LCRs with|Dependencies'
col total_lcrs_with_wmdep HEADING 'Total|LCRs with|WM Dependency'
col total_in_memory_lcrs HEADING 'Total|in-Memory|LCRs'
col unassigned_complete_txns HEADING 'Unassigned|Complete|Txns'
col auto_txn_buffer_size HEADING 'Auto|TXN Buffer|Size'

SELECT ap.APPLY_NAME,
       DECODE(ap.APPLY_CAPTURED,
                'YES','Captured LCRS',
                'NO','User-Enqueued','UNKNOWN') APPLY_CAPTURED,
       SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME,
       r.STATE,
       r.TOTAL_MESSAGES_DEQUEUED,
       r.TOTAL_MESSAGES_SPILLED,
       r.SGA_USED/1024/1024 sga_used, 
       r.sga_allocated/1024/1024 sga_allocated,
       r.oldest_transaction_id,
       total_lcrs_with_dep,
       total_lcrs_with_wmdep,
       total_in_memory_lcrs
       FROM gV$GG_APPLY_READER r, gV$SESSION s, DBA_APPLY ap
       WHERE r.SID = s.SID AND
             r.SERIAL# = s.SERIAL# AND
             r.APPLY_NAME = ap.APPLY_NAME  order by ap.apply_name;


col creation HEADING 'Dequeued Message|Creation|Timestamp'
col last_dequeue HEADING 'Dequeue |Timestamp'
col dequeued_message_number HEADING 'Last |Dequeued Message|Number'
col last_browse_num HEADING 'Last|Browsed Message|Number'
col latency HEADING 'Apply Reader|Latency|(Seconds)'

SELECT APPLY_NAME,
       (DEQUEUE_TIME-DEQUEUED_MESSAGE_CREATE_TIME)*86400 LATENCY,
     TO_CHAR(DEQUEUED_MESSAGE_CREATE_TIME,'HH24:MI:SS MM/DD') CREATION,
     TO_CHAR(DEQUEUE_TIME,'HH24:MI:SS MM/DD') LAST_DEQUEUE, 
     DEQUEUED_POSITION
  FROM gV$GG_APPLY_READER  order by apply_name;
prompt
prompt <a href="#Summary">Return to Summary</a>

col elapsed_dequeue HEADING 'Elapsed Time|Dequeue|(centisecs)'
col elapsed_schedule HEADING 'Elapsed Time|Schedule|(centisecs)'
col elapsed_spill HEADING 'Elapsed Time|Spill|(centisecs)'
col elapsed_idle HEADING 'Elapsed Time|Idle|(centisecs)'

REM   Select APPLY_NAME, total_messages_dequeued, total_messages_spilled,         Elapsed_dequeue_time Elapsed_dequeue, 
REM        elapsed_schedule_time elapsed_schedule, 
REM        elapsed_spill_time elapsed_spill
REM   from gv$GG_APPLY_READER  order by apply_name;




prompt ============================================================================================
prompt
prompt ++ APPLY Coordinator Statistics ++
col apply_name HEADING 'Apply Name' format a22 wrap
col process HEADING 'Process' format a7
col RECEIVED HEADING 'Total|Txns|Received' 
col ASSIGNED HEADING 'Total|Txns|Assigned' 
col APPLIED HEADING 'Total|Txns|Applied' 
col ERRORS HEADING 'Total|Txns|w/ Error' 
col total_ignored HEADING 'Total|Txns|Ignored' 
col total_rollbacks HEADING 'Total|Txns|Rollback' 
col WAIT_DEPS HEADING 'Total|Txns|Wait_Deps' 
col WAIT_COMMITS HEADING 'Total|Txns|Wait_Commits' 
col STATE HEADING 'State' format a10 word
col active_server_count HEADING 'Active|Server|Count'
prompt
prompt Active server count is the count of apply servers that are eligible to process transactions
prompt


SELECT ap.APPLY_NAME,
       SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS,
       c.STATE,
       c.TOTAL_RECEIVED RECEIVED,
       c.TOTAL_ASSIGNED ASSIGNED,
       c.TOTAL_APPLIED APPLIED,
       c.TOTAL_ERRORS ERRORS,
       c.total_ignored,
       c.total_rollbacks,
       c.TOTAL_WAIT_DEPS WAIT_DEPS, c.TOTAL_WAIT_COMMITS WAIT_COMMITS,
       c.unassigned_complete_txns, active_server_count
       FROM gV$GG_APPLY_COORDINATOR  c, gV$SESSION s, DBA_APPLY ap
       WHERE c.SID = s.SID AND
             c.SERIAL# = s.SERIAL# AND
             c.APPLY_NAME = ap.APPLY_NAME  order by ap.apply_name;

col lwm_msg_ts HEADING 'LWM Message|Creation|Timestamp'
col lwm_msg_nbr HEADING 'LWM Message|SCN'
col lwm_updated HEADING 'LWM Updated|Timestamp'
col hwm_msg_ts HEADING 'HWM Message|Creation|Timestamp'
col hwm_msg_nbr HEADING 'HWM Message|SCN'
col hwm_updated HEADING 'HWM Updated|Timestamp'
col LWM_POSITION HEADING 'XStream LWM|Position'
col HWM_POSITION  HEADING 'XStream HWM|Position'
col PROCESSED_MESSAGE_NUMBER  HEADING 'XStream Processed|Position'



SELECT APPLY_NAME,
     LWM_MESSAGE_CREATE_TIME LWM_MSG_TS ,
     LWM_MESSAGE_NUMBER LWM_MSG_NBR ,
     LWM_TIME LWM_UPDATED,
     HWM_MESSAGE_CREATE_TIME HWM_MSG_TS,
     HWM_MESSAGE_NUMBER HWM_MSG_NBR ,
     HWM_TIME HWM_UPDATED,
     LWM_POSITION,
     HWM_POSITION,
     PROCESSED_MESSAGE_NUMBER
  FROM gV$GG_APPLY_COORDINATOR;

SELECT APPLY_NAME,      TOTAL_RECEIVED,TOTAL_ASSIGNED,TOTAL_APPLIED,
     STARTUP_TIME,
     ELAPSED_SCHEDULE_TIME elapsed_schedule, 
     ELAPSED_IDLE_TIME  elapsed_idle
from gv$GG_apply_coordinator order by apply_name;
prompt
prompt <a href="#Summary">Return to Summary</a>
     
prompt ============================================================================================
prompt
prompt  ++ APPLY Server Statistics ++
col SRVR format 9999
col ASSIGNED format 9999999999999999 Heading 'Total|Transactions|Assigned'
col MSG_APPLIED heading 'Total|Messages|Applied' FORMAT 9999999999999999
col MESSAGE_SEQUENCE FORMAT 9999999999999999
col applied_message_create_time HEADING 'Applied Message|Creation|Timestamp'
col applied_message_number HEADING 'Last Applied|Message|SCN'
col lwm_updated HEADING 'Applied|Timestamp'
col message_sequence HEADING 'Message|Sequence'
col elapsed_apply_time HEADING 'Elapsed|Apply|Time (cs)'
col elapsed_dequeue_time HEADING 'Elapsed|Dequeue|Time (cs)'
col apply_time Heading 'Apply Time'
col total_lcrs_retried HEADING 'Total|LCRs|Retried'
col total_txns_retried HEADING 'Total|TXNs|Retried'
col total_txns_recorded HEADING 'Total|TXNs|Recorded'
col lcr_retry_iteration HEADING 'LCR Retry|Iteration'
col txn_retry_iteration HEADING 'TXN Retry|Iteration'
col TOTAL_ASSIGNED format 9999999999999999 Heading 'Total|Transactions|Assigned'
col TOTAL_MESSAGES_APPLIED heading 'Total|Messages|Applied' FORMAT 9999999999999999
col cnt HEADING 'Total|Apply|Servers'
col current_txn format a15 wrap


prompt 
prompt     Apply Server TOTALs Summary
prompt
select apply_name, count(*) cnt, sum(a.total_assigned) total_assigned, sum(a.total_messages_applied) total_messages_applied,
       sum(a.total_lcrs_retried) total_lcrs_retried,
       sum(a.total_txns_retried) total_txns_retried,
       sum(a.total_txns_recorded) total_txns_recorded
      FROM gV$GG_APPLY_SERVER a
       group by apply_name  ;

prompt
prompt    Apply Server Details
prompt
SELECT ap.APPLY_NAME,
       SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME,
       a.server_id SRVR,
       a.STATE,
       a.sid, a.serial#,
       a.TOTAL_ASSIGNED ASSIGNED,
       a.TOTAL_MESSAGES_APPLIED msg_APPLIED,
       a.MESSAGE_SEQUENCE,
       a.lcr_retry_iteration,
       a.txn_retry_iteration,
       a.total_lcrs_retried,
       a.total_txns_retried,
       a.total_txns_recorded,
       a.xidusn||'.'||a.xidslt||'.'||a.xidsqn CURRENT_TXN,
       a.elapsed_apply_time, a.apply_time,
       s.logon_time
       FROM gV$GG_APPLY_SERVER a, gV$SESSION s, DBA_APPLY ap
       WHERE a.SID = s.SID AND
             a.SERIAL# = s.SERIAL# AND
             a.APPLY_NAME = ap.APPLY_NAME order by a.apply_name, a.server_id;

prompt   Apply Server 0 Statistics (aggregated stats for apply servers that have been autotuned away)
prompt
SELECT ap.APPLY_NAME,
       a.server_id SRVR,
       a.STATE,
       a.TOTAL_ASSIGNED ASSIGNED,
       a.TOTAL_MESSAGES_APPLIED msg_APPLIED,
       a.MESSAGE_SEQUENCE,
       a.lcr_retry_iteration,
       a.txn_retry_iteration,
       a.total_lcrs_retried,
       a.total_txns_retried,
       a.total_txns_recorded,
       a.elapsed_apply_time, a.apply_time
       FROM gV$GG_APPLY_SERVER a,  DBA_APPLY ap
       WHERE a.server_id = 0 and 
             a.APPLY_NAME = ap.APPLY_NAME order by a.apply_name, a.server_id;
prompt
prompt <a href="#Summary">Return to Summary</a>


Col apply_name Heading 'Apply Name' FORMAT A30
Col server_id Heading 'Apply Server Number' FORMAT 99999999
Col sqltext Heading 'Current SQL' FORMAT A64


prompt     Using V$SQL
select a.inst_id, a.apply_name,  a.server_id, a.state, a.total_messages_applied,q.sql_id,q.sql_fulltext sqltext
  from gv$GG_apply_server a, gv$sql q, gv$session s
 where a.sid = s.sid and a.serial#=s.serial#
   and a.inst_id = s.inst_id 
   and s.sql_hash_value = q.hash_value 
   and s.sql_address = q.address and s.sql_id = q.sql_id 
 order by a.apply_name, a.server_id;

Col apply_name Heading 'Apply Name' FORMAT A30
Col server_id Heading 'Apply Server Number' FORMAT 99999999
Col event Heading 'Wait Event' FORMAT A64
Col secs Heading 'Seconds Waiting' FORMAT 9999999999999999

select a.inst_id, a.apply_name, a.server_id, w.event, w.seconds_in_wait secs
  from gv$GG_apply_server a, gv$session_wait w 
 where a.sid = w.sid   
   and a.inst_id = w.inst_id
order by a.apply_name, a.server_id;

Col apply_name Heading 'Apply Name' FORMAT A30
Col server_id Heading 'Apply Server Number' FORMAT 99999999
Col event Heading 'Wait Event' FORMAT 99999999
Col total_waits Heading 'Total Waits' FORMAT 9999999999999999
Col total_timeouts Heading 'Total Timeouts' FORMAT 9999999999999999
Col time_waited Heading 'Time Waited' FORMAT 9999999999999999
Col average_wait Heading 'Average Wait' FORMAT 9999999999999999
Col max_wait Heading 'Maximum Wait' FORMAT 9999999999999999

select a.inst_id, a.apply_name, a.server_id, e.event, e.total_waits, e.total_timeouts,
       e.time_waited, e.average_wait, e.max_wait 
  from gv$GG_apply_server a, gv$session_event e
 where a.sid = e.sid  
     and a.inst_id = e.inst_id
order by a.apply_name, a.server_id,e.time_waited desc;
prompt
prompt <a href="#Summary">Return to Summary</a>


col current_txn format a15 wrap
col dependent_txn Heading 'Dependent|Transaction' format a15 wrap
col dep_commit_position Heading 'Dependent|Commit Position' 

prompt

prompt    Apply server transactions ordered by server_id
prompt
select a.inst_id,a.APPLY_NAME, 
   SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME,
   server_id SRVR,a.state,
   a.TOTAL_ASSIGNED ASSIGNED,
   a.TOTAL_MESSAGES_APPLIED msg_APPLIED,
   xidusn||'.'||xidslt||'.'||xidsqn CURRENT_TXN,
   commitscn, 
   dep_xidusn||'.'||dep_xidslt||'.'||dep_xidsqn DEPENDENT_TXN,
   dep_commit_position, 
   message_sequence,
   apply_time
FROM gV$GG_APPLY_SERVER a, gV$SESSION s
WHERE a.SID = s.SID AND
a.SERIAL# = s.SERIAL# 
order by a.apply_name,a.server_id;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt

prompt    Apply server transactions ordered by source commitscn and dependent transaction scns.
prompt
select a.APPLY_NAME, 
   SUBSTR(s.PROGRAM,INSTR(S.PROGRAM,'(')+1,4) PROCESS_NAME,
   server_id SRVR,a.state,
   a.TOTAL_ASSIGNED ASSIGNED,
   a.TOTAL_MESSAGES_APPLIED msg_APPLIED,
   xidusn||'.'||xidslt||'.'||xidsqn CURRENT_TXN,
   commitscn, 
   dep_xidusn||'.'||dep_xidslt||'.'||dep_xidsqn DEPENDENT_TXN,
   dep_commit_position, 
   message_sequence,
   apply_time
FROM gV$GG_APPLY_SERVER a, gV$SESSION s
WHERE a.SID = s.SID AND
a.SERIAL# = s.SERIAL# 
 order by a.apply_name,a.commitscn, a.dep_commit_position;
prompt
prompt <a href="#Summary">Return to Summary</a>

prompt

prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt
prompt  ++  APPLY PROGRESS ++
col oldest_message_number HEADING 'Oldest|Message|SCN'
col apply_time HEADING 'Apply|Timestamp'
select * from dba_apply_progress order by apply_name;


prompt ============================================================================================
prompt
prompt ++ OPEN GoldenGate APPLY TRANSACTIONS ++
prompt
prompt +**   Count    **+
select component_name, count(*) "Open Transactions",sum(cumulative_message_count) "Total LCRs" from gv$Goldengate_transaction where component_type='APPLY' group by component_name;

prompt
prompt +**   Detail    **+
select * from gv$goldengate_transaction where component_type='APPLY' order by component_name,first_message_number;
prompt



prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  

prompt

prompt
prompt  ++ <a name=Topology> Replication Topology </a> ++
prompt

exec dbms_streams_advisor_adm.ANALYZE_CURRENT_PERFORMANCE ;
exec dbms_lock.sleep(5);
exec dbms_streams_advisor_adm.ANALYZE_CURRENT_PERFORMANCE;
exec dbms_lock.sleep(5);
exec dbms_streams_advisor_adm.ANALYZE_CURRENT_PERFORMANCE;

REM exec utl_spadv.show_stats

column global_name format a50

column component_id format 9999999
column component_name  format a25 wrap
column component_db    format a25 wrap
column component_type  format a20 wrap

column fromm Heading 'FROM|Component' format 99999
column source_component_id format 9999999
column source_component_name  HEADING 'Source|Component' format a25 wrap
column source_component_db  HEADING 'Source |Database'  format a25 wrap
column source_component_type HEADING 'Type' format a20 wrap
column destination_component_id format 9999999
column destination_component_name HEADING 'Destination|Component' format a25 wrap
column destination_component_db  HEADING 'Destination|Database'  format a25 wrap
column destination_component_type Heading 'Type' format a20 wrap
column too heading 'TO |Component'  format 99999
column top_session_id HEADING 'Top|Session SID'  format 999999
column top_session_serial# HEADING 'Top|Session Serial#' format 999999

prompt  ++  Topology Databases ++
prompt
select * from dba_streams_tp_database;

prompt
prompt  ++  Replication Components ++
prompt
select * from dba_streams_tp_component order by component_id;

prompt  ++ Replication Component Statistics ++
prompt 
select advisor_run_id
, component_id, component_name, component_db, component_type, sub_component_type
, statistic_time, statistic_name, statistic_value, statistic_unit
, session_id, session_serial#  
,  advisor_run_time
 from dba_streams_tp_component_stat   order by component_id, advisor_run_id,statistic_name;

prompt
prompt  ++  Active Paths ++
prompt
select path_id,position,source_component_id fromm,source_component_db,source_component_name,source_component_type,
destination_component_id too,destination_component_db, destination_component_name,destination_component_type
 from dba_streams_tp_component_link  order by path_id,position;

prompt
-- prompt
-- prompt  ++  Path Highest Activity Process (Bottleneck) ++
-- prompt

select * from dba_streams_tp_path_bottleneck where bottleneck_identified='YES' and advisor_run_id =(select  max(advisor_run_id) from dba_streams_tp_path_bottleneck )order by path_id, advisor_run_id;


prompt  ++  Path Statistics ++
prompt
col latency format a15
col transaction_rate format a40
col message_rate format a40
select path_id,statistic_time
                 ,max(case when statistic_name='LATENCY' then statistic_value||' '||statistic_unit end) latency
                 ,max(case when statistic_name='TRANSACTION RATE' then statistic_value||' '||statistic_unit end) transaction_rate
                 ,max(case when statistic_name='MESSAGE RATE' then statistic_value||' '||statistic_unit end) message_rate
from dba_streams_tp_path_stat
group by path_id,statistic_time
order by 1,2;


prompt
prompt  ++  GoldenGate Message Tracking ++
prompt
col message_number Heading 'Message|Number'
col tracking_label Heading 'Tracking|Label'
col Component_name Heading 'Component|Name'
col Component_type Heading 'Component|Type'
col action Heading 'Action'
col action_details Heading 'Action|Details'
col Message_creation_time Heading 'Message Creation|Time'
col tracking_id Heading 'Tracking|ID'
col source_database_name Heading 'Source|Database'
col object_owner Heading 'Owner|Name'
col object_name Heading 'Object|Name'
col command_type Heading 'Command|Type'
col message_position Heading 'Message|Position'

select * from gv$goldengate_message_tracking order by tracking_label,timestamp;
prompt

prompt
prompt ++   STATISTICS on RULES and RULE SETS  ++
prompt ++
prompt ++   RULE SET STATISTICS  ++
prompt

col name HEADING 'Name'

select * from gv$rule_set;




prompt
prompt ++  RULE STATISTICS  ++
prompt

select * from gv$rule;
prompt

prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  


prompt ================================================================================
prompt ++ <a name="Wait Analysis"><b>Replication Process Wait Analysis</b></a> ++ 


prompt
set lines 180
set numf 9999999999999
set pages 9999
set verify OFF

COL BUSY FORMAT A4
COL PERCENTAGE FORMAT 999D9
COL event wrapped

-- This variable controls how many minutes in the past to analyze
DEFINE minutes_to_analyze = 30

prompt  Analysis of last &minutes_to_analyze minutes of Replication processes
prompt

PROMPT Note:  When computing the busiest component, be sure to subtract the percentage where BUSY = 'NO'
PROMPT Note:  'no rows selected' means that the process was performing no busy work, or that no such process exists on the system.
PROMPT Note:  A null Wait Event implies running - either on the cpu or waiting for cpu

prompt
prompt ++ LOGMINER READER PROCESSES ++

COL LOGMINER_READER_NAME FORMAT A30 WRAP
BREAK ON LOGMINER_READER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON LOGMINER_READER_NAME;
SELECT c.capture_name || ' - reader' as logminer_reader_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$logmnr_process lp, v$goldengate_capture c
WHERE lp.SID = ash_capture.SESSION_ID 
  AND lp.serial# = ash_capture.SESSION_SERIAL#
  AND lp.role = 'reader' and lp.session_id = c.logminer_id
ORDER BY logminer_reader_name, percentage;

prompt
prompt ++ LOGMINER PREPARER PROCESSES ++

COL LOGMINER_PREPARER_NAME FORMAT A30 WRAP
BREAK ON LOGMINER_PREPARER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON LOGMINER_PREPARER_NAME;
SELECT c.capture_name || ' - preparer' || lp.spid as logminer_preparer_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$logmnr_process lp, v$goldengate_capture c
WHERE lp.SID = ash_capture.SESSION_ID 
  AND lp.serial# = ash_capture.SESSION_SERIAL#
  AND lp.role = 'preparer' and lp.session_id = c.logminer_id
ORDER BY logminer_preparer_name, percentage;

prompt
prompt ++ LOGMINER BUILDER PROCESSES ++

COL LOGMINER_BUILDER_NAME FORMAT A30 WRAP
BREAK ON LOGMINER_BUILDER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON LOGMINER_BUILDER_NAME;
SELECT c.capture_name || ' - builder' as logminer_builder_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$logmnr_process lp, v$goldengate_capture c
WHERE lp.SID = ash_capture.SESSION_ID 
  AND lp.serial# = ash_capture.SESSION_SERIAL#
  AND lp.role = 'builder' and lp.session_id = c.logminer_id
ORDER BY logminer_builder_name, percentage;


prompt
prompt ++ CAPTURE PROCESSES ++

COL CAPTURE_NAME FORMAT A30 WRAP
BREAK ON CAPTURE_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON CAPTURE_NAME;
SELECT c.capture_name, 
       ash_capture.event_count, ash_total.total_count, 
       ash_capture.event_count*100/ash_total.total_count percentage, 
       DECODE(ash_capture.event, 
              'REPL Capture: subscribers to catch up', 'NO',
              'REPL Capture/Apply: memory', 'NO',
              'REPL Capture: archive log', 'NO',
              'YES') busy,
       ash_capture.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash_capture,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$goldengate_capture c
WHERE c.SID = ash_capture.SESSION_ID and c.serial# = ash_capture.SESSION_SERIAL#
ORDER BY capture_name, percentage;




prompt
prompt ++  OUTBOUND  SERVER PROCESSES ++

COL SERVER_NAME FORMAT A30 WRAP
BREAK ON SERVER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON SERVER_NAME;
SELECT a.server_name ,
       ash.event_count, ash_total.total_count, 
       ash.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$xstream_outbound_server a
WHERE a.sid = ash.SESSION_ID and a.serial# = ash.SESSION_SERIAL#
ORDER BY server_name, percentage;
prompt
prompt -------------------------------------------------------------

prompt
prompt ++ APPLY RECEIVER PROCESSES ++

COL PROPAGATION_RECEIVER_NAME FORMAT A30 WRAP
BREAK ON PROPAGATION_RECEIVER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON PROPAGATION_RECEIVER_NAME;
SELECT ('"'||vpr.src_queue_schema||'"."'||vpr.src_queue_name||
          '@' || vpr.src_dbname|| '"=>'||global_name) 
          as propagation_receiver_name,
       ash.event_count, ash_total.total_count, 
       ash.event_count*100/ash_total.total_count percentage, 
       DECODE(ash.event, 
              'Streams AQ: enqueue blocked on low memory', 'NO',
              'Streams AQ: enqueue blocked due to flow control', 'NO',
              'REPL Capture/Apply: flow control', 'NO',
              'REPL Capture/Apply: memory','NO',
              'YES') busy,
       ash.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$propagation_receiver vpr, x$kwqpd xpd, global_name
WHERE xpd.kwqpdsid = ash.SESSION_ID and xpd.kwqpdser = ash.SESSION_SERIAL#
  AND xpd.kwqpdsqn = vpr.src_queue_name 
  AND xpd.kwqpdsqs = vpr.src_queue_schema and xpd.kwqpddbn = vpr.src_dbname
ORDER BY propagation_receiver_name, percentage;



prompt
prompt ++ APPLY READER PROCESSES ++

COL APPLY_READER_NAME FORMAT A30 WRAP
BREAK ON APPLY_READER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON APPLY_READER_NAME;
SELECT a.apply_name as apply_reader_name,
       ash.event_count, ash_total.total_count, 
       ash.event_count*100/ash_total.total_count percentage, 
       DECODE(ash.event, 
              'rdbms ipc message', 'NO',
              'YES') busy,
       ash.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$gg_apply_reader a
WHERE a.sid = ash.SESSION_ID and a.serial# = ash.SESSION_SERIAL#
ORDER BY apply_reader_name, percentage;



prompt
prompt ++ APPLY COORDINATOR PROCESSES ++

COL APPLY_COORDINATOR_NAME FORMAT A30 WRAP
BREAK ON APPLY_COORDINATOR_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON APPLY_COORDINATOR_NAME;
SELECT a.apply_name as apply_coordinator_name,
       ash.event_count, ash_total.total_count, 
       ash.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$gg_apply_coordinator a
WHERE a.sid = ash.SESSION_ID and a.serial# = ash.SESSION_SERIAL#
ORDER BY apply_coordinator_name, percentage;



prompt
prompt ++ APPLY SERVER PROCESSES ++

COL APPLY_SERVER_NAME FORMAT A30 WRAP
BREAK ON APPLY_SERVER_NAME;
COMPUTE SUM LABEL 'TOTAL' OF PERCENTAGE ON APPLY_SERVER_NAME;
SELECT a.apply_name || ' - ' || a.server_id as apply_server_name,
       ash.event_count, ash_total.total_count, 
       ash.event_count*100/ash_total.total_count percentage, 
       'YES' busy,
       ash.event
FROM (SELECT SESSION_ID,
             SESSION_SERIAL#,
             EVENT,
             COUNT(sample_time) AS EVENT_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60
       GROUP BY session_id, session_serial#, event) ash,
     (SELECT COUNT(DISTINCT sample_time) AS TOTAL_COUNT
       FROM  v$active_session_history
       WHERE sample_time > sysdate - &minutes_to_analyze/24/60) ash_total,
     v$gg_apply_server a
WHERE a.sid = ash.SESSION_ID and a.serial# = ash.SESSION_SERIAL#
ORDER BY apply_server_name, percentage;



prompt
prompt Configuration: <a href="#Database">Database</a>  <a href="#Queues in Database">Queue</a>   <a href="#Administrators">Administrators</a>   <a href="#Bundle">Bundle</a> 
prompt Extract: <a href="#Extract">Configuration</a>   <a href="#Capture Processes">Capture</a>   <a href="#Capture Statistics">Statistics</a>
prompt Replicat: <a href="#Inbound Server Configuration">Configuration</a>  <a href="#Apply Processes">Apply</a>   <a href="#GoldenGate Inbound Server Statistics">Statistics</a> 
prompt Analysis: <a href="#History">History</a>   <a href="#Notification">Notifications</a>   <a href="#DBA OBJECTS">Objects</a> <a href="#Configuration checks">Checks</a>   <a href="#Performance Checks">Performance</a>   <a href="#Wait Analysis">  Wait Analysis </a> <a href="#Topology"> Topology </a>
prompt Statistics: <a href="#Statistics">Statistics</a>   <a href="#Queue Statistics">Queue</a>   <a href="#Capture Statistics">Capture</a>   <a href="#Apply Statistics">Apply</a>   <a href="#Errors">Apply_Errors</a>  

prompt
set heading off
select 'Oracle GoldenGate Integrated Extract/Replicat Health Check (&hcversion) for '||global_name||' on Instance='||instance_name||' generated: '||sysdate o  from global_name, v$instance;
set heading on

set timing off
set markup html off
clear col
clear break
spool
prompt   Turning Spool OFF!!!
spool off


