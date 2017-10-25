prompt Show SPFILE parameters from v$spparameter matching %&1%
col sp_name head NAME for a40
col sp_value head VALUE for a80
col sp_sid head SID for a10

select sid sp_sid, name sp_name, value sp_value, isspecified from v$spparameter where lower(name) like lower('%&1%') and isspecified = 'TRUE';
