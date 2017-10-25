--prompt show parameter which have value &1

set verify off
set head off
set feed off
set linesize 150
set pages 0

select db.col1 from (
select '#-------------------------------------------------------------------------------------------------------------------------------' col1 from dual union all
select '# Solaris	                                                                  	                                	' col1 from dual union all
select '#-------------------------------------------------------------------------------------------------------------------------------' col1 from dual union all
select 'truss -cp <pid>		' || ' System call cummulative tracing returns call counts                                              ' col1 from dual union all
select 'iostat -xn 1		' || ' Display iostats n=descriptive format and seperate queue and service time x=extended              ' col1 from dual union all
select 'iostat -dmx 1		' || ' Display iostats m=megabytes d=each disk x=extended				                ' col1 from dual union all
select 'iostat notes		' || ' -n display wsvc_t and asvc_t separately	(wait and service) svc_t is overall reponse time        ' col1 from dual union all
select 'iostat notes		' || ' If asvc_t constantly exceeds disk IO latency queueing is happening somewhere	                ' col1 from dual union all
select 'nicstat 		' || ' IO throughput per HBA/NIC. Download nicstat-1.22.tar.gz   			                ' col1 from dual union all
select 'sysperfstat             ' || ' displays utilisation and saturation for CPU, memory, disk and network, all on one line. 		' col1 from dual union all
select 'swapinfo                ' || ' Display swap, memory usage							 		' col1 from dual union all
select 'prstat -m		' || ' %LAT shows scheduling latency when CPU usage is high						' col1 from dual union all
select '#-------------------------------------------------------------------------------------------------------------------------------' col1 from dual union all
select '# Linux		                                                                  	                                        ' col1 from dual union all
select '#-------------------------------------------------------------------------------------------------------------------------------' col1 from dual union all
select 'strace -cp <pid>	' || ' System call cummulative tracing returns call counts                                              ' col1 from dual union all
select 'iostat -dmx 1		' || ' Display iostats m=megabytes d=each disk x=extended				                ' col1 from dual union all
select 'iostat notes		' || ' -n display await and svctm separately	(wait and service) svc_t is overall reponse time        ' col1 from dual union all
select 'iostat notes		' || ' If avgqu-szz and wait is high that means more concurrent IO is happening		                ' col1 from dual union all
select 'nicstat			' || ' IO throughput per HBA/NIC. Download nicstat-1.22.tar.gz							                ' col1 from dual 
 ) db
where lower(db.col1) like '%&1%' or lower(db.col1) like '%#%' ;