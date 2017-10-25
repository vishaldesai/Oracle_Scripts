SELECT
    OPERATION_ID 
  , IT_TYPE      
  , IT_LEVEL     
  , IT_ORDER     
  , IT_CALL_TIME 
  , PNUM + 1 real_partnum     
  , SPNUM +1   subpartnum       
  , APNUM        
FROM
   kkpap_pruning
/

