set lines 200
set echo off
set pages 58
col SSEff	format 990.90 head 'Offload Efficiency'
col LIOEff 	format 990.90 head 'LIO|Efficiency'
col StorInd 	format 999999.90 head 'MB Saved|StorInd'
col FC 		format 999999.90 head 'MB From|FlashCache'
col MBreq  	format 999999.90 head 'Requested MB'
col SSElig 	format 999999.90 head 'Eligible Offload MB'
col ICMB 	format 999999.90 head 'Interconnect MB'
col ICmbps  	format 999999.90 head 'Interconnect MBPS'
col CellMB 	format 999999.90 head 'Cell Disk IO (MB)'
col Cellmbps 	format 999999.90 head 'Cell Disk MBPS'
select  pr+pw+rz MBreq, 
	elig SSElig,  
	ic_bytes ICMB, 
	--si StorInd, fc FC,
	(case
          when elig=0 then 0
          when elig > 0 then (100*(((pr+pw+rz)-ic_bytes)/(pr+pw+rz)))
        end) SSEff,
	ic_bytes/:n ICmbps, 
	(pr+pw+rz)-(si+fc) CellMB,
	((pr+pw+rz)-(si+fc))/:n Cellmbps
from (
 select * from (
   select name,mb from (
    select stats.name,
       (case 
	 when stats.name='physical reads' then (stats.value * dbbs.value)/1024/1024
	 when stats.name='physical writes' then asm.asmm*((stats.value * dbbs.value)/1024/1024)
	 when stats.name='redo size' then asm.asmm*((stats.value * 512)/1024/1024)
	 when stats.name like 'cell physi%' then stats.value/1024/1024
	 when stats.name like 'cell%flash%' then (stats.value * dbbs.value)/1024/1024
	 else stats.value
        end) mb
    from (
       select b.name,
          value
       from     v$mystat a,
       		v$statname b
       where  a.statistic# = b.statistic#
       and b.name in 
  	( 'cell physical IO bytes eligible for predicate offload',
    		'cell physical IO interconnect bytes',
    		'cell physical IO interconnect bytes returned by smart scan',
    		'cell flash cache read hits','cell physical IO bytes saved by storage index',
    		'physical reads',
    		'physical writes',
    	'redo size')
 	) stats,
  	(select value from v$parameter where name='db_block_size') dbbs,
  	(select decode(max(type),'NORMAL',2,'HIGH',3,2) asmm
   	from v$asm_diskgroup ) asm
  )) pivot (sum(mb) for (name) 
	in ('cell physical IO bytes eligible for predicate offload' as elig,
    	'cell physical IO interconnect bytes' as ic_bytes,
    	'cell physical IO interconnect bytes returned by smart scan' as ss_ret,
    	'cell flash cache read hits' as fc,'cell physical IO bytes saved by storage index' as si,
    	'physical reads' as pr, 'physical writes' as pw, 'redo size' as rz))
)
/
