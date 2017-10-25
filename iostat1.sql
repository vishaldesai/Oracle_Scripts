select 'exec sp_event_histogram_wc('direct path read',5,1);' from dual
                                           *
ERROR at line 1:
ORA-00923: FROM keyword not found where expected 


select 'exec sp_event_histogram_wc('direct path read',5,0);' from dual connect by level < 5
                                           *
ERROR at line 1:
ORA-00923: FROM keyword not found where expected 


