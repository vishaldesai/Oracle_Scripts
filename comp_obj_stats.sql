SET FEEDBACK OFF
SET VERIFY OFF
SET SCAN ON
SET LONG 1000000
set linesize 150
set pages 2000

accept owner         prompt 'Enter value for owner                  :'
accept table         prompt 'Enter value for table_name             :'


/*
variable last_a varchar2(100);
begin
select * into :last_a from 
(select * from (
select stats_update_time from dba_tab_stats_history where owner='&&owner' and table_name='&&table'
order by 1 desc) where rownum<=2 order by 1 ) where rownum<=1;
end;
/
*/
column partition_name format a20
column subpartition_name format a20
set linesize 500
set pages 9999
select owner,table_name,partition_name,subpartition_name,stats_update_time from dba_tab_stats_history where owner='&&owner' and table_name='&&table'
order by stats_update_time;

accept sttime	     prompt 'Enter start time from above				:'
accept edtime	     prompt 'Enter end   time from above (null for current stat)	:'
accept threshold     prompt 'Please enter percentage threshold 				 :'

SELECT *
FROM table(dbms_stats.diff_table_stats_in_history(
             ownname      => '&&owner',
             tabname      => '&&table',
	     time1	  => '&&sttime',
             time2        => '&&edtime', --null means current statistics
             pctthreshold => &&threshold));


