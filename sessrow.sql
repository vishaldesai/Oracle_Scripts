column name format a30 word_wrapped
column vlu format 999,999,999,999
select b.name, a.value vlu
from v$sesstat a, v$statname b
where a.statistic# = b.statistic#
and sid in (&sid)
and a.value <> 0
and b.name like '%row%'
/
