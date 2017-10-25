col pd_name head NAME for a45
col pd_value head VALUE for a30
set linesize 150
set pages 2000
column pd_descr heading DESCRIPTION format a55 word_wrap

Prompt Show all parameters and session values from x$ksppi/x$ksppcv...

select n.ksppinm pd_name, c.ksppstvl pd_value, n.ksppdesc pd_descr
from sys.x$ksppi n, sys.x$ksppcv c
where n.indx=c.indx
and (
   lower(n.ksppinm) like lower('%&1%') 
   or lower(n.ksppdesc) like lower('%&1%')
);
