prompt Show shared pool memory usage of SQL statement with hash value &1


SELECT
--    sql_text
--  , sql_fulltext
    hash_value
--  , sql_id
  , heap_desc
  , structure
  , function
  , chunk_com
--  , chunk_ptr
  , alloc_class
  , chunk_type
--  , subheap_desc
  , sum(chunk_size) total_size
  , trunc(avg(chunk_size)) avg_size
  , count(*) chunks
FROM
    v$sql_shared_memory
WHERE
    hash_value in (&1)
GROUP BY
    hash_value
--  , sql_id
  , heap_desc
  , structure
  , function
  , chunk_com
--  , chunk_ptr
  , alloc_class
  , chunk_type
--  , subheap_desc
ORDER BY
    total_size DESC
/

