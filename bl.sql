set echo off
-- File name:   bl.sql
-- Purpose:     Display blocking lock sessions
--
-- Author:      Vishal Desai
-- Copyright:   TBD
--      
-- Pre req:     
-- Run as:	    dba    
-- Usage:       @bl


column inst_id                  heading "Inst|Id" format 999
column sid 			heading "SID" format 999999
column serial#			heading "SERIAL#" format 999999
column nm			heading "P1" format a12
column p2			heading "P2|ID1" format a15
column p3			heading "P3|ID2" format a10
--column blocking_instance 	heading "block|inst" format 99999
--column blocking_session 	heading "block|sid" format  99999
--column blocking_session_status 	heading "block|sid|status" format a7
column blocking			heading "blocking|instance|sid|status" format a15
column holder			heading "blocking|lockholder|name|mode" format a15
--column final_blocking_instance  heading "final|block|inst" format 99999
--column final_blocking_session   heading "final|block|sid" format 99999
--column final_blocking_session_status heading "final|block|sid|status" format a7
column final			heading "final|blocking|instance|sid|status" format a15
column finalholder		heading "final|lockholder|name|mode"	format a15

set linesize 200
set pages 9999
DEF _IF_ORA_10_OR_HIGHER="--"
COL oraversion NOPRINT NEW_VALUE _IF_ORA_10_OR_HIGHER
SET TERMOUT OFF
SELECT DECODE(SUBSTR(BANNER, INSTR(BANNER, 'Release ')+8,2), 10, '--','') oraversion 
FROM v$version WHERE ROWNUM=1;
SET TERMOUT ON


select  ses.inst_id inst_id
       ,ses.sid as sid
       ,serial#
       --,to_char(p1, 'XXXXXXXXXXXXXXXX')
       ,'Name=' || utl_raw.cast_to_varchar2(substr(trim(to_char(p1, 'XXXXXXXXXXXXXXXX')),1,2)) 
        || utl_raw.cast_to_varchar2(substr(trim(to_char(p1, 'XXXXXXXXXXXXXXXX')),3,2)) || ' mode=' 
        || to_number(substr(trim(to_char(p1, 'XXXXXXXXXXXXXXXX')),5,4)) 
        || ' ' || decode(to_number(substr(trim(to_char(p1, 'XXXXXXXXXXXXXXXX')),5,4)),
                  	0,'none',
		  	1,'null', 
		  	2,'row-S',
			3,'row-X', 
			4,'share',
			5,'S/Row-X',
			6,'X') as nm
       ,eve.parameter2 || '=' || p2 as p2
       ,eve.parameter3 || '=' || p3 as p3
       ,blocking_instance || ' '|| blocking_session || ' '|| blocking_session_status as blocking
	   ,'Name=' || lk.type || ' '||'mode='||lmode || ' ' || decode(lmode,
                  									0,'none',
		  									1,'null', 
		  									2,'row-S',
											3,'row-X', 
											4,'share',
											5,'S/Row-X',
											6,'X') || ' id1=' || lk.id1 ||' id2=' || lk.id2 as holder
       &_IF_ORA_10_OR_HIGHER , final_blocking_instance || ' '|| final_blocking_session || ' '|| final_blocking_session_status final
       &_IF_ORA_10_OR_HIGHER , case when ses.final_blocking_session = ses.blocking_session then 
                                                                &_IF_ORA_10_OR_HIGHER   'Name=' || lk.type || ' '||'mode='||lmode || ' ' || decode(lmode,
                  						&_IF_ORA_10_OR_HIGHER	0,'none',
		  						&_IF_ORA_10_OR_HIGHER	1,'null', 
		  						&_IF_ORA_10_OR_HIGHER	2,'row-S',
								&_IF_ORA_10_OR_HIGHER	3,'row-X', 
								&_IF_ORA_10_OR_HIGHER	4,'share',
								&_IF_ORA_10_OR_HIGHER	5,'S/Row-X',
								&_IF_ORA_10_OR_HIGHER	6,'X') || ' id1=' || lk.id1 ||' id2=' || lk.id2
								&_IF_ORA_10_OR_HIGHER   end as finalholder
from   gv$session ses, gv$event_name eve, gv$lock lk
where  ses.event = eve.name and
       (
       &_IF_ORA_10_OR_HIGHER  lk.sid = ses.final_blocking_session 
       &_IF_ORA_10_OR_HIGHER    or 
       			      lk.sid=ses.blocking_session 
       ) 
        and
       --lk.block = 1 and
	   lk.id1=ses.p2 and
       blocking_session is not null
       &_IF_ORA_10_OR_HIGHER and final_blocking_session is not null
order by sid;


clear columns