set linesize 200
accept tbs     prompt 'Please enter tablespace name            : '

set feed off
set echo off
set verify off
set serveroutput on
declare
cursor c1 is select tablespace_name,file_id,max(block_id) mbid from dba_extents where tablespace_name='&&tbs' 
group by tablespace_name,file_id;
fs number;
fn varchar2(100);
ts number;
x number;
gtot number:=0;
tffs number:=0;
ffrags number:= 0;
begin
for v1 in c1 loop
	select sum(bytes)/1024/1024 into fs from dba_free_space where tablespace_name = v1.tablespace_name and
        file_id = v1.file_id and block_id>v1.mbid;
        select file_name,bytes/1024/1024 into fn,ts from dba_data_files where file_id=v1.file_id and tablespace_name=v1.tablespace_name;
        select sum(bytes/1024/1024) into tffs from 
        (select a.bytes/1024/1024 as bytes from dba_free_space a where file_id=v1.file_id and tablespace_name=v1.tablespace_name
         union all
         select 0.000001 as bytes from dual);
x:=(ts-fs)+64;
if ts>x then
dbms_output.put_line('alter database datafile ' || '''' || fn || '''' || ' resize ' ||  round(x) || 'm' || '--total size' || round(ts) || 'm;' );

gtot :=  gtot + (ts-x);
end if;

ffrags := nvl(tffs - fs,0);
dbms_output.put_line('--alter database datafile ' || '''' || fn || '''' || ' resize ' ||  round(x) || 'm' || '--frag size' || round(ffrags) || 'm;');

end loop;

dbms_output.put_line('Total space reclaimation:' || gtot || 'MB');
end;
/