#!/bin/sh
#
# Name	  : fulltime.sh
version=3e
# Purpose : To see wait time details AND Oracle 
#           kernel function CPU details TOGETHER.
# Orig    : 17-Oct-2013
# Latest  : 31-Oct-2013 
# Author  : Craig Shallahamer <craig@orapub.com>
#           Frits Hoogland <frits.hoogland@gmail.com>
# Warrenty: There is absolutely no warrenty.
#           Use at your own and your organization's risk.
#           It's all on you, not me!

# Usage   : ./fulltime.sh
#           ./fulltime.sh PID INTERVAL CYCLES
#
# This has been developed on Linux.
# You break out with a cntrl-c

# Here is the general idea:
#
# Help user Identify the PID to profile
# Initial setup
# Loop
#   get oracle wait times (snap 0)
#   get oracle CPU time (snap 0)
#   start oracle kernel cpu details
#   sleep x
#   get oracle wait times (snap 1)
#   get oracle CPU time (snap 1)
#   stop oracle kernel cpu gathering
#   do some cool math and other neat stuff
#   display results
# End Loop

# Set the key variables
#
# use this for virtualised hosts:
#PERF_SAMPLE_METHOD='-e cpu-clock'
# use this for physical hosts:
PERF_SAMPLE_METHOD='-e cycles' 

refresh_time=3
samples_remaining=999 # this is useful for longer single samples

workdir=$PWD  
perf_file=perf_report.txt

clear
echo ""
echo "Welcome to the FULLTIME script (v$version)"
echo ""
echo "To see wait time details AND Oracle kernel function CPU details TOGETHER"
echo ""
echo "Use at your own and your organization's risk!"
echo ""

# if problems with perf
echo "If unable to execute perf, do as root:"
echo "   echo 0 > /proc/sys/kernel/perf_event_paranoid"

# perf sample method
echo ""
echo "The perf sample method is set to: $PERF_SAMPLE_METHOD"
echo "Use cpu-clock for virtualised hosts, cycles for physical hosts"

###
# ctrl_c routine
###
ctrl_c() {
	sqlplus / as sysdba <<EOF0 >& /dev/null
	drop table op_perf_report;
	drop table op_timing;
	drop directory ext_dir;
EOF0

	echo ""
	echo ""
	echo "Thanks for using FULLTIME v${version}!"
	echo ""
	echo "To see the latest Call Graph, press ENTER or to exit press CNTRL-C."
	echo ""
	echo "The Call Graph file is callgraph.txt"
	read x
	perf report -g -i callgraph.pdata > callgraph.txt 2>/dev/null
	echo ""
	more callgraph.txt
	exit
}

###
# help_find_pid routine
#
# Let's help the user identifiy the Oracle session of interest
#
###
help_find_pid() {


sqlplus -S / as sysdba <<EOF1
set termout off feed off
select /*perf profile*/
    substr(a.spid,1,9) pid,
    substr(b.sid,1,5) sid,
    substr(b.serial#,1,5) serial#,
    substr(b.machine,1,20) machine,
    substr(b.username,1,10) username,
    b.server, server,
    substr(b.osuser,1,15) osuser,
    substr(b.program,1,30) program
from v\$session b, v\$process a, v\$mystat c
where b.paddr = a.addr
  and b.sid != c.sid
  and c.statistic# = 0
  and type='USER'
order by spid
/
EOF1

echo ""
read -p "Enter PID to profile : " ospid

}


###
###
# All the below is the MAIN routine
###
###

trap ctrl_c SIGINT

if [ "$#" -eq 0 ]; then
	help_find_pid;
else
	ospid=$1
	refresh_time=$2
	samples_remaining=$3

	echo ""
	echo "Command line arguments are:"
	echo ""
	echo "ospid  : $ospid"
	echo "delay  : $refresh_time"
	echo "cycles : $samples_remaining"
fi

echo ""

#
# Setup. Only needs to be done once.
#
# As Oracle user
#

# if the process is not there, exit
#
if ! ps -p $ospid >/dev/null; then ctrl_c; fi

sqlplus / as sysdba <<EOF2 >& /dev/null

create or replace directory ext_dir as '$workdir';

drop table op_perf_report;

create table op_perf_report (
  overhead      number,
  command       varchar2(100),
  shared_obj    varchar2(100),
  symbol        varchar2(100)
)
organization external (
  type              oracle_loader
  default directory ext_dir
  access parameters (
    records delimited  by newline
    nobadfile nodiscardfile nologfile
    fields  terminated by ','
    OPTIONALLY ENCLOSED BY '\\"' LDRTRIM
    missing field values are null
  )
  location ('$perf_file')
)
reject limit unlimited;

drop table op_timing;

create table op_timing (
    time_seq number,
    item     varchar2(100),
    time_s   number
);  

EOF2


while [ $samples_remaining  -gt 0 ] 
do
	echo "Gathering next $refresh_time second sample..."

	if ! ps -p $ospid >/dev/null; then ctrl_c; fi

	#echo "... going in 3..."

	sqlplus / as sysdba <<EOF3 >& /dev/null

	set serverout off termout off

	declare
	  sid_var number;
	  tot_cpu_s_var number;
          timeseq_var number := 0;
	begin

	  select s.sid
	  into   sid_var
	  from   v\$process p,
		 v\$session s
	  where  p.addr = s.paddr
	    and  p.spid = $ospid;

	  select sum(value/1000000)
	  into   tot_cpu_s_var
	  from   v\$sess_time_model
	  where  stat_name in ('DB CPU','background cpu time')
	    and  sid = sid_var;

	  insert into op_timing
		select timeseq_var, event, time_waited_micro/1000000
		from   v\$session_event
		where  sid = sid_var;

	  insert into op_timing values (timeseq_var , 'Oracle CPU sec' , tot_cpu_s_var );

	end;
	/
EOF3

	if ! ps -p $ospid >/dev/null; then ctrl_c; fi

	#perf record -f $PERF_SAMPLE_METHOD -p $ospid >& /dev/null &
	#perf record -f $PERF_SAMPLE_METHOD -g -o callgraph.pdata -p $ospid >& /dev/null &	

	perf record -f $PERF_SAMPLE_METHOD -p $ospid sleep $refresh_time >& /dev/null &
	perf record -f $PERF_SAMPLE_METHOD -g -o callgraph.pdata -p $ospid sleep $refresh_time >& /dev/null   &
        wait

	if ! ps -p $ospid >/dev/null; then ctrl_c; fi

        sqlplus / as sysdba <<EOF4 >& /dev/null

	set serverout off termout off

        def ospid=$ospid

	declare
	  sid_var number;
	  tot_cpu_s_var number;
          timeseq_var number := 1;
  
	begin

	  select s.sid
	  into   sid_var
	  from   v\$process p,
		 v\$session s
	  where  p.addr = s.paddr
	    and  p.spid = &ospid;

	  select sum(value/1000000)
	  into   tot_cpu_s_var
	  from   v\$sess_time_model
	  where  stat_name in ('DB CPU','background cpu time')
	    and  sid = sid_var;

	  insert into op_timing
		select timeseq_var, event, time_waited_micro/1000000
		from   v\$session_event
		where  sid = sid_var;

	  insert into op_timing values (timeseq_var , 'Oracle CPU sec' , tot_cpu_s_var );

	end;
	/
EOF4

	#perf report -t, 2> /dev/null | grep $ospid | grep -v [g]rep > $perf_file 
	perf report -t, > $perf_file 2>/dev/null

	if ! ps -p $ospid >/dev/null; then ctrl_c; fi

	clear

	echo "Fulltime.sh v$version"

        sqlplus -S / as sysdba <<EOF5

	set termout off serverout off
	set feedback off
	set tab off

	variable tot_cpu_s_var number;
	variable tot_wait_s_var number;
	begin
		select	sum(end.time_s-begin.time_s)
		into  	:tot_cpu_s_var
		from  	op_timing end,
		 	op_timing begin
		where   end.time_seq   = 1
		  and   begin.time_seq = 0
		  and   end.item = begin.item
		  and   end.item = 'Oracle CPU sec';

		select	sum(end.time_s-begin.time_s)
		into  	:tot_wait_s_var
		from 	op_timing end,
			op_timing begin
		where 	end.time_seq   = 1
		  and 	begin.time_seq = 0
		  and 	end.item = begin.item
		  and 	end.item != 'Oracle CPU sec';
	end;
	/

	set termout on

	-- This is the screen header
    	--
	set echo off heading off

	select  'PID: '||p.spid||'  SID: '||s.sid||'  SERIAL: '||s.serial#||
		  '  USERNAME: '||s.username||'  at '||to_char(sysdate,'DD-Mon-YYYY HH24:MI:SS'),
		'CURRENT SQL: '||substr(q.sql_text,1,70)
	from    v\$session s, v\$process p, v\$sql q
	where	s.paddr=p.addr
	  and 	s.sql_id=q.sql_id (+)
	  and 	s.sql_child_number = q.child_number (+)
	  and 	p.spid=$ospid
	/

	select 
       		'total time: '||round(:tot_cpu_s_var + :tot_wait_s_var, 3)||' secs,'||
       		'  CPU: '||round(:tot_cpu_s_var,3) ||' secs ('||
       		  round((100* :tot_cpu_s_var  /( :tot_cpu_s_var + :tot_wait_s_var )),2)||'%),'||
       		'  wait: '||round(:tot_wait_s_var,3) ||' secs ('||
       		  round((100* :tot_wait_s_var /( :tot_cpu_s_var + :tot_wait_s_var )),2)||'%)'
	from dual
        /
	
	-- This is the screen core output
	--
	set heading on
	set serveroutput on
	col raw_time_s format 99990.000  heading 'Time|secs'
	col item       format a60        heading 'Time Component'
	col perc       format 999.00     heading '%'

	select 
		'cpu : '||rpt.symbol item,
		(rpt.overhead/100)*:tot_cpu_s_var raw_time_s,
		((rpt.overhead/100)*:tot_cpu_s_var)/(:tot_wait_s_var+:tot_cpu_s_var)*100 perc
	from	op_perf_report rpt
	where   rpt.overhead > 2.0
	union
	select 
		'cpu : [?] sum of funcs consuming less than 2% of CPU time' item,
		sum((rpt.overhead/100)*:tot_cpu_s_var) raw_time_s,
		sum((rpt.overhead/100)*:tot_cpu_s_var)/(:tot_wait_s_var+:tot_cpu_s_var)*100 perc
	from    op_perf_report rpt
	where   rpt.overhead <= 2.0
	group by 1,3
	union
	select  'wait: '||end.item, 
		end.time_s-begin.time_s raw_time_s,
		(end.time_s-begin.time_s)/(:tot_wait_s_var+:tot_cpu_s_var)*100 perc
	from    op_timing end,
		op_timing begin
	where   end.time_seq   = 1
	  and   begin.time_seq = 0
	  and   end.item = begin.item
	  and   end.time_s-begin.time_s > 0
	  and   end.item != 'Oracle CPU sec'
	order by raw_time_s desc
	/

	set termout off serverout off
	-- delete is  much quicker on my server than truncate
	delete from op_timing;

EOF5

	echo ""
	echo "To see the Call Graph, press ENTER or to exit press CNTRL-C."
	samples_remaining=`echo "$samples_remaining-1" | bc`
	
	echo "Samples remaining: $samples_remaining"

done

# If NO command line options, then prompt for call graph, else just exit.
#
if [ "$#" -eq 0 ]; then
	ctrl_c
fi

