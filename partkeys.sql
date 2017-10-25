col partkeys_column_name head COLUMN_NAME for a30

select
    owner
  , name
  , object_type
  , column_name     partkeys_column_name
  , column_position 
from
    dba_part_key_columns
where
    upper(name) LIKE 
                upper(CASE 
                    WHEN INSTR('&1','.') > 0 THEN 
                        SUBSTR('&1',INSTR('&1','.')+1)
                    ELSE
                        '&1'
                    END
                     )
AND owner LIKE
        CASE WHEN INSTR('&1','.') > 0 THEN
            UPPER(SUBSTR('&1',1,INSTR('&1','.')-1))
        ELSE
            user
        END
/

