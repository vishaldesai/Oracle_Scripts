.
set termout off
set verify off
set markup html on spool on 
--def _html_spoolfile=html_&_tpt_tempfile..html
spool c:\temp\html_output.html
--list
/
spool off
set markup html off spool off 
set termout on
host C:\Program Files\Internet Explorer\iexplore c:\temp\html_output.html

