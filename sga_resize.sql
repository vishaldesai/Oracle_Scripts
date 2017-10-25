set linesize 120                              
set pagesize 60                               
                                              
set trimspool on                              
                                              
break on timed_at skip 1                      
                                              
column oper_type format a14                   
column component format a24                   
column parameter format a21                   
                                              
select                                        
    to_char(start_time,'hh24:mi:ss') timed_at,
    oper_type,                                
    component,                                
    parameter,                                
    oper_mode,                                
    initial_size,                             
    final_size                                
from                                          
    v$sga_resize_ops                          
where                                         
    start_time >= trunc(sysdate)              
order by                                      
    start_time, component                     
;                                             