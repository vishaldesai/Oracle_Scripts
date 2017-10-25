col tracefile_name for a120
SELECT rtrim(k.value,'/')||'/'||d.instance_name||'_ora_'||p.spid
||DECODE(p.value,'','','_'||p.value)||'.trc' tracefile_name
FROM v$parameter k, v$parameter p, v$instance d,
     sys.v_$session s, sys.v_$process p,
     (SELECT sid FROM v$mystat WHERE rownum=1) m
WHERE p.name = 'tracefile_identifier'
  AND k.name = 'user_dump_dest'
  AND s.paddr = p.addr
  AND s.sid = m.sid
/

