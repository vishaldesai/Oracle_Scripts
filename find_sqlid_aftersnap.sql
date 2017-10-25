select dba_hist_sqltext.sql_id,dba_hist_sqltext.sql_Text, dba_hist_sqlstat.plan_hash_value
from dba_hist_sqltext , dba_hist_sqlstat
where sql_Text like '%&sql_text%'
and dba_hist_sqltext.sql_id = dba_hist_sqlstat.sql_id
and dba_hist_sqlstat.snap_id>=&snap_id;