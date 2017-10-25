set serveroutput on
declare
  banner             VARCHAR2(80);
  c1                 sys_refcursor;
  cpus               NUMBER;
  cpusers            NUMBER;
  db_name            VARCHAR2(9);
  def_servers_max    NUMBER;
  def_servers_target NUMBER;
  granule_size       NUMBER;
  large_pool         NUMBER;
  large_pool_abs     NUMBER;
  large_pool_asmm    NUMBER;
  large_pool_smax    NUMBER;
  large_pool_smin    NUMBER;
  large_pool_strgt   NUMBER;
  lp_servers         NUMBER;
  mem_tgt            NUMBER;
  min_msg_pool       NUMBER;
  msg_size           NUMBER;
  nam                VARCHAR2(512);
  parbuf_hwm         NUMBER;
  parbuf_hwm_mem     NUMBER;
  parsvr_hwm         NUMBER;
  pga_agg            NUMBER;
  ptpcpu             NUMBER;
  servers_max        NUMBER;
  servers_min        NUMBER;
  servers_target     NUMBER;
  sga_tgt            NUMBER;
  subpools           NUMBER;
  use_lp             VARCHAR2(5);
  val                VARCHAR2(512);
begin
  /* Get db ID */
  select distinct NAME into db_name from v$database;
  select distinct BANNER into banner from V$version where banner like 'Oracle Database%';
  /* Get 11.2 parameters */
  open c1 for select nam.ksppinm NAME, val.KSPPSTVL VALUE from x$ksppi nam, x$ksppsv val where nam.indx = val.indx and nam.ksppinm in ('_PX_use_large_pool','_kghdsidx_count','_ksmg_granule_size','_parallel_min_message_pool','cpu_count','large_pool_size','memory_target','parallel_execution_message_size','parallel_max_servers','parallel_min_servers','parallel_servers_target','parallel_threads_per_cpu') order by 1;
  fetch c1 into nam, val;
  use_lp          := val;
  fetch c1 into nam, val;
  subpools        := val;
  fetch c1 into nam, val;
  granule_size    := val;
  fetch c1 into nam, val;
  min_msg_pool     :=val;
  fetch c1 into nam, val;
  cpus            := val;
  fetch c1 into nam, val;
  large_pool      := val;
  fetch c1 into nam, val;
  mem_tgt         := val;
  fetch c1 into nam, val;
  msg_size        := val;
  fetch c1 into nam, val;
  servers_max     := val;
  fetch c1 into nam, val;
  servers_min     := val;
  fetch c1 into nam, val;
  servers_target  := val;
  fetch c1 into nam, val;
  ptpcpu          := val;
  close c1;
  /* Get dynamic Memory settings */
  open c1 for select component, current_size from v$memory_dynamic_components where component in ('PGA Target','SGA Target','large pool') order by 1;
  fetch c1 into nam, val;
  pga_agg         := val;
  fetch c1 into nam, val;
  sga_tgt         := val;
  fetch c1 into nam, val;
  large_pool_asmm := val;
  close c1;
  /* Get Parallel Server HWM */
  open c1 for select value from v$pq_sysstat where statistic like 'Servers Highwater%';
  fetch c1 into val;
  parsvr_hwm      := val;
  close c1;
  /* Get Parallel processing statistics */
  open c1 for select value from v$px_process_sysstat where statistic like 'Buffers HWM%';
  fetch c1 into val;
  parbuf_hwm      := val;
  close c1;
  /* Perform calculations and display results */
  dbms_output.put_line('11gR2: CALCULATIONS for the LARGE_POOL_SIZE with parallel processing.');
  dbms_output.put_line('Version 1.0b, 2012.');
  dbms_output.put_line('Database Identification:');
  dbms_output.put_line('The database name is ' || db_name || '.');
  dbms_output.put_line('Version: ' || banner );
  dbms_output.put_line('LARGE_POOL_SIZE:');
  large_pool := large_pool/1024/1024;
  dbms_output.put_line('The initial setting is ' || large_pool || 'Mb.');
  if large_pool = 0 then
     dbms_output.put('If set, the ');
  else
     dbms_output.put('The ');
  end if;
  large_pool_abs := (granule_size * subpools)/1024/1024;
  dbms_output.put_line('absolute minimum is ' || large_pool_abs || 'Mb (a lower non-0 value is over-ridden).');
  large_pool_asmm := large_pool_asmm/1024/1024;
  if sga_tgt > 0 then
     dbms_output.put_line('The current dynamic size is ' || large_pool_asmm || 'Mb.');
  end if;
  /* Parallel processing */
  dbms_output.put_line('Parallel Processing:');
  if servers_min > 0 then
     large_pool_smin := (granule_size * (servers_min + 2))/1024/1024; /* From unpublished Bug 13096841 */
     dbms_output.put_line('For parallel_min_servers=' || servers_min || ', the minimum Large Pool is ' || large_pool_smin || 'Mb.');
  else
     dbms_output.put_line('The parallel_min_servers setting is 0.');
  end if;
  /* Calculate Concurrent Parallel Users */
  cpusers := 1;
  if pga_agg > 0 then
     cpusers := 2;
     if sga_tgt > 0 then
        cpusers := 4;
     end if;
  end if;
  if mem_tgt > 0 then
     cpusers := 4;
  end if;
  if servers_target > 0 then
     large_pool_strgt := (granule_size * servers_target)/1024/1024/2; /* assume 2 servers use 1 granule */
     dbms_output.put_line('For parallel_servers_target=' || servers_target || ', the Large Pool may grow to ' || large_pool_strgt || 'Mb.');
  else
     dbms_output.put_line('The parallel_servers_target setting is 0');
  end if;
  /* Calculate the default for parallel_max_servers */
  /* 11.2 PARALLEL_THREADS_PER_CPU x CPU_COUNT x concurrent_parallel_users x 5 */
  def_servers_max := ptpcpu * cpus * cpusers * 5;
  /* Calculate Large Pool usage (theoretical) */
  if servers_max > 0 then
     lp_servers := servers_max;
  else
     lp_servers := def_servers_max;
  end if;
  large_pool_smax := (granule_size * lp_servers)/1024/1024/2; /* assume 2 servers use 1 granule */
  if servers_max > 0 then
     dbms_output.put('For parallel_max_servers=' || servers_max );
  else
     dbms_output.put_line('No Parallelism because parallel_max_servers=0.');
     dbms_output.put('If enabled with the parallel_max_servers DEFAULT');
  end if;
  dbms_output.put_line(', the Large Pool may grow to ' || large_pool_smax || 'Mb.');
  /* Calculate the default for parallel_servers_target */
  /* 11.2 PARALLEL_THREADS_PER_CPU * CPU_COUNT * concurrent_parallel_users * 2 */
  def_servers_target := ptpcpu * cpus * cpusers * 2;
  dbms_output.put_line('The DEFAULT for parallel_servers_target is ' || def_servers_target || ' (over-rides 0 setting).');
  dbms_output.put_line('The DEFAULT for parallel_max_servers is ' || def_servers_max || '.');
  /* Additional PX information */
  dbms_output.put_line('Additional:');
  dbms_output.put('The Parallel Servers High Water Mark is ');
  if parsvr_hwm > 0 then
     dbms_output.put_line(parsvr_hwm || '.');
  else
     dbms_output.put_line('currently 0 (yet to be set).');
  end if;
  dbms_output.put('This instance will put the "PX msg pool" allocation in the ');
  if sga_tgt = 0 and use_lp != 'TRUE' then
     dbms_output.put_line('Shared Pool.');
  else
     dbms_output.put_line('Large Pool.');
  end if;
  dbms_output.put('The initial size of the "PX msg pool" allocation ');
  if min_msg_pool > 0 then
      dbms_output.put_line('is ' || min_msg_pool || ' bytes.');
  else
     dbms_output.put_line('has been manually set to 0.');
  end if;
  dbms_output.put('The Parallel Buffers High Water Mark is ');
  if parbuf_hwm > 0 then
     dbms_output.put_line(parbuf_hwm || ' buffers,');
     parbuf_hwm_mem := parbuf_hwm * msg_size;
     dbms_output.put_line('that required ' || parbuf_hwm_mem || ' bytes of memory.');
  else
     dbms_output.put_line('currently 0.');
  end if;
end;
/

