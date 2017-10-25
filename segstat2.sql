col segstat_statistic_name head STATISTIC_NAME for a35
col subobject_name for a20

SELECT * FROM (
  SELECT 
	owner, 
    object_name, 
    SUBOBJECT_NAME,   
	statistic_name segstat_statistic_name,
	value 
  FROM 
	v$segment_statistics 
  WHERE 
	lower(owner) =lower('&1')
  and lower(object_name) =lower('&2')
  and statistic_name like '%&3%'
   order by value desc
)
--WHERE rownum <= 40
/
