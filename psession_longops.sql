create or replace function getsesslong (sid1 number) return varchar2
is
x varchar2(600);
begin
select  ' %complete: ' ||
rpad(lpad(ROUND(sofar / DECODE(totalwork, 0, sofar, totalwork) * 100),2,'0'),2,' ') ||  ' sofar: ' || rpad(sofar,6,' ') || 
' ELA: ' || rpad(ELAPSED_SECONDS,5,' ') || ' total: ' || rpad(totalwork,8,' ') || ' '|| message into x
 from v$session_longops where sid=sid1 and sofar <> totalwork and ROUND(sofar / DECODE(totalwork, 0, sofar, totalwork) * 100, 2) < 100;
return x;
end;
/



col username for a12 
col "QC SID" for a6 
col SID for a5
col "QC/Slave" for A10 
col "Requested DOP" for 99 
col "Actual DOP" for 99
col "slave set" for  A10 
column progress format a200
set pages 100 
set linesize 800


select 
  decode(px.qcinst_id,NULL,username, ' - '||lower(substr(s.program,length(s.program)-4,4) ) ) "Username", 
  decode(px.qcinst_id,NULL, 'QC', '(Slave)') "QC/Slave" , 
  to_char( px.server_set) "Slave Set", 
  to_char(s.sid) "SID", 
  decode(px.qcinst_id, NULL ,to_char(s.sid) ,px.qcsid) "QC SID", 
  getsesslong(s.sid) Progress
from 
  v$px_session px, 
  v$session s 
where 
  px.sid=s.sid (+) 
 and 
  px.serial#=s.serial# 
order by 5 , 1 desc 
/

drop function getsesslong;
