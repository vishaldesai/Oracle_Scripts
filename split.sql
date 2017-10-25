set verify off
define TNAME=DOCVERSION
define CHUNKS=64

select grp,
       dbms_rowid.rowid_create( 1, data_object_id, lo_fno, lo_block, 0 ) min_rid,
       dbms_rowid.rowid_create( 1, data_object_id, hi_fno, hi_block, 10000 ) max_rid,
	   'insert /*+ APPEND */ into stg_icmp_reqs.DOCVERSION@hmmdei1 select /*+ ROWID (dda) */ OBJECT_ID,OBJECT_CLASS_ID,CREATE_DATE,U3D48_ORGNT_REQ_ID,UD958_RCV_FAX_NUM,U4E93_RCV_DTTM,UE968_SND_FAX_NUM,U0223_SRC_CMMT_DTTM,UBEE8_DOC_CAT_CD,U40B8_DOC_SUBTYPE_CD,UF328_DOC_TYPE_CD,U63C8_UIL,UA095_BLOB_OS_ID,UA175_BLOB_ID,U8C56_BUS_PTNR_NUM,UFF58_PROC_SRC_CD,UAC78_COMMITTAL_BUS_LINE_NM,U0B08_DEL_IND,U4318_DOC_REC_IND,UA778_EMP_ACCT_IND,UAE28_NT_STAT_CD,U9B88_EXTRL_DOC_REF_ID,U64A8_FNL_IND,UE338_IMG_CAPT_STAT_CD,U4858_IMG_CAPT_VLD_IND,U0178_INTRNL_IND,U3095_LFT_DAT_DOC_ID,U6D85_LFT_DAT_OS_ID,U1CF8_LN_FL_IND,U10D6_DOC_GEN_DOC_SEQ,UB738_ORIG_IND,U8138_ORIG_SRC_RPSTR_NM,UDB88_PKG_NM,U0A56_PG_NUM,UF448_PROC_FCLTY_ID,UF358_RELT_DOC_ID,U3C58_SIG_IND,U8E88_TAX_YR_NUM,U1958_EXTRL_REQ_REF_ID,U2E26_INV_CASE_NUM,UFFC6_INV_ORG_CD,U4D78_IMG_REF_ID,UC828_EXTRL_WORKFLOW_IND,UFD16_TOT_PG_CNT from ICMPOSSIT1.DOCVERSION dda WHERE rowid BETWEEN ' || '''' || 
	   dbms_rowid.rowid_create( 1, data_object_id, lo_fno, lo_block,1) || '''' || ' and ' || '''' ||  
	   dbms_rowid.rowid_create( 1, data_object_id, hi_fno, hi_block ,10000)
	   ) || '''' || ';' as cmd
  from (
select distinct grp,
       first_value(relative_fno) 
        over (partition by grp order by relative_fno, block_id
              rows between unbounded preceding and unbounded following) lo_fno,
       first_value(block_id    ) 
       over (partition by grp order by relative_fno, block_id
              rows between unbounded preceding and unbounded following) lo_block,
       last_value(relative_fno) 
       over (partition by grp order by relative_fno, block_id
              rows between unbounded preceding and unbounded following) hi_fno,
       last_value(block_id+blocks-1) 
       over (partition by grp order by relative_fno, block_id
              rows between unbounded preceding and unbounded following) hi_block,
       sum(blocks) over (partition by grp) sum_blocks
  from (
select relative_fno,
       block_id,
       blocks,
       trunc( (sum(blocks) over (order by relative_fno, block_id)-0.01) / (sum(blocks) over ()/&CHUNKS) ) grp
  from dba_extents
 where segment_name = upper('DOCVERSION') and owner='ICMPOSSIT1'
   order by block_id
       )
       ),
       (select data_object_id from dba_objects where object_name = upper('DOCVERSION') and owner='ICMPOSSIT1')
 order by grp;

undefine TNAME
undefine CHUNKS
set verify on

/*
for i in `ls x*`
do
mv $i $i.sql
done

for i in `ls x*` 
do
nohup sqlplus "/ as sysdba" @"$i" &
done

*/



