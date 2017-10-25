set feedback off
set echo off
set feed off

column host_name     format A15
column instance_name format A15
column user          format A15

SELECT
       host_name
      ,instance_name
      ,user
      ,to_char(sysdate, 'Mon DD YYYY HH:MI AM') ToDay
 FROM v$instance;


column wu    format A10     head   'Waiting|User' noprin
column wou   format A10     head   'Waiting|OS-User' noprin
column wsid  format 999999  head   'Waiting|SID' noprin
column wpid  format A10     head   'Waiting|PID' noprin
column wt    format A15     head   'Waiting|Since' noprin

column hu    format A10     head   'Holding|User' noprin
column hou   format A10     head   'Holding|OS-User' noprin
column hsid  format 999999  head   'Holding|SID' noprin
column hpid  format A10     head  ' Holding|PID' noprin
column ht    format A15     head   'Holding|Since' noprin
column blk  format A79      head  'Blocking Information'

SELECT /*+ RULE */
  -- Waiter --
       S1.username  || ' (' || TO_CHAR(w.session_id) || ')' wu,
       S1.osuser   wou ,
       W.session_id wsid,
       P1.spid wpid ,
       TO_CHAR(TRUNC(s1.last_call_et/3600,0))||' '||' Hrs '||
       TO_CHAR(TRUNC((s1.last_call_et - TRUNC(s1.last_call_et/3600,0) *3600) / 60,0))|| ' Mins' wt ,
  -- Lock Holder --
       s2.username  || ' (' || TO_CHAR(h.session_id) || ')' hu,
       S2.osuser hou,
       P2.spid hpid,
        TO_CHAR(TRUNC(s2.last_call_et/3600,0))||' '||' Hrs '||
        TO_CHAR(TRUNC((s2.last_call_et - TRUNC(s2.last_call_et/3600,0) *3600) / 60,0))|| ' Mins' ht
   , NVL(s2.username, 'Oracle' )  || ' (' || TO_CHAR(h.session_id) || ') is blocking user '||
       S1.username  || ' (' || TO_CHAR(w.session_id) || ') since '  ||
       TO_CHAR(TRUNC(s1.last_call_et/3600,0))||' '||' Hrs '||
       TO_CHAR(TRUNC((s1.last_call_et - TRUNC(s1.last_call_et/3600,0) *3600) / 60,0))|| ' Mins.'  blk
FROM
       v$process P1,
       v$process P2,
       v$session S1,
       v$session S2,
       dba_locks W,
       dba_locks H
WHERE
 H.BLOCKING_OTHERS = 'Blocking'
-- and H.mode_held = 'Null'
AND W.mode_requested != 'None'
AND W.lock_type(+)= H.lock_type
AND W.lock_id1(+)= H.lock_id1
AND W.lock_id2(+)= H.lock_id2
AND W.session_id = S1.sid (+)
AND H.session_id = S2.sid (+)
AND S1.paddr     = P1.addr (+)
AND S2.paddr     = P2.addr (+);


column osuser  format A20
column machine format A20
column program format A30
column sid     format A12
column sql_address head 'Sql Ref'

prompt
prompt  =====  BLOCKERS DETAILS =====
prompt

SELECT  /*+ RULE */ distinct TRIM(to_char(s2.sid)||','|| to_char(s2.serial#)) sid,
       s2.osuser, s2.machine, s2.program, s2.sql_address
FROM v$process P1,
       v$process P2,
       v$session S1,
       v$session S2,
       dba_locks W,
       dba_locks H
WHERE H.BLOCKING_OTHERS = 'Blocking'
-- and H.mode_held = 'Null'
AND W.mode_requested != 'None'
AND W.lock_type(+)= H.lock_type
AND W.lock_id1(+)= H.lock_id1
AND W.lock_id2(+)= H.lock_id2
AND W.session_id = S1.sid (+)
AND H.session_id = S2.sid (+)
AND S1.paddr     = P1.addr (+)
AND S2.paddr     = P2.addr (+);


break on sql_address skip 1

SELECT /*+ RULE */ address sql_address, sql_text
  FROM v$sqltext
WHERE address IN ( SELECT s2.sql_address
FROM v$process P1,
       v$process P2,
       v$session S1,
       v$session S2,
       dba_locks W,
       dba_locks H
WHERE H.BLOCKING_OTHERS = 'Blocking'
-- and H.mode_held = 'Null'
AND W.mode_requested != 'None'
AND W.lock_type(+)= H.lock_type
AND W.lock_id1(+)= H.lock_id1
AND W.lock_id2(+)= H.lock_id2
AND W.session_id = S1.sid (+)
AND H.session_id = S2.sid (+)
AND S1.paddr     = P1.addr (+)
AND S2.paddr     = P2.addr (+) )
ORDER BY address, piece;


prompt
prompt  =====  BLOCKEES DETAILS =====
prompt

SELECT /*+ RULE */ distinct TRIM(to_char(s1.sid)||','|| to_char(s1.serial#)) sid,
       s1.osuser, s1.machine, s1.program, s1.sql_address
FROM v$process P1,
       v$process P2,
       v$session S1,
       v$session S2,
       dba_locks W,
       dba_locks H
WHERE H.BLOCKING_OTHERS = 'Blocking'
-- and H.mode_held = 'Null'
AND W.mode_requested != 'None'
AND W.lock_type(+)= H.lock_type
AND W.lock_id1(+)= H.lock_id1
AND W.lock_id2(+)= H.lock_id2
AND W.session_id = S1.sid (+)
AND H.session_id = S2.sid (+)
AND S1.paddr     = P1.addr (+)
AND S2.paddr     = P2.addr (+);


SELECT /*+ RULE */ address sql_address, sql_text
  FROM v$sqltext
WHERE address IN ( SELECT s1.sql_address
FROM v$process P1,
       v$process P2,
       v$session S1,
       v$session S2,
       dba_locks W,
       dba_locks H
WHERE H.BLOCKING_OTHERS = 'Blocking'
-- and H.mode_held = 'Null'
AND W.mode_requested != 'None'
AND W.lock_type(+)= H.lock_type
AND W.lock_id1(+)= H.lock_id1
AND W.lock_id2(+)= H.lock_id2
AND W.session_id = S1.sid (+)
AND H.session_id = S2.sid (+)
AND S1.paddr     = P1.addr (+)
AND S2.paddr     = P2.addr (+) )
ORDER BY address, piece;
