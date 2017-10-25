accept owner      prompt 'Please enter the value for owner                  : '
accept table_name prompt 'Please enter the value for table_name             : '
REM
REM Column statistics
REM
set linesize 400
set pages 9999
set head on
COLUMN name FORMAT A30
COLUMN #dst FORMAT 99999999999

COLUMN dens FORMAT 9.99999
COLUMN #null FORMAT 9999999999
COLUMN avglen FORMAT 999999
COLUMN histogram FORMAT A30
COLUMN buckets FORMAT 999999 justify right
column num_buckets format 999999
COLUMN low_value FORMAT A80 justify right
COLUMN high_value FORMAT A100 justify right

SELECT column_name AS "NAME", 
       num_distinct AS "#DST", 
       density AS "DENS", 
       num_nulls AS "NULLS", 
       avg_col_len AS "AVGLEN", 
       histogram, 
       num_buckets AS Buckets,
       low_value, 
       high_value
FROM dba_tab_col_statistics
WHERE owner = '&owner'
  and table_name = '&table_name';

set serveroutput on

exec dbms_output.put_line( 'To find actual values of low_value and high_value open script');
/*
cast_to_binary_double
cast_to_binary_float
cast_to_binary_integer
cast_to_number
cast_to_nvarchar2
cast_to_raw
cast_to_varchar2

convert_raw_value
convert_raw_value_nvarchar
conver_raw_value_rowid

PAUSE

COLUMN low_value FORMAT 9999
COLUMN high_value FORMAT 9999

SELECT utl_raw.cast_to_number(low_value) AS low_value,
       utl_raw.cast_to_number(high_value) AS high_value
FROM user_tab_col_statistics
WHERE table_name = 'T'
AND column_name = 'VAL1';

PAUSE

DECLARE
  l_low_value user_tab_col_statistics.low_value%TYPE;
  l_high_value user_tab_col_statistics.high_value%TYPE;
  l_val1 t.val1%TYPE;
BEGIN
  SELECT low_value, high_value
  INTO l_low_value, l_high_value
  FROM user_tab_col_statistics
  WHERE table_name = 'T'
  AND column_name = 'VAL1';
  
  dbms_stats.convert_raw_value(l_low_value, l_val1);
  dbms_output.put_line('low_value: ' || l_val1);
  dbms_stats.convert_raw_value(l_high_value, l_val1);
  dbms_output.put_line('high_value: ' || l_val1);
END;
/

*/