-- taken from metalink note 396940.1
-- added order by clause
set echo off
prompt
prompt WARNING!!! This script will query X$KSMSP, which will cause heavy shared pool latch contention 
prompt in systems under load and with large shared pool. This may even completely hang 
prompt your instance until the query has finished! You probably do not want to run this in production!
prompt
pause  Press ENTER to continue, CTRL+C to cancel...


col sga_heap format a15 
col size format a10 

break on subpool on sga_heap skip 1 on status on chunkcomment

select 
	KSMCHIDX subpool, 
	'sga heap('||KSMCHIDX||',0)'sga_heap,
	ksmchcom ChunkComment, 
	ksmchcls Status, 
	decode(round(ksmchsiz/1000),
		0,'0-1K', 
		1,'1-2K', 
		2,'2-3K',
		3,'3-4K', 
		4,'4-5K',
		5,'5-6k',
		6,'6-7k',
		7,'7-8k',
		8,'8-9k', 
		9,'9-10k',
		'> 10K') "SIZE", 
	count(*),
	sum(ksmchsiz) "SUM(BYTES)",
	min(ksmchsiz) MinBytes, 
	max(ksmchsiz) MaxBytes,
	avg(ksmchsiz) AvgBytes 
from 
	x$ksmsp 
where 
	1=1
and	lower(KSMCHCOM) like lower('%&1%')
group by 
	ksmchidx, 
	ksmchcls,
	'sga heap('||KSMCHIDX||',0)',
	ksmchcom, 
	decode(round(ksmchsiz/1000),0,'0-1K',1,'1-2K', 2,'2-3K', 3,'3-4K',4,'4-5K',5,'5-6k',
		6, '6-7k',7,'7-8k',8,'8-9k', 9,'9-10k','> 10K')
order by
	ksmchidx,
	lower(ksmchcom),
	ksmchcls,
	"SIZE"
/



