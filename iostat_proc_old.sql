create or replace procedure iostat (v_interval IN number,v_header IN number) is

cursor b_c1 is
select name,value from v$sysstat
where name in ('physical reads direct',
	       'physical reads direct temporary tablespace',
	       'physical reads direct (lob)',
               'physical read IO requests',
               'physical reads',
	       'physical writes direct',
	       'physical writes direct temporary tablespace',
	       'physical writes direct (lob)',
               'physical write IO requests',
               'physical writes',
               'redo writes',
               'redo size');

cursor a_c1 is
select name,value from v$sysstat
where name in ('physical reads direct',
	       'physical reads direct temporary tablespace',
	       'physical reads direct (lob)',
               'physical read IO requests',
               'physical reads',
	       'physical writes direct',
	       'physical writes direct temporary tablespace',
	       'physical writes direct (lob)',
               'physical write IO requests',
               'physical writes',
               'redo writes',
               'redo size');

b_prd number;
b_prdt number;
b_prdl number;
b_prIOr number;
b_prMBPS number;
b_wrd number;
b_wrdt number;
b_wrdl number;
b_wIOr number;
b_wMBPS number;
b_rw number;
b_rs number;

a_prd number;
a_prdt number;
a_prdl number;
a_prIOr number;
a_prMBPS number;
a_wrd number;
a_wrdt number;
a_wrdl number;
a_wIOr number;
a_wMBPS number;
a_rw number;
a_rs number;


t_prd number;
t_prdt number;
t_prdl number;
t_prIOr number;
t_prMBPS number;
t_wrd number;
t_wrdt number;
t_wrdl number;
t_wIOr number;
t_wMBPS number;
t_rw number;
t_rs number;

blksize number;

begin

select value into blksize
from v$parameter
where name = 'db_block_size';


if v_header = 1 then
dbms_output.put_line('----------READS------------------------------WRITES-------------------' || '--Total READS--' || '--Total WRITES--');
dbms_output.put_line('Direct Direct Direct Read   Read   Direct Direct Direct Write  Write  ' || ' ');
dbms_output.put_line('------ Temp   LOB    IO     MBPS   ------ Temp   LOB    IO     MBPS   ' || ' ');
end if;

for b_v1 in b_c1 loop
	if    b_v1.name = 'physical reads direct'                      then b_prd :=b_v1.value;
	elsif b_v1.name = 'physical reads direct temporary tablespace' then b_prdt:=b_v1.value;
	elsif b_v1.name = 'physical reads direct (lob)'   	       then b_prdl:=b_v1.value;
	elsif b_v1.name = 'physical read IO requests'                  then b_prIOr:=b_v1.value;
	elsif b_v1.name = 'physical reads'                             then b_prMBPS:=b_v1.value;
	elsif b_v1.name = 'physical writes direct'                     then b_wrd:=b_v1.value;
	elsif b_v1.name = 'physical writes direct temporary tablespace' then b_wrdt:=b_v1.value;
	elsif b_v1.name = 'physical writes direct (lob)'               then b_wrdl:=b_v1.value;
	elsif b_v1.name = 'physical write IO requests'                 then b_wIOr:=b_v1.value;
	elsif b_v1.name = 'physical writes'                            then b_wMBPs:=b_v1.value;
	elsif b_v1.name = 'redo writes'                                then b_rw:=b_v1.value;
	elsif b_v1.name = 'redo size'                                  then b_rs:=b_v1.value;
        end if;
end loop;

dbms_lock.sleep(v_interval);

for a_v1 in a_c1 loop
	if    a_v1.name = 'physical reads direct'                      then a_prd :=a_v1.value;
	elsif a_v1.name = 'physical reads direct temporary tablespace' then a_prdt:=a_v1.value;
	elsif a_v1.name = 'physical reads direct (lob)'   	       then a_prdl:=a_v1.value;
	elsif a_v1.name = 'physical read IO requests'                  then a_prIOr:=a_v1.value;
	elsif a_v1.name = 'physical reads'                             then a_prMBPS:=a_v1.value;
	elsif a_v1.name = 'physical writes direct'                     then a_wrd:=a_v1.value;
	elsif a_v1.name = 'physical writes direct temporary tablespace' then a_wrdt:=a_v1.value;
	elsif a_v1.name = 'physical writes direct (lob)'               then a_wrdl:=a_v1.value;
	elsif a_v1.name = 'physical write IO requests'                 then a_wIOr:=a_v1.value;
	elsif a_v1.name = 'physical writes'                            then a_wMBPs:=a_v1.value;
	elsif a_v1.name = 'redo writes'                                then a_rw:=a_v1.value;
	elsif a_v1.name = 'redo size'                                  then a_rs:=a_v1.value;
        end if;
end loop;

t_prd	:=	round((a_prd	 -	b_prd)/v_interval);
t_prdt	:=	round((a_prdt	 -	b_prdt)/v_interval);
t_prdl	:=	round((a_prdl	 -	b_prdl)/v_interval);
t_prIOr	:=	round((a_prIOr	 -	b_prIOr)/v_interval);
t_prMBPS:=	round((a_prMBPS  -	b_prMBPS)*blksize/(v_interval*1024*1024));
t_wrd	:=	round((a_wrd	 -	b_wrd)/v_interval);
t_wrdt	:=	round((a_wrdt	 -	b_wrdt)/v_interval);
t_wrdl	:=	round((a_wrdl	 -	b_wrdl)/v_interval);
t_wIOr	:=	round((a_wIOr	 -	b_wIOr)/v_interval);
t_wMBPS	:=	round((a_wMBPS -	b_wMBPS)*blksize/(v_interval*1024*1024));
t_rw	:=	round((a_rw	 -	b_rw)/v_interval);
t_rs	:=	round((a_rs	 -	b_rs)/v_interval);


dbms_output.put_line (	lpad(t_prd,6,' ') 	        || 
			lpad(t_prdt,7,' ') 		|| 
			lpad(t_prdl,7,' ') 		|| 
			lpad(t_prIOr,7,' ') 		|| 
			lpad(t_prMBPS,7,' ') 		||
			lpad(t_wrd,7,' ') 		|| 
			lpad(t_wrdt,7,' ') 		|| 
			lpad(t_wrdl,7,' ')  		|| 
			lpad(t_wIOr,7,' ')  		|| 
			lpad(t_wMBPS,7,' ')
                     );


end;
/