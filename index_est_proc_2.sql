spool index_est_proc_2
 
set verify off
set serveroutput on size 1000000 format wrapped
 
define  m_owner         = 'PSBPMN'
define m_blocksize = 8192
define  m_target_use    = 90 -- equates to pctfree 10
define  m_scale_factor  = 0.6
define m_minimum = 10000
define m_overhead = 192 -- leaf block "lost" space in index_stats
 
declare
    m_leaf_estimate number;
begin
    for r in (
        select
            table_owner,
            table_name,
            owner       index_owner,
            index_name,
            leaf_blocks
        from
            dba_indexes
        where
            owner = upper('&m_owner')
        and index_type in (
                'NORMAL',
                'NORMAL/REV',
                'FUNCTION-BASED NORMAL'
            )
        and partitioned = 'NO'
        and temporary = 'N'
        and dropped = 'NO'
        and status = 'VALID'
        and last_analyzed is not null
        order by
            owner, table_name, index_name
    ) loop
 
        if r.leaf_blocks > &m_minimum then
            select
                round(
                    100 / &m_target_use *       -- assumed packing efficiency
                    (
                        ind.num_rows * (tab.rowid_length + ind.uniq_ind + 4) +
                        sum(
                            (tc.avg_col_len) *
                            (tab.num_rows)
                        )           -- column data bytes
                    ) / (&m_blocksize - &m_overhead)
                )               index_leaf_estimate
                into    m_leaf_estimate
            from
                (
                select  /*+ no_merge */
                    table_name,
                    num_rows,
                    decode(partitioned,'YES',10,6) rowid_length
                from
                    dba_tables
                where
                    table_name  = r.table_name
                and owner       = r.table_owner
                )               tab,
                (
                select  /*+ no_merge */
                    index_name,
                    index_type,
                    num_rows,
                    decode(uniqueness,'UNIQUE',0,1) uniq_ind
                from
                    dba_indexes
                where
                    table_owner = r.table_owner
                and table_name  = r.table_name
                and owner       = r.index_owner
                and index_name  = r.index_name
                )               ind,
                (
                select  /*+ no_merge */
                    column_name
                from
                    dba_ind_columns
                where
                    table_owner = r.table_owner
                and index_owner = r.index_owner
                and table_name  = r.table_name
                and index_name  = r.index_name
                )               ic,
                (
                select  /*+ no_merge */
                    column_name,
                    avg_col_len
                from
                    dba_tab_cols
                where
                    owner       = r.table_owner
                and table_name  = r.table_name
                )               tc
            where
                tc.column_name = ic.column_name
            group by
                ind.num_rows,
                ind.uniq_ind,
                tab.rowid_length
            ;
 
            if m_leaf_estimate < &m_scale_factor * r.leaf_blocks then
 
                /*dbms_output.put_line(
                    to_char(sysdate,'hh24:mi:ss') || ': ' ||
                    trim(r.table_name) || ' - ' ||
                    trim(r.index_name)
                );
 
                dbms_output.put_line(
                    'Current Leaf blocks: ' ||
                    to_char(r.leaf_blocks,'999,999,999') ||
                    '         Target size: ' ||
                    to_char(m_leaf_estimate,'999,999,999')
                );
 
                dbms_output.new_line;*/
				
                dbms_output.put_line(
                    trim(r.table_name) || '|' || trim(r.index_name) || '|' ||
                    to_char(r.leaf_blocks,'999,999,999') ||
                    '|' ||
                    to_char(m_leaf_estimate,'999,999,999')
                );
				
 
            end if;
        end if;
    end loop;
end;
/
set verify on
 
spool off
 
set doc off