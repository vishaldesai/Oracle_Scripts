define __FILE = &1
define __BLOCK = &2

alter session set parallel_force_local=true;
select /*+ parallel(s,4) */ owner,segment_name
from dba_extents s
where file_id = &__FILE
			and &__BLOCK between block_id and block_id + blocks - 1
			and rownum = 1
;

set echo on