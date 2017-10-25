--tq monitors traffic flowing through TQ buffers
prompt Show PX Table Queue statistics from last Parallel Execution in this session...

col tq_tq head "TQ_ID|(DFO,SET)" for a10

break on tq_tq on dfo_number skip 1 on tq_id skip 1

select 
    ':TQ'||trim(to_char(t.dfo_number))||trim(to_char(t.tq_id,'0999')) tq_tq
  , t.* 
from 
    v$pq_tqstat t
order by 
    dfo_number, tq_id,server_type  desc
/

