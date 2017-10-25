select a.name,b.value/1024/1024 MB
from v$sysstat a, v$mystat b
where a.statistic#=b.statistic# and
(a.name like 'physical%total%bytes' OR a.name like 'cell phys%'
or a.name like 'cell IO%');
