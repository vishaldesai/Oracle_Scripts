column segment_name format a40
select segment_name,bytes/1024/1024/1024 from dba_segments
where owner in ('CSUSER','DPUSER') order by 2;
/