set linesize 400
set pages 9999
col table_owner format a15
col table_name format a20
col partition_name format a20
col last_analyzed format a20
col tabpart_high_value head HIGH_VALUE_RAW for a35
col pos format 999

select
    table_owner        
  , table_name         
  , partition_position pos
  , composite          
  , partition_name
  , num_rows     
  , subpartition_count
  , last_analyzed  
  , high_value         tabpart_high_value
  , high_value_length
From
    dba_tab_partitions
where
    upper(table_name) LIKE 
                upper(CASE 
                    WHEN INSTR('&1','.') > 0 THEN 
                        SUBSTR('&1',INSTR('&1','.')+1)
                    ELSE
                        '&1'
                    END
                     )
AND table_owner LIKE
        CASE WHEN INSTR('&1','.') > 0 THEN
            UPPER(SUBSTR('&1',1,INSTR('&1','.')-1))
        ELSE
            user
        END
/
