accept sid    prompt 'Please enter the value for SID                   :'
accept serial prompt 'Please enter the value for SERIAL#               :'
accept para   prompt 'Please enter the name of parameter               :'
accept val    prompt 'Please enter the value for parameter(TRUE/FALSE) :'

select sid,name,value,isdefault from v$ses_optimizer_env where sid=&sid and name='&para';

exec dbms_system.set_bool_param_in_session(&sid,&serial,'&para' ,&val);

--Run below query from different session to check value of parmaeter
--select sid,name,value,isdefault from v$ses_optimizer_env where sid=&sid and name='&para';



