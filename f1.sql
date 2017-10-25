REM Flushes one cursor out of the shared pool. Works on 11g+

PRO *** before flush ***

BEGIN
 FOR i IN (SELECT address, hash_value
 FROM v$sql WHERE plan_hash_value='&plan_hash')
 LOOP
 SYS.DBMS_SHARED_POOL.PURGE(i.address||','||i.hash_value, 'C');
 END LOOP;
END;
/
PRO *** after flush ***

