set linesize 500
set pages 9999
column relationship format a300


accept owner   prompt 'Enter schema owner    : '
accept rel1    prompt 'Enter start table_name (start: LSW_TASK->% end:%->LSW_TASK middle:%->LSW_TASK->%): '
--accept rel2    prompt 'Enter middle table_name  :'
--accept rel3    prompt 'Enter end table_name     :'

SELECT
       distinct relationship
FROM
       (
              SELECT /*+ parallel(4) */
                      CONNECT_BY_ISLEAF lf, regexp_replace(SYS_CONNECT_BY_PATH(table_name, '->'),'->','',1,1) relationship
              FROM
                     (
                            SELECT DISTINCT
                                   a.table_name AS table_name
                                 , b.table_name AS parent_table_name
                            FROM
                                   dba_constraints a
                            LEFT OUTER JOIN dba_constraints b
                            ON
                                   a.r_constraint_name = b.constraint_name
                               AND a.owner             = b.owner
                            WHERE
                                   a.owner = '&owner'
							  --AND  b.table_name is not null
                     )
                     -- start with parent_table_name is null
                     CONNECT BY nocycle prior table_name=parent_table_name
       )
WHERE
	   relationship LIKE nvl('&rel1','%')
AND    relationship LIKE '%->%'
AND    lf =1
order by 1
;
