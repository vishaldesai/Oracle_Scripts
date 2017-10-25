set echo off
col kgllk_hold_mode head HOLD_MODE for a10
col kgllk_req_mode head REQ_MODE for a10
col kgllk_user_name head USER_NAME for a15
col kgllk_state head 0xSTATE for A8
set linesize 500

select 
   KGLLKADR
 , s.sid
 , KGLLKSNM rsid
-- , KGLLKUSE
-- , KGLLKSES
 , decode(l.kgllkmod, 0, 'None', 1, 'Null', 2, 'Share', 3, 'Exclusive', to_char(l.kgllkmod)) kgllk_hold_mode
 , decode(l.kgllkreq, 0, 'None', 1, 'Null', 2, 'Share', 3, 'Exclusive', to_char(l.kgllkreq)) kgllk_req_mode
 , TO_CHAR(l.kgllkflg,'XXXXX') kgllk_state
-- , LPAD('0x'||TRIM(TO_CHAR(l.kgllkflg,'XXXXX')),8) kgllk_state
-- , decode(l.kgllkflg, 0, 1, 'BROKEN', 2, 'BREAKABLE', l.kgllkflg) kgllk_state
-- 11g stuff
-- , kgllkest
-- , kgllkexc
 , KGLLKHDL
 , KGLLKPNC
 , KGLLKPNS
 , KGLLKCNT
-- , KGLLKFLG
-- , KGLLKSPN
-- , KGLLKHTB
   , KGLNAHSH
-- , KGLLKSQLID
-- , KGLHDPAR
-- , KGLHDNSP
 , USER_NAME kgllk_user_name
 , KGLNAOBJ
-- , KGLLKCTP -- cursor type
FROM
   x$kgllk l
 , v$session s
WHERE
    s.saddr(+) = l.kgllkuse
--AND kgllkhdl = hextoraw(upper(lpad('&1',vsize(l.kgllkhdl)*2,'0')))
AND &1
/
