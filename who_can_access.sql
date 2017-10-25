-- -----------------------------------------------------------------------------
--                 WWW.PETEFINNIGAN.COM LIMITED
-- -----------------------------------------------------------------------------
-- Script Name : who_can_access.sql
-- Author      : Pete Finnigan
-- Date        : Jan 2004
-- -----------------------------------------------------------------------------
-- Description : This script can be used to find who can access an object that
--               is passed in. It checks recursively for users hierarchically via 
--               roles.
--      
--               The output can be directed to either the screen via dbms_output
--               or to a file via utl_file. The method is decided at run time 
--               by choosing either 'S' for screen or 'F' for File. If File is
--               chosen then a filename and output directory are needed. The 
--               output directory needs to be enabled via utl_file_dir prior to
--               9iR2 and a directory object or utl_file_dir after.
--
-- Limitations : 1. Access granted via "ANY" privileges such as SELECT ANY TABLE
--                  or EXECUTE ANY PROCEDURE are not considered in this script
--                  at present. It may be added if demand shows users want it.
--                  My own view is that %ANY% privileges should be checked 
--                  separately. My script who_has_priv.sql can be used for this.
--               2. SYS owned base tables such as sys.obj$ are used to find out 
--                  the objects type as using dictionary views such as DBA_OBJECTS
--                  and DBA_TAB_PRIVS causes extra joins to occur because many
--                  objects having the same name. This means that the script must 
--                  be run as a user who has access to these tables.
-- -----------------------------------------------------------------------------
-- Maintainer  : Pete Finnigan (http://www.petefinnigan.com)
-- Copyright   : Copyright (C) 2004 PeteFinnigan.com Limited. All rights
--               reserved. All registered trademarks are the property of their
--               respective owners and are hereby acknowledged.
-- -----------------------------------------------------------------------------
--  Usage      : The script provided here is available free. You can do anything 
--               you want with it commercial or non commercial as long as the 
--               copyrights and this notice are not removed or edited in any way. 
--               The scripts cannot be posted / published / hosted or whatever 
--               anywhere else except at www.petefinnigan.com/tools.htm
-- -----------------------------------------------------------------------------
-- Version History
-- ===============
--
-- Who         version     Date      Description
-- ===         =======     ======    ======================
-- P.Finnigan  1.0         Feb 2004  First Issue.
-- P.Finnigan  1.1         Oct 2004  Added usage notes.
-- P.Finnigan  1.2         Apr 2005  Added whenever sqlerror continue to stop 
--                                   subsequent errors barfing SQL*Plus. Thanks
--                                   to Norman Dunbar for the update.
-- P.Finnigan  1.3         May 2005  Added two new parameters to allow specification
--                                   of users to be ommited from the report
--                                   output.
-- -----------------------------------------------------------------------------

whenever sqlerror exit rollback
set feed on
set head on
set arraysize 1
set space 1
set verify off
set pages 25
set lines 80
set termout on
clear screen
set serveroutput on size 1000000

spool who_can_access.lis

undefine object_to_find
undefine owner_to_find
undefine output_method
undefine file_name
undefine output_dir
undefine skip_user
undefine user_to_skip

set feed off
col system_date  noprint new_value val_system_date
select to_char(sysdate,'Dy Mon dd hh24:mi:ss yyyy') system_date from sys.dual;

prompt who_can_access: Release 1.0.3.0.0 - Production on &val_system_date
prompt Copyright (c) 2004 PeteFinnigan.com Limited. All rights reserved. 
set feed on
prompt
accept object_to_find char prompt 'NAME OF OBJECT TO CHECK       [USER_OBJECTS]: ' default USER_OBJECTS
accept owner_to_find char prompt  'OWNER OF THE OBJECT TO CHECK          [USER]: ' default USER
accept output_method char prompt  'OUTPUT METHOD Screen/File                [S]: ' default S
accept file_name char prompt      'FILE NAME FOR OUTPUT              [priv.lst]: ' default priv.lst
accept output_dir char prompt     'OUTPUT DIRECTORY [DIRECTORY  or file (/tmp)]: ' default /tmp
accept skip_user char prompt      'EXCLUDE CERTAIN USERS                    [N]: ' default N
accept user_to_skip char prompt   'USER TO SKIP                         [TEST%]: ' default TEST%
prompt 
declare
    --
    lg_fptr utl_file.file_type;
    lv_file_or_screen varchar2(1):='S';
    --
    procedure open_file (pv_file_name in varchar2,
            pv_dir_name in varchar2) is 
    begin
        lg_fptr:=utl_file.fopen(pv_dir_name,pv_file_name,'A');
    exception
        when utl_file.invalid_path  then
            dbms_output.put_line('invalid path');
        when utl_file.invalid_mode  then
            dbms_output.put_line('invalid mode');
        when utl_file.invalid_filehandle  then
            dbms_output.put_line('invalid filehandle');
        when utl_file.invalid_operation  then
            dbms_output.put_line('invalid operation');
        when utl_file.read_error  then
            dbms_output.put_line('read error');
        when utl_file.write_error  then
            dbms_output.put_line('write error');
        when utl_file.internal_error  then
            dbms_output.put_line('internal error');
        when others then
            dbms_output.put_line('ERROR (open_file) => '||sqlcode);
            dbms_output.put_line('MSG (open_file) => '||sqlerrm);

    end open_file;
    --
    procedure close_file is
    begin
        utl_file.fclose(lg_fptr);
    exception
        when utl_file.invalid_path  then
            dbms_output.put_line('invalid path');
        when utl_file.invalid_mode  then
            dbms_output.put_line('invalid mode');
        when utl_file.invalid_filehandle  then
            dbms_output.put_line('invalid filehandle');
        when utl_file.invalid_operation  then
            dbms_output.put_line('invalid operation');
        when utl_file.read_error  then
            dbms_output.put_line('read error');
        when utl_file.write_error  then
            dbms_output.put_line('write error');
        when utl_file.internal_error  then
            dbms_output.put_line('internal error');
        when others then
            dbms_output.put_line('ERROR (close_file) => '||sqlcode);
            dbms_output.put_line('MSG (close_file) => '||sqlerrm);

    end close_file;
    --
    procedure write_op (pv_str in varchar2) is
    begin
        if lv_file_or_screen='S' then
            dbms_output.put_line(pv_str);
        else
            utl_file.put_line(lg_fptr,pv_str);
        end if;
    exception
        when utl_file.invalid_path  then
            dbms_output.put_line('invalid path');
        when utl_file.invalid_mode  then
            dbms_output.put_line('invalid mode');
        when utl_file.invalid_filehandle  then
            dbms_output.put_line('invalid filehandle');
        when utl_file.invalid_operation  then
            dbms_output.put_line('invalid operation');
        when utl_file.read_error  then
            dbms_output.put_line('read error');
        when utl_file.write_error  then
            dbms_output.put_line('write error');
        when utl_file.internal_error  then
            dbms_output.put_line('internal error');
        when others then
            dbms_output.put_line('ERROR (write_op) => '||sqlcode);
            dbms_output.put_line('MSG (write_op) => '||sqlerrm);

    end write_op;
    --
    function user_or_role(pv_grantee in dba_users.username%type) 
    return varchar2 is
        --
        cursor c_use (cp_grantee in dba_users.username%type) is
        select  'USER' userrole 
        from    dba_users u 
        where   u.username=cp_grantee 
        union 
        select  'ROLE' userrole 
        from    dba_roles r 
        where   r.role=cp_grantee;
        --
        lv_use c_use%rowtype;
    begin
        open c_use(pv_grantee);
        fetch c_use into lv_use;
        close c_use;
        return lv_use.userrole;
    exception
        when others then
            dbms_output.put_line('ERROR (user_or_role) => '||sqlcode);
            dbms_output.put_line('MSG (user_or_role) => '||sqlerrm);
    end user_or_role;
    --
    procedure get_obj (pv_object in varchar2,pv_owner in varchar2) is
        --
        cursor c_main (cp_object in varchar2,cp_owner in varchar2) is
	select	g.name grantee,
		decode(o.type#,2,'TABLE',
				4,'VIEW',
				6,'SEQUENCE',
				7,'PROCEDURE',
				8,'FUNCTION',
				9,'PACKAGE',
				13,'TYPE',
				22,'LIBRARY',
				23,'DIRECTORY',
				24,'QUEUE',
				29,'JAVA CLASS',
				30,'JAVA RESOURCE',
				32,'INDEXTYPE',
				33,'OPERATOR',
				48,'CONSUMER GROUP',
				62,'EVALUATION CONTEXT',
				'UNDEFINED') object_type,
		t.name privilege,
		decode(mod(a.option$,2),2,'YES','NO') grantable,
		'--' column_name,
		'TAB' coltype
	from	sys.objauth$ a,
		sys.obj$ o,
		sys.user$ u,
		sys.user$ g,
		sys.table_privilege_map t
	where	a.obj#=o.obj#
	and	a.grantee#=g.user#
	and	a.col# is null
	and	a.privilege#=t.privilege
	and	u.user#=o.owner#
	and	u.name=cp_owner
	and	o.name=cp_object
	union
	select	g.name grantee,
		decode(o.type#,2,'TABLE',
				4,'VIEW',
				6,'SEQUENCE',
				7,'PROCEDURE',
				8,'FUNCTION',
				9,'PACKAGE',
				13,'TYPE',
				22,'LIBRARY',
				23,'DIRECTORY',
				24,'QUEUE',
				29,'JAVA CLASS',
				30,'JAVA RESOURCE',
				32,'INDEXTYPE',
				33,'OPERATOR',
				48,'CONSUMER GROUP',
				62,'EVALUATION CONTEXT',
				'UNDEFINED') object_type,
		t.name privilege,
		decode(mod(a.option$,2),2,'YES','NO') grantable,
		c.name column_name,
		'COL' coltype
	from	sys.objauth$ a,
		sys.obj$ o,
		sys.user$ u,
		sys.user$ g,
		sys.col$ c,
		sys.table_privilege_map t
	where	a.obj#=o.obj#
	and	a.grantee#=g.user#
	and	a.col#=c.col#
	and	bitand(c.property,32)=0
	and	a.col# is not null
	and	a.privilege#=t.privilege
	and	u.user#=o.owner#
	and	u.name=cp_owner
	and	o.name=cp_object
        order by 2,3,6;
        --
        lv_old_type dba_objects.object_type%type:='NOTSET';
        lv_old_priv dba_tab_privs.privilege%type:='NOTSET';
        --
        lv_userrole dba_users.username%type;
        lv_tabstop number;
        --
        procedure get_users(pv_grantee in dba_roles.role%type,pv_tabstop in out number) is
            --
            lv_tab varchar2(50):='';
            lv_loop number;
            lv_user_or_role dba_users.username%type;
            --
            cursor c_user (cp_username in dba_role_privs.grantee%type) is
            select  r.grantee,
                    r.admin_option
            from    dba_role_privs r
            where   r.granted_role=cp_username;
            --
        begin
            pv_tabstop:=pv_tabstop+1;
            for lv_loop in 1..pv_tabstop loop
                lv_tab:=lv_tab||chr(9);
            end loop;
            
            for lv_user in c_user(pv_grantee) loop
                lv_user_or_role:=user_or_role(lv_user.grantee);
                if lv_user_or_role = 'ROLE' then
	            if lv_user.grantee = 'PUBLIC' then
       			write_op(lv_tab||'Role => '||lv_user.grantee
       				||' (ADM = '||lv_user.admin_option||')');
            	    else
       			write_op(lv_tab||'Role => '||lv_user.grantee
       				||' (ADM = '||lv_user.admin_option||')'
       				||' which is granted to =>');
            	    end if;
                    get_users(lv_user.grantee,pv_tabstop);
                else
                    if upper('&&skip_user') = 'Y' and lv_user.grantee like upper('&&user_to_skip') then
                    	null;
                    else
	               	    write_op(lv_tab||'User => '||lv_user.grantee
	                		||' (ADM = '||lv_user.admin_option||')');
		    end if;
                end if;
            end loop;
            pv_tabstop:=pv_tabstop-1;
            lv_tab:='';
        exception
            when others then
                dbms_output.put_line('ERROR (get_users) => '||sqlcode);
                dbms_output.put_line('MSG (get_users) => '||sqlerrm);        
        end get_users;
        --
    begin
        write_op(chr(10));
        lv_tabstop:=1;
        for lv_main in c_main(pv_object,pv_owner) loop
            if (lv_old_type != lv_main.object_type)  then
                write_op('Object type is => '||lv_main.object_type||' ('||lv_main.coltype||') ');
            end if;
            if (lv_old_priv != lv_main.privilege) or (lv_old_type != lv_main.object_type) then
                write_op(chr(9)||'Privilege => '||lv_main.privilege||' is granted to =>');
            end if;
            lv_userrole:=user_or_role(lv_main.grantee);
            if lv_userrole='USER' then
               	if upper('&&skip_user') = 'Y' and lv_main.grantee like upper('&&user_to_skip') then
                    null;
               	else
	            write_op(chr(9)||'User => '||lv_main.grantee
                               ||' (ADM = '||lv_main.grantable||')');
                end if;
            else
            	if lv_main.grantee='PUBLIC' then
            		write_op(chr(9)||'Role => '||lv_main.grantee
            				||' (ADM = '||lv_main.grantable||')');            		
            	else
            		write_op(chr(9)||'Role => '||lv_main.grantee
            				||' (ADM = '||lv_main.grantable||')'
            				||' which is granted to =>');
            		
            	end if;
                get_users(lv_main.grantee,lv_tabstop);
            end if;
            lv_old_type:=lv_main.object_type;
            lv_old_priv:=lv_main.privilege;
        end loop;
    exception
        when others then
            dbms_output.put_line('ERROR (get_obj) => '||sqlcode);
            dbms_output.put_line('MSG (get_obj) => '||sqlerrm);
    end get_obj;
begin
    	lv_file_or_screen:= upper('&&output_method');
    	if lv_file_or_screen='F' then
	        open_file('&&file_name','&&output_dir');
    	end if;
    	write_op('Checking object => '||upper('&&owner_to_find')||'.'||upper('&&object_to_find'));
    	write_op('====================================================================');
    	get_obj(upper('&&object_to_find'),upper('&&owner_to_find'));
    	if lv_file_or_screen='F' then
        	close_file;
    	end if;
exception
    	when others then
        	dbms_output.put_line('ERROR (main) => '||sqlcode);
        	dbms_output.put_line('MSG (main) => '||sqlerrm);

end;
/

prompt
prompt For updates please visit http://www.petefinnigan.com/tools.htm
prompt
spool off

whenever sqlerror continue