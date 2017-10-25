-- Kerry Osborne, 20-Jun-13
-- Based on script by Randolf Geist
-- must be run as user with privilege to create type

create or replace type ntt_varchar2 as table of varchar2(4000);
/

select * from (
select
          sql_id
        , plan_hash_value
        , child_number
        , the_hash
        , case when plan_hash_value = next_plan_hash_value and the_hash != next_the_hash then 'DIFF!' end as are_hashs_diff
from (
  select
            sql_id
          , plan_hash_value
          , child_number
          , the_hash
          , lead(plan_hash_value, 1) over (partition by sql_id, plan_hash_value order by child_number) as next_plan_hash_value
          , lead(the_hash, 1) over (partition by sql_id, plan_hash_value order by child_number) as next_the_hash
  from (
    select
              sql_id
            , plan_hash_value
            , child_number
            , ora_hash(cast(collect(to_char(hash_path_row, 'TM')) as ntt_varchar2)) as the_hash
    from (
      select
                sql_id
              , plan_hash_value
              , child_number
              , hash_path_row
      from (
        select
                  sql_id
                , plan_hash_value
                , child_number
                , id
                , dense_rank() over (order by sql_id, plan_hash_value, child_number) as rnk
                , ora_hash(
                  operation
                  || '-' || ora_hash(access_predicates)
                  || '-' || ora_hash(filter_predicates)
                  ) as hash_path_row
        from (
          select
                  *
          from
                  v$sql_plan 
        )
      )
    )
    group by
              sql_id
            , plan_hash_value
            , child_number
  )
)
) where are_hashs_diff is not null;