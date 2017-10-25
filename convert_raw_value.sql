var n number
exec dbms_stats.convert_raw_value('&1', :n);
print :n