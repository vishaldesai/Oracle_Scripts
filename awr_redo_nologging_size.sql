-------------------------------------------------------------------------------------------------
--  Script : awr_redo_nologging_size.sql
-------------------------------------------------------------------------------------------------
-- This script will calculate the daily redo size using AWR
-- Restrictions :
-- 	1. Of course, AWR must be running and collects statistics
--      2. If you have centralized AWR repository, then you might want to verify the data.
--         Tested only for non-centralized AWR repository
--
--  Author : Riyaj Shamsudeen
--  No implied or explicit warranty !
-------------------------------------------------------------------------------------------------
PROMPT
PROMPT
PROMPT  awr_redo_nologging_size.sql v1.20 by Riyaj Shamsudeen @orainternals.com
PROMPT
PROMPT   To generate Report about Redo rate from AWR tables
PROMPT    
PROMPT Calculation: Redo size if you turn on force logging at DB level = 
PROMPT                          current redo size + 
PROMPT                          db_block_size * (Physical Writes Direct - Physical Writes Direct Temporary tablespace)
PROMPT     Note: 1.This number includes Direct LOB Writes too.
PROMPT           2.If you have already turned on FORCE logging use script awr_redo_size.sql script.
PROMPT
set pages 40
set lines 160
set serveroutput on size 1000000
column "redo_size (MB)" format 999,999,999,999.99
column "phy_writes_dir (MB)" format 999,999,999,999.99
column "phy_writes_dir_temp(MB)" format 999,999,999,999.99
set verify off
accept db_block_size prompt 'Enter the block size(Null=8192):'
accept history_days prompt 'Enter past number of days to search for (Null=30):'
SELECT inst.db_name,
       redo_date,
       Trunc(SUM(redo_size + nvl('&&db_block_size', 8192) * ( phy_write_direct - phy_write_direct_temp )) / 1024 / 1024, 2) "redo_size (MB)",
       Trunc(SUM(phy_write_direct) * nvl('&&db_block_size',8192) / 1024 / 1024, 2) "phy_writes_dir (MB)",
       Trunc(SUM(phy_write_direct_temp) * nvl('&&db_block_size',8192) / 1024 / 1024, 2) "phy_writes_dir_temp(MB)"
FROM   (SELECT DISTINCT dbid,instance_number,
                        redo_date,
                        redo_size,
                        phy_write_direct,
                        phy_write_direct_temp,
                        startup_time
        FROM   (SELECT sysst.dbid,sysst.instance_number,
                       Trunc(begin_interval_time) redo_date,
                       startup_time,
                       VALUE,
                       CASE
                         WHEN stat_name = 'redo size' THEN
                         Last_value (VALUE) over ( PARTITION BY Trunc (begin_interval_time), startup_time, sysst.stat_id ,sysst.instance_number
                                                   ORDER BY begin_interval_time, startup_time, sysst.stat_id ROWS BETWEEN unbounded preceding AND unbounded following ) -
                         First_value (VALUE) over ( PARTITION BY Trunc(begin_interval_time), startup_time , sysst.stat_id ,sysst.instance_number
						   ORDER BY begin_interval_time, startup_time, sysst.stat_id ROWS BETWEEN unbounded preceding AND unbounded following )
                         ELSE 0
                        END                        redo_size,
                       CASE
                         WHEN stat_name = 'physical writes direct' THEN Nvl( 
			   Last_value (VALUE) over ( PARTITION BY Trunc( begin_interval_time), startup_time, sysst.stat_id,sysst.instance_number
						     ORDER BY begin_interval_time, startup_time, sysst.stat_id ROWS BETWEEN unbounded preceding AND unbounded following ), 0) - 
			   Nvl( First_value (VALUE) over ( PARTITION BY Trunc( begin_interval_time), startup_time , sysst.stat_id , sysst.instance_number
						     ORDER BY begin_interval_time, startup_time, sysst.stat_id ROWS BETWEEN unbounded preceding AND unbounded following ), 0) 
			  ELSE 0
                        END                        phy_write_direct,
                       CASE
                         WHEN stat_name = 'physical writes direct temporary tablespace' THEN Nvl(
                           Last_value (VALUE) over ( PARTITION BY Trunc( begin_interval_time), startup_time , sysst.stat_id ,sysst.instance_number
						     ORDER BY begin_interval_time, startup_time, sysst.stat_id ROWS BETWEEN unbounded preceding AND unbounded following ), 0) - 
			   Nvl( First_value (VALUE) over ( PARTITION BY Trunc( begin_interval_time), startup_time , sysst.stat_id ,sysst.instance_number
						     ORDER BY begin_interval_time, startup_time, sysst.stat_id ROWS BETWEEN unbounded preceding AND unbounded following ), 0) 
			  ELSE 0
                       END                        phy_write_direct_temp
                FROM   sys.wrh$_sysstat sysst,
                       dba_hist_snapshot snaps,
                       sys.wrh$_stat_name statname
                WHERE  snaps.snap_id = sysst.snap_id
                       AND snaps.dbid = sysst.dbid
                       AND snaps.instance_number = sysst.instance_number
                       AND sysst.stat_id = statname.stat_id
                       AND sysst.dbid = statname.dbid
                       AND statname.stat_name in 
			('redo size','physical writes direct' ,'physical writes direct temporary tablespace')
		       AND snaps.begin_interval_time >= to_date(trunc(sysdate-nvl('&&history_days',30)))
                ORDER  BY snaps.snap_id)) redo_data,
       sys.dba_hist_database_instance inst
WHERE  inst.dbid = redo_data.dbid
       AND inst.instance_number = redo_data.instance_number
GROUP  BY inst.db_name,
          redo_date
ORDER  BY inst.db_name,
          redo_date

/ 
set verify on

