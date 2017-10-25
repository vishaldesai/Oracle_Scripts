set pages 200
set linesize 200
select distinct name, version, offloadable
from V$SQLFN_METADATA
order by 1,2;