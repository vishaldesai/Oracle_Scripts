col 0xFLAG just right
set linesize 500
column sid format 9999
column "0xFLAG" format a20

select
    s.sid
  , s.serial#
  , s.username
  , t.addr taddr
  , s.saddr ses_addr
  , t.used_ublk
  , t.used_urec
--  , t.start_time
  , to_char(t.flag, 'XXXXXXXX') "0xFLAG"
  , t.status
  , t.start_date
  , XIDUSN 
  , XIDSLOT
  , XIDSQN
  , t.xid
  , t.prv_xid
  , t.ptx_xid
from
    v$session s
  , v$transaction t
where
    s.saddr = t.ses_addr
/

select
    s.sid
  , s.serial#
  , s.username
  , t.used_ublk
  , t.status || case when bitand(t.flag,128)=128 then 'Rolling back' end status
from
    v$session s
  , v$transaction t
where
    s.saddr = t.ses_addr
/

/*
set serveroutput on
declare
bblocks number;
ablocks number;
dblocks number;
begin

select
sum(t.used_ublk) into bblocks from
    v$session s
  , v$transaction t
where
    s.saddr = t.ses_addr
and bitand(t.flag,128)=128;

dbms_lock.sleep(60);

select
sum(t.used_ublk) into ablocks from
    v$session s
  , v$transaction t
where
    s.saddr = t.ses_addr
and bitand(t.flag,128)=128;

dblocks := bblocks-ablocks;

dbms_output.put_line( 'Rate blocks/min:' ||  dblocks);
dbms_output.put_line( 'Estimate to complete rollback:' || round( ablocks*60/(dblocks*60*60)) || ' hours');
end;
/

*/



