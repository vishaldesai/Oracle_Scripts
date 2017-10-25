-- loading colors variables:
@inc/colors;
-- set max length of bar:
def _max_length=100;
-- column formatting
col bar format a&_max_length;
-- clear screen:
prompt &_CLS
 
-- test query which prints histogram(or may be simply bars?):
with t as (-- it's just a test values for example:
            select level id
                 , round(sys.dbms_random.value(1,100)) val 
            from dual 
            connect by level<=10
          )
select
       id
      ,val
      , case
           when pct >= 0.9 then '&_C_RED' 
           when pct <= 0.4 then '&_C_GREEN'
           else '&_C_YELLOW'
        end 
        -- string generation:
      ||lpad( chr(192)
             ,ceil(pct * &_max_length)-9 -- color - 5 chars and reset - 4
             ,chr(192)
            )
      ||'&_C_RESET'
       as bar
from (
     select
        t.*
       ,val / max(val)over() as pct -- as a percentage of max value:
     from t
     ) t2
/