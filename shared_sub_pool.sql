--How to check how many shared pool subpools do i have

select child#,gets from v$latch_children where name ='shared pool';

@pd _kghdsidx_count

select * from x$kghlu where kghlushrpool=1;

--Different kghluidx means protection by different latch
-- Different kghludur = same latch, different sub-sub-heap

-- select * from x$kglob where kglnaown='SYS' and kglnaobj='BIGP' @pr;
-- KGLOBHS0, KGLOBHS1 etc shows detailed memory chunks.
-- v$db_object_cache sharable_mem is memory used in shared pool.