--prompt Display Parallel Execution QC and slave sessions for QC ....
set linesize 400
col pxs_degr head "Degree (Req)" for a12
col pxs_username head "USERNAME" for a20
column spid format 9999999

select 
    s.username          pxs_username
  , pxs.qcsid
  , s.sql_id
  , pxs.server_group    dfo_tree
  , pxs.server_set
  , pxs.qcinst_id inst
  , pxs.server#
  , lpad(to_char(pxs.degree)||' ('||to_char(pxs.req_degree)||')',12,' ') pxs_degr
  , pxs.inst_id
  , pxs.sid           slave_sid
  , p.server_name
  , p.spid
  , s.blocking_instance
  , s.blocking_session
  , s.state
  , s.event
from 
    gv$px_session pxs 
  , gv$session    s
  , gv$px_process p
where 
    --pxs.qcsid in () 
s.sid     = pxs.qcsid
and s.serial# = pxs.qcserial#
and p.sid     = pxs.sid
and pxs.inst_id = s.inst_id
and s.inst_id = p.inst_id
order by
    pxs.qcsid
  , pxs.server_group
  , pxs.server_set
  , pxs.qcinst_id
  , pxs.server#
/

