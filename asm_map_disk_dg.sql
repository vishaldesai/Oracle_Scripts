column disk_file_path format a40
set pages 200
set linesize 200

SELECT
    NVL(a.name, '[CANDIDATE]')      disk_group_name
  , b.path                          disk_file_path
  , b.name                          disk_file_name
--  , b.failgroup                     disk_file_fail_group
FROM
    v$asm_diskgroup a RIGHT OUTER JOIN v$asm_disk b USING (group_number)
WHERE
    a.name like '%CSPROD%'
ORDER BY
    a.name;

