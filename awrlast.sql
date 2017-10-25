set termout off

col end_snap new_value   end_snap
col begin_snap new_value begin_snap

with s as (
    select max(snap_id) end_snap from dba_hist_snapshot
)
select end_snap, (select max(snap_id) begin_snap from dba_hist_snapshot where snap_id < s.end_snap) begin_snap 
from s;

def report_name=awrlast.txt
def num_days=1
def report_type=text

@awrrpt

undef end_snap
undef begin_snap

set termout on

--host open awrlast..txt
