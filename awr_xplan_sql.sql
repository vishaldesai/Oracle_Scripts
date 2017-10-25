REM --------------------------------------------------------------------------------------------------
REM Author: Riyaj Shamsudeen @OraInternals, LLC
REM         www.orainternals.com
REM
REM Functionality: This script is to print changes in plan_hash_value from AWR for a given sql_id
REM **************
REM Source  : AWR tables
REM
REM Note : 1. Keep window 160 columns for better visibility.
REM
REM Exectution type: Execute from sqlplus or any other tool. 
REM
REM Parameters: Modify the script to use correct parameters. Search for PARAMS below.
REM No implied or explicit warranty
REM
REM Please send me an email to rshamsud@orainternals.com, if you enhance this script :-) 
REM  This is a open Source code and it is free to use and modify.
REM --------------------------------------------------------------------------------------------------
PROMPT 
PROMPT  Find plan_hash_value and enter it below.
PROMPT
set lines 320 pages 300
column  begin_interval_time format A30
column  prior_pl_hash format 9999999999999999999999
column  first_ph format 9999999999999999999999
column  first_ph_time format A30
column  last_ph format 9999999999999999999999
column  last_ph_time format A30
undef sql_id   
undef in_phv
with planhashes as (
SELECT   
                 s.dbid,
                 s.instance_number,
                 s.snap_id,
                 sn.begin_interval_time,
                 s.sql_id,
                 s.plan_hash_value,
                 LAG(plan_hash_value,1) OVER ( partition by s.dbid,s.instance_number, s.snap_id, s.sql_id ORDER BY s.snap_id ) prior_pl_hash
        FROM     dba_hist_sqlstat s,
                 dba_hist_snapshot sn
        WHERE    s.snap_id = sn.snap_id
        AND      sn.dbid = s.dbid
        AND      s.sql_id ='&&sql_id'
        AND      sn.instance_number = s.instance_number
--        AND      sn.begin_interval_time >= sysdate -(6/24)
--        AND      sn.begin_interval_time <= sysdate 
 order by s.dbid,
                    s.instance_number,
                    s.snap_id,
                    s.sql_id,
                   sn.begin_interval_time
)
select  distinct
                 s.dbid,
                 s.instance_number,
                 s.sql_id,
                 first_value(s.plan_hash_value) over ( partition by s.dbid,s.instance_number, s.sql_id, s.plan_hash_value order by s.snap_id
	  	    rows between unbounded preceding and unbounded following
		) first_ph,
                 first_value(s.begin_interval_time) over ( partition by s.dbid,s.instance_number,s.sql_id,  s.plan_hash_value order by s.snap_id
	  	    rows between unbounded preceding and unbounded following
                ) first_ph_time,
                 last_value(s.plan_hash_value) over ( partition by s.dbid,s.instance_number, s.sql_id, s.plan_hash_value order by s.snap_id
	  	    rows between unbounded preceding and unbounded following
 		) last_ph,
                 last_value(s.begin_interval_time) over ( partition by s.dbid,s.instance_number,s.sql_id,  s.plan_hash_value order by s.snap_id
	  	    rows between unbounded preceding and unbounded following
		) last_ph_time
  from planhashes s
order by 1,2,3,5,4
;
select  plan_table_output from  table(dbms_xplan.display_awr('&&sql_id', &&plan_hash_value, null, 'ALL -ALIAS'));

