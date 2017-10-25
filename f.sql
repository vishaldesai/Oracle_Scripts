col view_name for a25 wrap
col text for a60 word_wrap
set linesize 120
set pages 200
prompt Search for Fixed view (V$ view) text containing %&1%

select view_name, view_definition text from v$fixed_View_definition where upper(view_definition) like upper('%&1%');

