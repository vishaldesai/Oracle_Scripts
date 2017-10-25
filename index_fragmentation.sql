-- Refer https://jonathanlewis.wordpress.com/index-sizing/
-- Refer https://hourim.wordpress.com/2015/05/12/index-efficiency/
-- Refer https://hourim.wordpress.com/?s=p_check_free_space

set termout off verify off

define owner='AUDITDATA'         -- table owner
define table='AUDIT_OBJECT_PROPERTY'    -- table name
define index='PK_AUDIT_OBJECT_PROPERTY'    -- index name
define buckets=10           -- number of buckets
define sample=100           -- 100% scans all the index

column "free" format A5

variable c refcursor;

declare
 o all_indexes.owner%TYPE:='&owner';
 t all_indexes.table_name%TYPE:='&table';
 i all_indexes.table_name%TYPE:='&index';
 oid all_objects.object_id%TYPE;
 hsz varchar2(2000);
 n number:=&buckets;
 p number:=&sample;
 s varchar2(2000):='';
 k_min varchar2(2000);
 k_max varchar2(2000);
 k_lst varchar2(2000);
 k_nul varchar2(2000);
 k_vsz varchar2(2000);
 p_sam varchar2(2000):='';
 cursor cols is select i.column_name,i.column_position,case when data_type in ('VARCHAR2','RAW') then 3 else 1 end length_bytes
  from dba_ind_columns i join dba_tab_columns t 
  on (t.owner=i.table_owner and t.table_name=i.table_name and t.column_name=i.column_name)
  where i.table_owner=o and i.table_name=t and i.index_name=i order by column_position;
 procedure add(l in varchar2,i number default 0) is begin s:=s||chr(10)||rpad(' ',i)||l; end;
begin
 select object_id into oid from dba_objects where object_type='INDEX' and owner=o and object_name=i;
 /* Note:10640.1: block header size = fixed header (113 bytes) + variable transaction header (23*initrans) */
 select nvl(to_char(block_size - 113 - ini_trans*23),'null') header_size into hsz 
  from dba_indexes left outer join dba_tablespaces using (tablespace_name) where owner=o and index_name=i;
 for c in cols loop
  if ( c.column_position > 1 ) then k_lst:=k_lst||',' ; k_min:=k_min||',';k_max:=k_max||','; k_nul:=k_nul||' and ' ; k_vsz:=k_vsz||'+' ; end if;
  k_lst:=k_lst||c.column_name;
  k_nul:=k_nul||c.column_name|| ' is not null';
  k_min:=k_min||'min('||c.column_name||') '||c.column_name;
  k_max:=k_max||'max('||c.column_name||') '||c.column_name;
  k_vsz:=k_vsz||'nvl(vsize('||c.column_name||'),1)+'||c.length_bytes;
 end loop;
 if p != 100 then p_sam:='sample block('||p||')'; end if;
 add('with leaf_blocks as (',0);
 add('select /* cursor_sharing_exact dynamic_sampling(0) no_monitoring',1);
 add(' no_expand index_ffs('||t||','||i||') noparallel_index('||t||','||i||') */',10);
 add(k_min||','||1/(p/100)||'*count(rowid) num_rows',1);
 add(','||1/(p/100)||'*sum(1+vsize(rowid)+'||k_vsz||') vsize',1);
 add('from '||o||'.'||t||' '||p_sam||' '||t,1);
 add('where '||k_nul,1);
 add('group by sys_op_lbid('||oid||',''L'',rowid)',1);
 add('),keys as (',0);
 add('select ntile('||n||') over (order by '||k_lst||') bucket,',1);
 add(k_min||',',2);
 add('count(*) leaf_blocks, count(*)*'||hsz||' tsize,',2);
 add('sum(num_rows) num_rows,sum(vsize) vsize',2);
 add('from leaf_blocks group by '||k_lst,1);
 add(')',0);
 add('select '||k_min||',''->'' "->",'||k_max||',round(sum(num_rows)/sum(leaf_blocks)) "rows/block"',0);
 add(',round(sum(vsize)/sum(leaf_blocks)) "bytes/block",',1);
 add('case when sum(vsize)<=sum(tsize) then 100*round(1- sum(vsize) / (sum(tsize)),2) else null end "%free space",',1);
 add(' sum(leaf_blocks) "blocks",');
 --add('case when sum(vsize)<=sum(tsize)/2 then substr(rpad(''o'',5*round(1- sum(vsize) / (sum(tsize)),2),''o''),1,5) end "free"',1);
 add('substr(rpad(''o'',5*round(1- sum(vsize) / (sum(tsize)),2),''o''),1,5) "free"',1);
 add('from keys group by bucket order by bucket',0);
 
 dbms_output.put_line(s);
 begin open :c for s ; exception when others then dbms_output.put_line(s); raise; end ;
 dbms_output.put_line(s);
end;
/
set termout on 
print c
