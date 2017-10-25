set linesize 500
set pages 9999
column owner format a15
column object_name format a25


SELECT
  o.owner ,
  o.object_name object_name ,
  ROW_WAIT_FILE# file# ,
  ROW_WAIT_BLOCK# block# ,
  ROW_WAIT_ROW# row# ,
  COUNT(1)
FROM
  v$session ses,
  dba_objects o
WHERE
  event            = 'enq: TX - row lock contention'
AND o.object_id (+)= ses.row_wait_obj#
GROUP BY
  o.owner,
  o.object_name,
  ROW_WAIT_FILE#,
  ROW_WAIT_BLOCK#,
  ROW_WAIT_ROW#
ORDER BY
  COUNT(1);
  
accept owner      	prompt 'Enter owner		:'
accept table_name   prompt 'Enter table_name	:'
accept file			prompt 'Enter file		:'
accept block		prompt 'Enter block		:'
accept row			prompt 'Enter row		:'
  
SELECT
  *
FROM
  &owner..&table_name
WHERE
    dbms_rowid.rowid_relative_fno(rowid) = &file
AND dbms_rowid.rowid_block_number(ROWID) = &block
AND dbms_rowid.rowid_row_number(ROWID)   = &row;