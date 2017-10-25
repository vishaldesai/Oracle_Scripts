SET ECHO off 
REM NAME:   TFSAUDIT.SQL 
REM USAGE:"@path/tfsaudit" 
REM -------------------------------------------------------------------------- 
REM REQUIREMENTS: 
REM    SELECT ON DBA_OBJ_AUDIT_OPTS, DBA_STMT_AUDIT_OPTS, DBA_AUDIT_TRAIL 
REM    and DBA_PRIV_AUDIT_OPTS
REM -------------------------------------------------------------------------- 
REM AUTHOR:  
REM    Geert De Paep    -    Oracle Belgium       
REM -------------------------------------------------------------------------- 
REM PURPOSE: 
REM    see what is being audited in the database, and to see the audit_trail 
REM ------------------------------------------------------------------------- 
REM DISCLAIMER: 
REM    This script is provided for educational purposes only. It is NOT  
REM    supported by Oracle World Wide Technical Support. 
REM    The script has been tested and appears to work as intended. 
REM    You should always run new scripts on a test instance initially. 
REM -------------------------------------------------------------------------- 
REM Main text of script follows: 

col user_name for a12 heading "User name"
col proxy_name for a12 heading "Proxy name"
col privilege for a30 heading "Privilege"
col user_name for a12 heading "User name" 
col audit_option format a30 heading "Audit Option"
col timest format a13 
col userid format a8 trunc 
col obn format a10 trunc 
col name format a13 trunc 
col sessionid format 99999 
col entryid format 999 
col owner format a10 
col object_name format a10 
col object_type format a6 
col priv_used format a15 trunc 
break on user_name
set pages 1000

set pause 'Return...' 

pause Press return to see the audit related parameters...

col name for a20 
col display_value for a20

SELECT NAME ,DISPLAY_VALUE 
FROM V$PARAMETER 
WHERE UPPER(NAME) LIKE UPPER('%audit%') 
ORDER BY NAME,ROWNUM
/





prompt 
prompt System auditing options across the system and by user

select * from sys.dba_stmt_audit_opts
order by user_name, proxy_name, audit_option 
/

pause Press return to see auditing options on all objects...

select owner, object_name, object_type, 
       alt,aud,com,del,gra,ind,ins,loc,ren,sel,upd,ref,exe 
from sys.dba_obj_audit_opts 
where  
   alt !='-/-' or aud !='-/-' or com !='-/-' 
or del !='-/-' or gra !='-/-' or ind !='-/-' 
or ins !='-/-' or loc !='-/-' or ren !='-/-' 
or sel !='-/-' or upd !='-/-' or ref !='-/-' or exe !='-/-' 
/ 
 
pause Press return to see audit trail... Note that the query returns the audit data for the last day only
 
col acname format a12 heading "Action name" 
select username userid, to_char(timestamp,'dd-mon hh24:mi') timest , 
  action_name acname, priv_used, obj_name obn, ses_actions 
from sys.dba_audit_trail
where timestamp>sysdate-1
order by timestamp 
/ 

pause Press return to see system privileges audited across the system and by user...

select * from dba_priv_audit_opts
order by user_name, proxy_name, privilege
/
