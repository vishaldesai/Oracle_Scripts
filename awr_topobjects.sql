set linesize 200
set pages 200
set verify off
set pages 9999
column event_name format a40
accept start_date      prompt 'Please enter start_date(mm/dd/yy)    :'
accept end_date        prompt 'Please enter end_date  (mm/dd/yy)    :'

select snap_id,begin_interval_time from dba_hist_snapshot 
where begin_interval_time>=to_date('&start_date','mm/dd/yy')
and   begin_interval_time<=to_date('&end_date','mm/dd/yy')+1
order by snap_id;

accept ssnap      prompt 'Enter value for start snap_id   :'
accept esnap      prompt 'Enter value for end snap_id     :'
select 'LOGICAL_READS_DELTA' as metric_name from dual
union all
select 'BUFFER_BUSY_WAITS_DELTA' as metric_name from dual
union all
select 'DB_BLOCK_CHANGES_DELTA' as metric_name from dual
union all
select 'PHYSICAL_READS_DELTA' as metric_name  from dual
union all
select 'PHYSICAL_WRITES_DELTA' as metric_name from dual
union all
select 'PHYSICAL_READS_DIRECT_DELTA' as metric_name from dual
union all
select 'PHYSICAL_WRITES_DIRECT_DELTA' as metric_name from dual
union all
select 'ITL_WAITS_DELTA' as metric_name from dual
union all
select 'ROW_LOCK_WAITS_DELTA' as metric_name from dual
union all
select 'GC_CR_BLOCKS_SERVED_DELTA' as metric_name from dual
union all
select 'GC_CU_BLOCKS_SERVED_DELTA' as metric_name from dual
union all
select 'GC_BUFFER_BUSY_DELTA' as metric_name from dual
union all
select 'GC_CR_BLOCKS_RECEIVED_DELTA' as metric_name from dual
union all
select 'GC_CU_BLOCKS_RECEIVED_DELTA' as metric_name from dual
union all
select 'TABLE_SCANS_DELTA' as metric_name from dual
union all
select 'CHAIN_ROW_EXCESS_DELTA' as metric_name from dual
union all
select 'PHYSICAL_READ_REQUESTS_DELTA' as metric_name from dual
union all
select 'PHYSICAL_WRITE_REQUESTS_DELTA' as metric_name from dual
union all
select 'OPTIMIZED_PHYSICAL_READS_DELTA' as metric_name from dual;




accept  metric     prompt 'Enter metric name from above		:'
accept  topn       prompt 'Enter top n=	:'
accept  inst_no    prompt 'Enter instance number:'

column owner format a15
column object_name format a35
column subobject_name format a30

SELECT owner,
  object_name,
  sm AS &metric,
  round(sm*100/tot,0) AS "% &metric"
FROM
  (SELECT owner,
    object_name,
    SUM(metric) AS sm,
    tot
  FROM
    (SELECT owner,
      object_name,
      metric,
      tot
    FROM
      (SELECT seg.obj#,
        SUM(&metric) AS metric
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      GROUP BY obj#
      ) s,
      (SELECT SUM(&metric) AS tot
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      ) t,
      dba_objects
    WHERE object_id = s.obj#
    ORDER BY 3 DESC
    )
  GROUP BY owner,object_name, tot
  ORDER BY 3 DESC, 1,2
  )
WHERE rownum<=&topn;

break on object_name
compute sum of &metric on object_name

select owner,object_name,subobject_name,sm as &metric,round(sm*100/tot,2) as "% &metric" from(
SELECT owner,
    object_name,
    subobject_name,
    SUM(metric) AS sm,
    tot
  FROM
    (SELECT owner,
      object_name,
      subobject_name,
      metric,
      tot
    FROM
      (SELECT seg.obj#,
        SUM(&metric) AS metric
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      GROUP BY obj#
      ) s,
      (SELECT SUM(&metric) AS tot
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      ) t,
      dba_objects
    WHERE object_id = s.obj#
    ORDER BY 4 DESC
    )
	where (owner,object_name)
	in (SELECT owner,
  object_name
FROM
  (SELECT owner,
    object_name,
    SUM(metric) AS sm,
    tot
  FROM
    (SELECT owner,
      object_name,
      metric,
      tot
    FROM
      (SELECT seg.obj#,
        SUM(&metric) AS metric
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      GROUP BY obj#
      ) s,
      (SELECT SUM(&metric) AS tot
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      ) t,
      dba_objects
    WHERE object_id = s.obj#
    ORDER BY 3 DESC
    )
  GROUP BY owner,object_name, tot
  ORDER BY 3 DESC
  )
WHERE rownum<=&topn)
  GROUP BY owner,object_name,subobject_name, tot
)   order by owner,object_name,4 desc;

clear breaks
clear computes

  /*

SELECT owner,
  object_name,
  subobject_name,
  sm AS &metric,
  round(sm*100/tot,0) AS "% &metric"
FROM
  (SELECT owner,
    object_name,
    subobject_name,
    SUM(metric) AS sm,
    tot
  FROM
    (SELECT owner,
      object_name,
      subobject_name,
      metric,
      tot
    FROM
      (SELECT seg.obj#,
        SUM(&metric) AS metric
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      GROUP BY obj#
      ) s,
      (SELECT SUM(&metric) AS tot
      FROM dba_hist_seg_stat SEG,
           dba_hist_snapshot s
      WHERE s.snap_id       = seg.snap_id
      AND s.instance_number = seg.instance_number
      AND s.instance_number = &inst_no
      AND s.snap_id >= &ssnap
      AND s.snap_id <= &esnap
      ) t,
      dba_objects
    WHERE object_id = s.obj#
    ORDER BY 4 DESC
    )
  GROUP BY owner,object_name,subobject_name, tot
  ORDER BY 4 DESC
  )
WHERE rownum<=&topn+30;
*/