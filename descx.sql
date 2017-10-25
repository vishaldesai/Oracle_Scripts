set linesize 400
set pages 9999
COL desc_column_id 		HEAD "Col#" FOR A4
COL desc_column_name	HEAD "Column Name" FOR A40
COL desc_data_type		HEAD "Type" FOR A20 WORD_WRAP
COL desc_nullable		HEAD "Null?" FOR A10
COL desc_density        HEAD "Density" FOR 9.99999999999 
col low_value format a60
col high_value format a100
--prompt eXtended describe of &1

SELECT
	CASE WHEN hidden_column = 'YES' THEN 'H' ELSE ' ' END||
	LPAD(column_id,3)	desc_column_id,
    SEGMENT_COLUMN_ID   seg_col_id,
--    owner,
--    table_name,
	column_name	desc_column_name,
	CASE WHEN nullable = 'N' THEN 'NOT NULL' ELSE NULL END AS desc_nullable,
	data_type||CASE 
--					WHEN data_type = 'NUMBER' THEN '('||data_precision||CASE WHEN data_scale = 0 THEN NULL ELSE ','||data_scale END||')' 
					WHEN data_type = 'NUMBER' THEN '('||data_precision||','||data_scale||')' 
					ELSE '('||data_length||')'
				END AS desc_data_type,
--	data_default,
	num_distinct,
	density             desc_density,
	num_nulls,
    CASE WHEN histogram = 'NONE'  THEN null ELSE histogram END histogram,
	num_buckets,
	low_value,
	high_value
	--,'--' desc_succeeded
FROM
	dba_tab_cols
WHERE
	upper(table_name) LIKE 
				upper(CASE 
					WHEN INSTR('&1','.') > 0 THEN 
					    SUBSTR('&1',INSTR('&1','.')+1)
					ELSE
					    '&1'
					END
				     )
AND	owner LIKE
		CASE WHEN INSTR('&1','.') > 0 THEN
			UPPER(SUBSTR('&1',1,INSTR('&1','.')-1))
		ELSE
			user
		END
ORDER BY
    owner ASC
  , table_name ASC
  ,	column_id ASC
/

