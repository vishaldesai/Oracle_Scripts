break on sql_id skip 1

col sql_id       format a13           heading 'SQL Id'
col sqt          format a50  trunc    heading 'SQL Text'
col execs        format    999,999,990  heading 'Execs'
col gets         format  9,999,999,990  heading 'Gets'
col bpe          format  9,999,999,990  heading 'per Exec'
col reads        format    999,999,990  heading 'Reads'
col rpe          format  9,999,999,990  heading 'per Exec'
col rws          format    999,999,990  heading 'Rows'
col rwpe         format  9,999,999,990  heading 'per Exec'
col cpu_time     format     999,990.90  heading 'CPU (s)'
col cppe         format     999,990.90   heading 'per Exec(s)'
col elapsed_time format   9,999,990.90  heading 'Ela (s)'
col elpe         format   9,999,990.90   heading 'per Exec(s)'
col clwait_time  format     999,990.90  heading 'Clu (s)'
col clpe         format     999,990.90  heading 'per Exe(s)'
col iowait_time  format     999,990.90  heading 'IOWait (s)'
col iope         format     999,990.90  heading 'per Exe(s)'

col nl           format  a13 newline  heading ''
col bp           heading ''
col ela_pct_dbt  format  9,999,990.90  heading '% of DB time'
col cpu_pct      format    999,990.90  heading '% of DB CPU'
col gets_pct     format 99,999,990.90 heading '% of Gets'
col rds_pct      format   9999,990.90  heading '% of Reads'
col execs_pct    format   9999,990.90  heading '% of Execs'
col clwait_pct   format    999,990.90  heading '% of CluTm'
col iowait_pct   format    999,990.90  heading '% of IO Tm'

col ep           format a12       heading ''
col sqtn         format a50 trunc heading ''

--top sql by cpu
select 
 		          s.sql_id
      		, cpu_time/&ustos       cpu_time
      		, elapsed_time/&ustos   elapsed_time
     		    , iowait_time/&ustos    iowait_time
      		, gets
      		, reads
      		, rws
      		, clwait_time/&ustos    clwait_time
      		, execs
      		, substr(regexp_replace(st.sql_text,'(\s)+',' '),1,50) sqt
      		, '             ' nl
      		, cpu_time/&ustos/decode(execs,0,null,execs)           cppe
      		, elapsed_time/&ustos/decode(execs,0,null,execs)       elpe
      		, iowait_time/&ustos/decode(execs,0,null,execs)        iope
      		, gets/decode(execs,0,null,execs)                      bpe
      		, reads/decode(execs,0,null,execs)                     rpe
      		, rws/decode(execs,0,null,execs)                       rwpe
      		, clwait_time/&ustos/decode(execs,0,null,execs)        clpe
      		, '          '    ep
      		, substr(regexp_replace(st.sql_text,'(\s)+',' '),51,50)   sqtn
      		, '            ' nl
      		, cpu_time/decode(:tdbcpu,0,null,:tdbcpu)*100 cpu_pct
      		-- , '                                                                  ' bp
      		, elapsed_time/decode(:tdbtim,0,null,:tdbtim)*100       ela_pct_dbt
      		, iowait_time/decode(:tiowtm,0,null,:tiowtm)*100        iowait_pct
      		, gets/decode(:tgets,0,null,:tgets)*100                 gets_pct
      		, reads/decode(:trds,0,null,:trds)*100                  rds_pct
      		, '            '                                        bp
      		, clwait_time/decode(:tclutm,0,null,:tclutm)*100        clwait_pct
      		, execs/decode(:texecs,0,null,:texecs)*100              execs_pct
      		, substr(regexp_replace(st.sql_text,'(\s)+',' '),101,50)  sqtn
    from  
   (select * from
      ( select sql_id
           , sum(executions_delta)      execs
           , sum(buffer_gets_delta)     gets
           , sum(disk_reads_delta)      reads
           , sum(rows_processed_delta)  rws
           , sum(cpu_time_delta)        cpu_time
           , sum(elapsed_time_delta)         elapsed_time
           , sum(iowait_delta)         iowait_time
           , sum(clwait_delta)         clwait_time
        from dba_hist_sqlstat
       where snap_id  > :bid
         and snap_id <= :eid
         and dbid     = :dbid
       group by sql_id
       order by sum(cpu_time_delta) desc)
    where rownum <= &&top_n ) s
  , dba_hist_sqltext st
 where st.dbid = :dbid
   and st.sql_id = s.sql_id
 order by cpu_time desc, sql_id;
