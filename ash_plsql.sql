column owner format  a12
column object_name format a30
column ashcnt heading 'ASH |count' 				format 99999999
column rr     heading 'ASH report-to|ratio' 	format 999.99
column ps     heading 'PLSQL(P)|SQL(S)' 		format a5
column pscnt  heading 'ASH |(P)(S)' 			format 9999999
column rs     heading 'ASH report-to|(P)(S)' 	format 999.99

accept own			prompt 'Enter owner  :'
accept objname      prompt 'Enter object : '
accept vname        prompt 'Enter v$/DBA view name:'
accept ndays        prompt 'Enter n days: '

SELECT a.owner, 
       a.object_name, 
       a.ashcnt, 
       a.rr, 
       b.ps, 
       b.pscnt, 
       round(Ratio_to_report(pscnt) 
               over ( 
                 PARTITION BY a.object_name), 3) * 100 AS rs 
FROM   (SELECT owner, 
               object_name, 
               ashcnt, 
               round(Ratio_to_report (ashcnt) 
                       over (), 3) * 100 rr 
        FROM   (SELECT owner, 
                       object_name, 
                       Count(*) ashcnt 
                FROM   &vname, 
                       dba_objects 
                WHERE  plsql_entry_object_id IS NOT NULL 
                       AND owner NOT IN ( 'SYS', 'SYSTEM' ) 
                       AND sample_time >= sysdate-&ndays
					   AND owner  = nvl('&own',owner)
					   AND object_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','TRIGGER')
                       AND object_id = plsql_entry_object_id 
                GROUP  BY owner,object_name)) a, 
       (SELECT owner,
	           object_name, 
               ps, 
               Count(*) pscnt 
        FROM   (SELECT owner,
		               object_name, 
                       CASE 
                         WHEN sql_opname = 'PL/SQL EXECUTE' THEN 'P' 
                         ELSE 'S' 
                       END ps 
                FROM   &vname, 
                       dba_objects 
                WHERE  plsql_entry_object_id IS NOT NULL 
                       AND owner NOT IN ( 'SYS', 'SYSTEM' )
                       AND sample_time >= sysdate-&ndays
					   AND owner  = nvl('&own',owner)	
					   AND object_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','TRIGGER')
                       AND object_id = plsql_entry_object_id) 
        GROUP  BY owner,object_name, 
                  ps) b 
WHERE  a.owner = b.owner 
       AND a.object_name = b.object_name 
	   --AND a.owner       = nvl('&own',a.owner)
       --AND a.object_name = nvl('&objname',a.object_name)
ORDER  BY a.ashcnt DESC, 
          a.object_name, 
          b.ps; 