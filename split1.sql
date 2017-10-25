SELECT /*+ parallel(8) */
  'rowid between '''
  ||sys.dbms_rowid.rowid_create(1, d.oid, c.fid1, c.bid1, 0)
  ||''' and '''
  || sys.dbms_rowid.rowid_create(1, d.oid, c.fid2, c.bid2, 9999)
  ||''''
FROM
  (
    SELECT DISTINCT
      b.rn,
      first_value(a.fid) over (partition BY b.rn order by a.fid,
      a.bid rows BETWEEN unbounded preceding AND unbounded following)
      fid1,
      last_value(a.fid) over (partition BY b.rn order by a.fid, a.bid  rows BETWEEN unbounded preceding AND unbounded following) fid2,
      first_value(DECODE(SIGN(range2-range1), 1, a.bid+((b.rn-   a.range1)                     *a.chunks1), a.bid)) over (
      partition BY b.rn order by a.fid, a.bid rows BETWEEN unbounded    preceding AND unbounded following) bid1,
      last_value(DECODE(SIGN(range2-range1), 1, a.bid+((b.rn-a.range1  +1)*a.chunks1)-1, (a.bid+a.blocks- 1))) over (partition BY b.rn order by a.fid, a.bid rows BETWEEN
      unbounded preceding AND unbounded following) bid2
    FROM
      (
        SELECT
          fid,
          bid,
          blocks,
          chunks1,
          TRUNC((sum2-blocks+1-0.1)/chunks1) range1,
          TRUNC((sum2-0.1)/chunks1) range2
        FROM
          (
            SELECT
              relative_fno fid,
              block_id bid,
              blocks,
              SUM(blocks) over () sum1,
              TRUNC((SUM(blocks) over ())/50000) chunks1,
              SUM(blocks) over (order by relative_fno, block_id) sum2
            FROM
              dba_extents
            WHERE
              segment_name = upper('DOCVERSION')
            AND owner      = 'ICMPOSSIT1'
          )
        WHERE
          sum1 >
          50000
      )
      a,
      (
        SELECT
          rownum-1 rn
        FROM
          dual
          CONNECT BY level <= 50000
      )
      b
    WHERE
      b.rn BETWEEN a.range1 AND a.range2
  )
  c,
  (
    SELECT
      MAX(data_object_id) oid
    FROM
      dba_objects
    WHERE
      object_name       = upper('DOCVERSION')
    AND owner           = 'ICMPOSSIT1'
    AND data_object_id IS NOT NULL
  )
  d;