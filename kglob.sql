col kglob_addrlen new_value kglob_addrlen

set termout off
select vsize(addr)*2 kglob_addrlen from x$dual;
set termout on

var printtab2_cursor varchar2(4000)

exec :printtab2_cursor:='select * from x$kglob where kglhdadr = hextoraw(upper(lpad(''&1'',&kglob_addrlen,''0'')))'

@@printtab2
