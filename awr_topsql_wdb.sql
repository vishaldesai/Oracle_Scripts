set linesize 500
set verify off
set feedback off
set feed off
set echo off


--  Microseconds to milli-seconds
define ustoms = 1000;
--  Microseconds to seconds
define ustos = 1000000;
-- Centiseconds to seconds
define cstos = 100;
-- Centiseconds to milli-seconds
define cstoms = 10;


accept bid          prompt 'Enter begin snap	 	: '
accept eid           prompt 'Enter end   snap   		: '
accept top_n 					   prompt 'Enter topn display 		:'
accept sql_order		   prompt 'Enter metric (elapsed,cpu,gets,reads,cluster,execs,iowait) :'

--dynamic comment section
col SELECTED new_val SELECTION

set term off
 
SELECT
 case when '&&sql_order' = 'elapsed' then 'sql_order_elapsed.sql'
      when '&&sql_order' = 'cpu'	 then 'sql_order_cpu.sql'
	  when '&&sql_order' = 'gets'	 then 'sql_order_gets.sql'
	  when '&&sql_order' = 'reads'   then 'sql_order_reads.sql'
	  when '&&sql_order' = 'cluster' then 'sql_order_cluster.sql'
	  when '&&sql_order' = 'execs'   then 'sql_order_execs.sql'
	  when '&&sql_order' = 'iowait'   then 'sql_order_iowait.sql'
 END AS SELECTED
FROM dual;
 
-- activate terminal output
set term on

--begin and end snap
variable bid       number;
variable eid       number;
begin
  :bid      :=  &bid;
  :eid      :=  &eid;
end;
/


-- Get dbid
variable dbid       number;
begin
  select dbid            into :dbid
     --, db_name         dbb_name
     --, count(distinct instance_number) instt_tot
  from dba_hist_database_instance where startup_time>=sysdate-30 
 group by dbid, db_name
 order by dbid;
end;
/

-- Get dbtime, dbcpu, db background time, and db background cpu
variable tdbtim       number;
variable tdbcpu       number;
variable tbgtim       number;
variable tbgcpu       number;
begin

select tdbtim,tdbcpu,tbgtim,tbgcpu into :tdbtim,:tdbcpu,:tbgtim,:tbgcpu
  from ((select e.stat_name
             , (e.value - nvl(b.value,0))  value
          from dba_hist_sys_time_model b
             , dba_hist_sys_time_model e
         where e.dbid            = :dbid
           and e.dbid            = b.dbid            (+)
           and e.instance_number = b.instance_number (+)
           and e.snap_id         = :eid
           and b.snap_id   (+)   = :bid
           and b.stat_id   (+)   = e.stat_id
           and e.stat_name in ('DB time','DB CPU'
              ,'background elapsed time','background cpu time'))
       pivot (sum(value) for stat_name in
               ('DB time'                 tdbtim
               ,'DB CPU'                  tdbcpu
               ,'background elapsed time' tbgtim
               ,'background cpu time'     tbgcpu)));
			   
end;
/
			   

--Get cluster and io time
variable tclutm       number;
variable tiowtm       number;
begin

select tclutm,tiowtm into :tclutm,:tiowtm
  from ((select e.wait_class
              , sum(e.time_waited_micro - nvl(b.time_waited_micro,0))  twttm
           from dba_hist_system_event b
              , dba_hist_system_event e
          where e.dbid            = :dbid
            and e.dbid            = b.dbid             (+)
            and e.instance_number = b.instance_number  (+)
            and e.snap_id         = :eid
            and b.snap_id   (+)   = :bid
            and e.event_id        = b.event_id         (+)
            and e.wait_class in ('Cluster', 'User I/O')
          group by e.wait_class))
    pivot (sum(twttm) for wait_class in
                ('Cluster'   tclutm
                ,'User I/O'  tiowtm));
				
end;
/

--Get logical stats
variable trds       number;
variable tgets		number;
variable texecs     number;
begin
select trds,tgets,texecs into :trds,:tgets,:texecs
  from ((select e.stat_name
             , (e.value - nvl(b.value,0))  value
          from dba_hist_sysstat b
             , dba_hist_sysstat e
         where e.dbid            = :dbid
           and e.dbid            = b.dbid            (+)
           and e.instance_number = b.instance_number (+)
           and e.snap_id         = :eid
           and b.snap_id   (+)   = :bid
           and b.stat_id   (+)   = e.stat_id
           and e.stat_name in ('session logical reads', 'db block changes'
               ,'physical reads', 'physical reads direct'
               ,'physical writes', 'physical writes direct'
               ,'execute count'
               , 'index fast full scans (full)', 'table scans (long tables)'
               , 'gc cr blocks received', 'gc current blocks received'
               , 'gc cr blocks served', 'gc current blocks served'
               , 'user commits', 'user rollbacks'))
        pivot (sum(value) for stat_name in
              ('session logical reads'         tgets
              ,'db block changes'              tdbch
              ,'physical reads'                trds
              ,'physical reads direct'         trdds
              ,'physical writes'               twrs
              ,'physical writes direct'        twrds
              ,'execute count'                 texecs
              ,'index fast full scans (full)'  tiffs
              ,'table scans (long tables)'     ttslt
              ,'gc cr blocks received'         tgccrr
              ,'gc current blocks received'    tgccur
              ,'gc cr blocks served'           tgccrs
              ,'gc current blocks served'      tgccus
              ,'user commits'                  tucm
              ,'user rollbacks'                tur)));
end;
/			  


@ &SELECTION


clear columns sql
undefine top_n
undefine bid
undefine eid



