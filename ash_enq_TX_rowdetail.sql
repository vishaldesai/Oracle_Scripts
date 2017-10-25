set linesize 500
set pages 9999
column owner format a15
column object_name format a25
accept n prompt 'Enter number of days	:'

SELECT
  o.owner ,
  o.object_name object_name ,
  CURRENT_FILE# file# ,
  CURRENT_BLOCK# block# ,
  CURRENT_ROW# row# ,
  COUNT(1)
FROM
  --v$active_session_history ash,
  dba_hist_active_sess_history ash,
  dba_objects o
WHERE
  event            = 'enq: TX - row lock contention'
AND ash.sample_time >= systimestamp - &n 
AND o.object_id (+)= ash.CURRENT_obj#
GROUP BY
  o.owner,
  o.object_name,
  CURRENT_FILE#,
  CURRENT_BLOCK#,
  CURRENT_ROW#
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