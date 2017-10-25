--  ******** Copyright ORACLE Expert Services ***************

-- ==============================================================================
-- This Oracle profile script is used to collect database profile information.
-- It needs to be run as a user who has read privileges on the V$ virtual tables and the DBA_ tables.
-- The script will prompt for the Siebel Schema name and the customer name.
-- 
-- Note that the script version is available from the script name, the output report name and the 
-- heading (in IE) & contents of the output report file. This will make it easier to track the right profile 
-- script that was used to gather information for a specific report. 
--
-- Note that when providing the customers's name, DO NOT USE single/double quotes.
-- Please use alphanumeric (0-9, A-Z, a-z), hyphen and punctuation characters only.
--
-- Whenever you update this script, please document the update history with the following information
-- Date, Version, Change Author and the text/description of the text.
-- ==============================================================================
-- Update History
-- ==============================================================================
-- Pat Sodia (Oracle Expert Service)
-- ==============================================================================

DEFINE SCRIPT_VERSION="v7.0"

SET LINESIZE 175 ;
SET PAGESIZE 5000 ;

--ACCEPT TABLE_OWNER   PROMPT 'Enter Table/Schema Owner Name: '
ACCEPT CUSTOMER_NAME PROMPT 'Enter Customer Name: '
ACCEPT DB_INSTANCE PROMPT 'Enter DB Instance Name: '
ACCEPT REPORT_VERSION PROMPT 'Enter Report Version: '

SPOOL DB_HealthCheck_&CUSTOMER_NAME._&DB_INSTANCE..v&REPORT_VERSION..HTML ;

SET HEADING  OFF
SET FEEDBACK OFF
SET VERIFY   OFF
SET ECHO     OFF

PROMPT <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd"> 

PROMPT <HTML>

PROMPT <HEAD>

PROMPT <TITLE>
SELECT 'Oracle HealthCheck Profile Script Report run for ' || 
       '&&CUSTOMER_NAME'  ||  ' on '  ||  TO_CHAR(SYSDATE, 'MON-DD-YYYY HH24:MM:SS PM') 
  FROM DUAL ;
PROMPT </TITLE>


PROMPT <STYLE type="text/css">

PROMPT  H1    {align: left; color: Black; font-family: Times; font-size: 16pt; background-color: Aqua} 
PROMPT  H2    {align: left; color: Blue;   font-family: Arial;   font-size: 12pt; font-weight: bold; text-decoration: underline;} 
PROMPT  H3    {align: left; color: Red;    font-family: Arial;  font-size: 10pt; font-weight: extra-bold} 
PROMPT  BODY  {font-family: Verdana; font-size: 8pt} 

PROMPT </STYLE>

PROMPT </HEAD>

PROMPT <BODY>

PROMPT <H1 id="TopOfPage">
PROMPT Oracle HealthCheck Profile Report V&REPORT_VERSION for &CUSTOMER_NAME.: Database Instance &DB_INSTANCE</H1>
PROMPT Copyright <A href="http://www.oracle.com">Oracle Expert Services</A>

PROMPT <br><br>
SELECT 'Oracle HealthCheck Profile Script Report (Version &&SCRIPT_VERSION) for <B><I><U>  ' || 
       '&&CUSTOMER_NAME'  ||  '</U></I></B> run on '  || TO_CHAR(SYSDATE, 'MON-DD-YYYY HH24:MM:SS PM') ||
       ' against Database Instance <B><I><U> &&DB_INSTANCE </U></I></B> '
  FROM DUAL ;

PROMPT <OL>
PROMPT <LI> <A href="#Section1">  Basic Database and Instance Information                    </A>
PROMPT <LI> <A href="#Section2">  Redo Log Information                                       </A> 
PROMPT <LI> <A href="#Section3">  Rollback Segment Information                               </A> 
PROMPT <LI> <A href="#Section4">  Tablespace Information                                     </A> 
PROMPT <LI> <A href="#Section5">  Schema, Table and Index Information                        </A> 
PROMPT <LI> <A href="#Section6">  Basic Performance Information                              </A> 
PROMPT <LI> <A href="#Section7">  Oracle Roles, User and Security Information                </A> 
PROMPT </OL>


SET MARKUP HTML ON ENTMAP OFF ;

-- SET VERIFY   ON
SET HEADING  ON
-- SET FEEDBACK ON
SET FEEDBACK OFF
CLEAR BREAKS;
CLEAR COLUMNS;

PROMPT <H1 id="Section1">Basic Database and Instance Information</H1>

PROMPT <OL>
PROMPT <LI> <A href="#Section1.1">  Oracle Software Version Information                    </A>
PROMPT <LI> <A href="#Section1.2">  Global Name                                       </A> 
PROMPT <LI> <A href="#Section1.3">  Database Create Timestamp and Logging                               </A> 
PROMPT <LI> <A href="#Section1.4">  Machine and Instance Startp Information                                     </A> 
PROMPT <LI> <A href="#Section1.5">  Oracle SGA Max Size and Granule Size Information                        </A> 
PROMPT <LI> <A href="#Section1.6">  Oracle SGA Summary Information                              </A> 
PROMPT <LI> <A href="#Section1.7">  Oracle SGA dynamic component sizes, In Bytes                </A> 
PROMPT <LI> <A href="#Section1.8">  Oracle Control File Locations                </A> 
PROMPT <LI> <A href="#Section1.9">  Database Character Set                </A> 
PROMPT <LI> <A href="#Section1.10"> Database Initialization Parameters                </A> 
PROMPT </OL>

PROMPT <P><P> <H2 id="Section1.1"> Oracle Software Version Information </H2><P>

PROMPT <H3> Ensure that the Oracle version is listed in the Supported Platforms Document </H3>
-- PROMPT </P>

SELECT BANNER "ORACLE SOFTWARE VERSION"
FROM   V$VERSION ;

PROMPT <P><P> <H2 id="Section1.2"> Global Name </H2>

COLUMN GLOBAL_NAME FORMAT A100

SELECT GLOBAL_NAME 
FROM   GLOBAL_NAME ;

PROMPT <P><P> <H2 id="Section1.3"> Database Create Timestamp and Logging </H2>

PROMPT <H3> Ensure that Archival Logging is turned on</H3>

COLUMN "DB CREATE TIMESTAMP" FORMAT A30

SELECT DBID DATABASE_ID, 
       NAME "DATABASE NAME", 
       TO_CHAR(CREATED, 'MON-DD-YYYY HH24:MM') "DB CREATE TIMESTAMP", 
       CHECKPOINT_CHANGE#,
       LOG_MODE, 
       (CASE WHEN log_mode = 'NOARCHIVELOG' THEN 'REDFLAG - Archive Logging Not Setup' END) "Error"
FROM   V$DATABASE ;


PROMPT <P><P> <H2 id="Section1.4"> Machine and Instance Startp Information </H2>

COLUMN "HOST NAME" 		FORMAT A10
COLUMN "INSTANCE START TIME" 	FORMAT A20

SELECT HOST_NAME "HOST NAME",
       VERSION,
       INSTANCE_NAME "INSTANCE NAME",
       TO_CHAR(STARTUP_TIME, 'MON-DD-YYYY HH24:MM') "INSTANCE START TIME", 
       STATUS,
       DATABASE_STATUS "DATABASE STATUS"
FROM   V$INSTANCE ;


PROMPT <P><P> <H2 id="Section1.5"> Oracle SGA Max Size and Granule Size Information </H2>

PROMPT <H3> <P><UL><LI>SGA MAX SIZE - Maximum size of the SGA for the life of the instance </LI>
PROMPT <LI>GRANULE SIZE - Contiguous VM allocation and is based on SGA_MAX_SIZE </LI>
PROMPT <LI>SGA/Granule - (<128 MB - 4MB), (>128MB - 16MB), W2K - 8MB </LI></UL></P> </H3>

COLUMN "SGA MAX SIZE" FORMAT 999,999,999,999.99
COLUMN "GRANULE SIZE" FORMAT 999,999,999
COLUMN "GRANULE" FORMAT 999,999,999.99

SELECT to_number(A.VALUE)/(1024*1024*1024) "SGA MAX SIZE"
      ,B.GRANULE_SIZE "GRANULE SIZE"
      ,to_number(A.VALUE)/B.GRANULE_SIZE "GRANUAL"
  FROM (SELECT VALUE FROM V$PARAMETER WHERE NAME = 'sga_max_size') A,
       (SELECT DISTINCT GRANULE_SIZE FROM V$SGA_DYNAMIC_COMPONENTS) B;

PROMPT <P><P> <H2 id="Section1.6"> Oracle SGA Summary Information </H2>

COLUMN "SGA COMPONENT NAME"   FORMAT A20
COLUMN "SIZE (MB)"                            FORMAT 999,999,999.99

BREAK ON REPORT
COMPUTE SUM LABEL "WHOLE SGA SIZE" OF VALUE "SIZE (MB)" ON REPORT
SELECT NAME "SGA COMPONENT NAME",
       VALUE/(1024*1024*1024) "SIZE (GB)" 
FROM   V$SGA ;

CLEAR BREAKS;
CLEAR COLUMNS;

PROMPT <P><P> <H2 id="Section1.7"> Oracle SGA dynamic component sizes, In Bytes </H2>

COLUMN "COMPONENT"		FORMAT a30
COLUMN "CURRENT SIZE"		FORMAT 9,999,999,999,999
COLUMN "MIN SIZE"			FORMAT 9,999,999,999,999
COLUMN "MAX SIZE"			FORMAT 9,999,999,999,999

SELECT COMPONENT,
       CURRENT_SIZE "CURRENT SIZE", 
       MIN_SIZE "MIN SIZE", 
       MAX_SIZE "MAX SIZE"
FROM   V$SGA_DYNAMIC_COMPONENTS;

PROMPT <P><P> <H2> Oracle SGA Resize Events </H2>
SELECT COUNT(*), component, oper_mode 
  FROM v$sga_resize_ops 
 GROUP BY component, oper_mode;

PROMPT <P><P> <H2 id="Section1.8"> Oracle Control File Locations </H2>

SELECT NAME "CONTROL FILE/PATH" 
FROM   V$CONTROLFILE ;

PROMPT <P><P> <H2 id="Section1.9"> Database Character Set </H2>

PROMPT <H3> Ensure that the character set / code page is supported and check the SORT mode also</H3>
SELECT *
FROM   V$NLS_PARAMETERS ;

/*
PROMPT <P><P><H2>Table: Oracle Initialization Parameters</H2>

COLUMN "INSTANCE PARAMETER"  FORMAT A30 ;
COLUMN "PARAMETER VALUE"     FORMAT A50 ;
COLUMN "REMARKS"	           FORMAT A20 ;

SELECT UPPER(NAME) "INSTANCE PARAMETER",
       VALUE "PARAMETER VALUE"
FROM   V$PARAMETER 
ORDER  BY NAME;

PROMPT <P><P><H2>Table: Oracle Parameters, Including Hidden Parameters</H2>
*/

/*
COLUMN NAME FORMAT A39
COLUMN DESCRIPTION FORMAT A40
COLUMN VAL FORMAT A20
SELECT NAM.KSPPINM NAME, 
       NAM.KSPPDESC DESCRIPTION, 
       VAL.KSPPSTVL VALUE
  FROM X$KSPPI NAM, 
    	 X$KSPPSV VAL 
 WHERE NAM.INDX = VAL.INDX ORDER BY 1 ;
*/

PROMPT <P><P> <H2 id="Section1.10"> Database Initialization Parameters </H2>

COLUMN NAME FORMAT A39
COLUMN DESCRIPTION FORMAT A40
COLUMN VALUE FORMAT A20

SELECT name, VALUE, DESCRIPTION
  FROM v$parameter
 ORDER BY NAME;

PROMPT <A href="#TopOfPage">Back to the Top of Report</A>



PROMPT <H1 id="Section2">Redo Log Information</H1>

PROMPT <OL>
PROMPT <LI> <A href="#Section2.1">  Redo Log Configuration                   </A>
PROMPT <LI> <A href="#Section2.2">  Current Status of Redo Log files                                    </A> 
PROMPT <LI> <A href="#Section2.3">  Frequency of Log Switches last 60 Days                             </A> 
PROMPT </OL>


PROMPT <P><P><H2 id="Section2.1">Redo Log Configuration</H2>

COLUMN MEMBER FORMAT A75

SELECT *
FROM   V$LOGFILE
ORDER  BY GROUP#, MEMBER ;



PROMPT <P><P><H2 id="Section2.2">Current Status of Redo Log files</H2>

PROMPT <H3>Ensure that sufficient nummber of redo logs are available <P> Also frequent log switches may indicate redo log size is smaller for the DML activity or smaller LOG related parameters </H3>

COLUMN "SIZE (MB)"              FORMAT 999,999,999,999.99
COLUMN FIRST_CHANGE_TIMESTAMP   FORMAT A25

SELECT GROUP#, 
       THREAD#, 
       SEQUENCE#, 
       BYTES/(1024*1024) "SIZE (MB)", 
       MEMBERS, 
       ARCHIVED, 
       STATUS, 
       FIRST_CHANGE#, 
       TO_CHAR(FIRST_TIME, 'MON-DD-YYYY HH24:MM') FIRST_CHANGE_TIMESTAMP
FROM   V$LOG 
ORDER BY group#, thread#, sequence#;

PROMPT <P><P><H2 id="Section2.3">Frequency of Log Switches last 60 Days</H2>

SELECT * FROM
(
SELECT * FROM
(
SELECT TO_CHAR(FIRST_TIME, 'MM-DD-YYYY') DAY, 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'00',1,0)),'999') "00", 
	   TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'01',1,0)),'999') "01", 
 	   TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'02',1,0)),'999') "02", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'03',1,0)),'999') "03", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'04',1,0)),'999') "04", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'05',1,0)),'999') "05", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'06',1,0)),'999') "06", 
  	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'07',1,0)),'999') "07", 
	   TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'08',1,0)),'999') "08", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'09',1,0)),'999') "09", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'10',1,0)),'999') "10", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'11',1,0)),'999') "11", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'12',1,0)),'999') "12", 
  	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'13',1,0)),'999') "13", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'14',1,0)),'999') "14", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'15',1,0)),'999') "15", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'16',1,0)),'999') "16", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'17',1,0)),'999') "17", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'18',1,0)),'999') "18", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'19',1,0)),'999') "19", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'20',1,0)),'999') "20", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'21',1,0)),'999') "21", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'22',1,0)),'999') "22", 
   	 TO_CHAR(SUM(DECODE(SUBSTR(TO_CHAR(FIRST_TIME, 'MM-DD-YY HH24:MI:SS'),10,2),'23',1,0)),'999') "23" 
FROM 	 V$LOG_HISTORY 
GROUP  BY TO_CHAR(FIRST_TIME, 'MM-DD-YYYY')
)
ORDER BY to_date(DAY,'MM-DD-YYYY') DESC 
)
WHERE ROWNUM < 61
;

PROMPT <A href="#TopOfPage">Back to the Top of Report</A>

PROMPT <H1 id="Section3">Rollback Segment Information</H1>

PROMPT <OL>
PROMPT <LI> <A href="#Section3.1">  Rollback Segment Configuration            </A>
PROMPT </OL>

PROMPT <P><P><H2 id="Section3.1">Rollback Segment Configuration</H2>

COLUMN "TABLESPACE_NAME" FORMAT A15
COLUMN "SEGMENT_NAME"    FORMAT A12
COLUMN "INIT_EXT (KB)"   FORMAT 999,999,999
COLUMN "NEXT_EXT (KB)"   FORMAT 999,999,999
COLUMN "MIN_EXTENTS"     FORMAT 99
COLUMN "MAX_EXTENTS"     FORMAT 999,999,999
COLUMN STATUS            FORMAT A9

SELECT SEGMENT_NAME,
	 TABLESPACE_NAME,
	INITIAL_EXTENT/1024 "INIT_EXT (KB)",
	NEXT_EXTENT/1024    "NEXT_EXT (KB)",
      MIN_EXTENTS,
	MAX_EXTENTS,
	PCT_INCREASE,
      STATUS
FROM DBA_ROLLBACK_SEGS;


PROMPT <A href="#TopOfPage">Back to the Top of Report</A>

PROMPT <H1 id="Section4">Tablespace Information</H1>
PROMPT <OL>
PROMPT <LI> <A href="#Section4.1"> Tablespace Storage Configuration</A>
PROMPT <LI> <A href="#Section4.2"> Tablespace Space Allocation and Utilization</A> 
--PROMPT <LI> <A href="#Section4.3"> Recommended TableSpace Allocations</A> 
PROMPT <LI> <A href="#Section4.3"> TEMP Space Allocation and Utilization</A> 
PROMPT <LI> <A href="#Section4.4"> Datafile and Tempfile Sizes and Configuration</A> 
PROMPT <LI> <A href="#Section4.5"> I/O Distribution Across Datafiles</A> 
PROMPT </OL>

PROMPT <P><P><H2 id="Section4.1">Tablespace Storage Configuration</H2>

PROMPT <H3> Ensure that temporary tablespace is configured for temporary segments and its extent size matches the SORT_AREA Oracle parameter </H3>

COLUMN "INIT (KB)"                            FORMAT 999,999,999
COLUMN "NEXT (KB)"                            FORMAT 999,999,999
COLUMN "BLOCK SIZE (KB)"                      FORMAT 999,999,999
COLUMN  ALLOCATION_TYPE                       FORMAT A15
COLUMN STATUS                                 FORMAT A10
COLUMN "EXTENT MANAGEMENT"         		        FORMAT A18 HEADING 'EXTENT | MANAGEMENT'
COLUMN "EXTENT ALLOCATION TYPE"               FORMAT A25 HEADING 'EXTENT | ALLOCATION | TYPE'
COLUMN "CONTENT TYPE"                         FORMAT A15 HEADING 'CONTENT | TYPE'
COLUMN "SEGMENT SPACE MANAGEMENT"             FORMAT A15 HEADING 'SEGMENT | SPACE | MANAGEMENT'

SELECT TABLESPACE_NAME "TABLESPACE", 
       STATUS "STATUS",
       BLOCK_SIZE "BLOCK_SIZE",
       INITIAL_EXTENT/1024 "INIT (KB)" , 
       NVL(NEXT_EXTENT, INITIAL_EXTENT)/1024 "NEXT (KB)" , 
       NVL(PCT_INCREASE, 0) "% INCREASE", 
       MIN_EXTENTS "MIN EXTENTS", 
       CASE WHEN MAX_EXTENTS > 2000000000 THEN 'UNLIMITED' 
            ELSE TO_CHAR(MAX_EXTENTS,'999,999,999,999') END "MAX EXTENTS",
       CONTENTS "CONTENT_TYPE", 
       ALLOCATION_TYPE "EXTENT ALLOCATION TYPE",
       LOGGING,
       EXTENT_MANAGEMENT "EXTENT MANAGEMENT", 
       SEGMENT_SPACE_MANAGEMENT "SEGMENT SPACE MANAGEMENT"
FROM   DBA_TABLESPACES 
ORDER  BY TABLESPACE_NAME ;
CLEAR COLUMNS ;

PROMPT <P><P><H2 id="Section4.2">Tablespace Space Allocation and Utilization</H2>
PROMPT <H3> Ensure that all tablespaces have atleast 20% of free space </H3>


/* 
 *--------------------------------------------------------------------------------------------
 *  Commented Out by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
/*
BREAK ON REPORT;
CLEAR COLUMNS
COLUMN TABLESPACE FORMAT A20
COLUMN TOTAL_MB FORMAT 999,999,999,999.99
COLUMN USED_MB FORMAT 999,999,999,999.99
COLUMN FREE_MB FORMAT 999,999,999.99
COLUMN PCT_USED FORMAT 999.99
COMPUTE SUM OF TOTAL_MB ON REPORT
COMPUTE SUM OF USED_MB ON REPORT
COMPUTE SUM OF FREE_MB ON REPORT
BREAK ON REPORT 
SET LINES 200 PAGES 100

SELECT  TOTAL.TS TABLESPACE,
        DECODE(TOTAL.MB,NULL,'OFFLINE',DBAT.STATUS) STATUS,
	  TOTAL.MB TOTAL_MB,
	  NVL(TOTAL.MB - FREE.MB,TOTAL.MB) USED_MB,
	  NVL(FREE.MB,0) FREE_MB,
        DECODE(TOTAL.MB,NULL,0,NVL(ROUND((TOTAL.MB - FREE.MB)/      (TOTAL.MB)*100,2),100)) PCT_USED
FROM
	(SELECT TABLESPACE_NAME TS, SUM(BYTES)/1024/1024 MB 
       FROM DBA_DATA_FILES GROUP BY TABLESPACE_NAME) TOTAL,
	(SELECT TABLESPACE_NAME TS, SUM(BYTES)/1024/1024 MB 
       FROM DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) FREE,
       DBA_TABLESPACES DBAT
WHERE TOTAL.TS=FREE.TS(+) AND
      TOTAL.TS=DBAT.TABLESPACE_NAME
UNION ALL
SELECT  SH.TABLESPACE_NAME, 
        'TEMP',
	 SUM(SH.BYTES_USED+SH.BYTES_FREE)/1024/1024 TOTAL_MB,
	 SUM(SH.BYTES_USED)/1024/1024 USED_MB,
	 SUM(SH.BYTES_FREE)/1024/1024 FREE_MB,
        ROUND(SUM(SH.BYTES_USED)/SUM(SH.BYTES_USED+SH.BYTES_FREE)* 100,2) PCT_USED
FROM V$TEMP_SPACE_HEADER SH
GROUP BY TABLESPACE_NAME
ORDER BY 1;
*/

/* 
 *--------------------------------------------------------------------------------------------
 *  Replace above with following by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 

/* 
BREAK ON REPORT;
CLEAR COLUMNS
COLUMN TABLESPACE FORMAT A20
COLUMN TOTAL_GB FORMAT 999,999,999,999.99
COLUMN USED_GB FORMAT 999,999,999,999.99
COLUMN FREE_GB FORMAT 999,999,999.99
COLUMN PCT_FREE FORMAT 999.99
COMPUTE SUM OF TOTAL_GB ON REPORT
COMPUTE SUM OF USED_GB ON REPORT
COMPUTE SUM OF FREE_GB ON REPORT
BREAK ON REPORT 
SET LINES 200 PAGES 100

SELECT tablespace_name      "TABLESPACE"
      ,tot_alloc_bytes_in_G "TOTAL_GB"
      ,tot_used_bytes_in_G  "USED_GB"
      ,tot_avail_bytes_in_G "FREE_GB"
      ,percent_free         "PCT_FREE"
 FROM
(
SELECT  tablespace_name
       ,SUM(tot_alloc_bytes_in_G) tot_alloc_bytes_in_G
       ,SUM(tot_used_bytes_in_G) tot_used_bytes_in_G
       ,SUM(tot_avail_bytes_in_G) tot_avail_bytes_in_G
       ,trunc((SUM(tot_avail_bytes_in_G)/SUM(tot_alloc_bytes_in_G))*100,2) percent_free
FROM
(
SELECT a.tablespace_name
      ,a.file_name
      ,a.tot_alloc_bytes_in_G
      ,(a.tot_alloc_bytes_in_G - b.tot_free_bytes_in_G) tot_used_bytes_in_G
      ,b.tot_free_bytes_in_G                            tot_avail_bytes_in_G
      ,trunc(((b.tot_free_bytes_in_M)/a.tot_alloc_bytes_in_M)*100,2) Percent_free
  FROM  (SELECT SUM(blocks)                  tot_alloc_blocks
               ,SUM(bytes)/(1024*1024)       tot_alloc_bytes_in_M
               ,SUM(bytes)/(1024*1024*1024)  tot_alloc_bytes_in_G
               ,tablespace_name
               ,file_name
               ,file_id
          FROM dba_data_files
         GROUP BY tablespace_name
                  ,file_name
                  ,file_id) a
       ,(SELECT SUM(blocks)                  tot_free_blocks
               ,SUM(bytes)/(1024*1024)       tot_free_bytes_in_M
               ,SUM(bytes)/(1024*1024*1024)  tot_free_bytes_in_G
               ,tablespace_name
               ,file_id
          FROM dba_free_space
         GROUP BY tablespace_name
                 ,file_id) b
 WHERE a.tablespace_name = b.tablespace_name (+)
   AND a.file_id         = b.file_id (+)
)
GROUP BY tablespace_name
)
ORDER BY tablespace_name
;
*/

/* 
 *--------------------------------------------------------------------------------------------
 *  Replace above with following by tsalau 4/4/2011
 *--------------------------------------------------------------------------------------------
*/ 

BREAK ON REPORT;
CLEAR COLUMNS
COLUMN TABLESPACE FORMAT A20
COLUMN TOTAL_GB FORMAT 999,999,999,999.99
COLUMN USED_GB FORMAT 999,999,999,999.99
COLUMN FREE_GB FORMAT 999,999,999.99
COLUMN PCT_FREE FORMAT 999.99
COMPUTE SUM OF TOTAL_GB ON REPORT
COMPUTE SUM OF USED_GB ON REPORT
COMPUTE SUM OF FREE_GB ON REPORT
BREAK ON REPORT 
SET LINES 200 PAGES 100

SELECT tablespace_name      "TABLESPACE"
      ,tot_alloc_bytes_in_G "TOTAL_GB"
      ,tot_used_bytes_in_G  "USED_GB"
      ,tot_avail_bytes_in_G "FREE_GB"
      ,percent_free         "PCT_FREE"
 FROM
(
SELECT  tablespace_name
       ,SUM(tot_alloc_bytes_in_G) tot_alloc_bytes_in_G
       ,SUM(tot_used_bytes_in_G) tot_used_bytes_in_G
       ,SUM(tot_avail_bytes_in_G) tot_avail_bytes_in_G
       ,trunc((SUM(tot_avail_bytes_in_G)/SUM(tot_alloc_bytes_in_G))*100,2) percent_free
FROM
(
SELECT a.tablespace_name
      ,a.tot_alloc_bytes_in_G
      ,(a.tot_alloc_bytes_in_G - b.tot_free_bytes_in_G) tot_used_bytes_in_G
      ,b.tot_free_bytes_in_G                            tot_avail_bytes_in_G
      ,trunc(((b.tot_free_bytes_in_M)/a.tot_alloc_bytes_in_M)*100,2) Percent_free
  FROM  (SELECT SUM(blocks)                  tot_alloc_blocks
               ,SUM(bytes)/(1024*1024)       tot_alloc_bytes_in_M
               ,SUM(bytes)/(1024*1024*1024)  tot_alloc_bytes_in_G
               ,tablespace_name
          FROM dba_data_files
         GROUP BY tablespace_name ) a
       ,(SELECT SUM(blocks)                  tot_free_blocks
               ,SUM(bytes)/(1024*1024)       tot_free_bytes_in_M
               ,SUM(bytes)/(1024*1024*1024)  tot_free_bytes_in_G
               ,tablespace_name
          FROM dba_free_space
         GROUP BY tablespace_name  ) b
 WHERE a.tablespace_name = b.tablespace_name (+)
)
GROUP BY tablespace_name
)
ORDER BY tablespace_name
;

/*
PROMPT <P><P><H2 id="Section4.3">Recommended TableSpace Allocations</H2>
PROMPT <H3>It is recommended that different Tablespaces be created for different Extent Sizes as follows: <P><UL>
PROMPT<LI>Object Size < 4MB use AUTO Space Management </LI>
PROMPT <LI>Object Size 4MB to < 160MB use 4MB Extent Sizes with UNIFORM Space Management</LI>
PROMPT <LI>Object Size >= 160MB use 160MB Extent Sizes with UNIFORM Space Management</LI>
PROMPT </UL></P> </H3>
PROMPT <H3>NOTE: Oracle SYS, SYSTEM and other Internal Schemas have been excluded from the calculations below. </H3>

SELECT 
       object_type
      ,CASE
         WHEN bytes_in_M < 4   THEN
           'AUTO'
         WHEN bytes_in_M >= 4 AND bytes_in_M < 160 THEN
           '4M'
         ELSE
           '160M'
       END  EXTENT_SIZE
      ,SUM(bytes_in_M)/1024 bytes_gb
  FROM 
(
SELECT owner
      ,table_name
      ,index_name
      ,object_type
      ,tablespace_name
      ,SUM(bytes)               total_bytes
      ,SUM(bytes)/(1024*1024)   bytes_in_M
      ,SUM(blocks)              total_blocks
  FROM
(
SELECT b.owner
      ,a.table_name
      ,a.index_name
      ,'INDEX' object_type
      ,b.tablespace_name
      ,b.bytes
      ,b.blocks
  FROM dba_indexes a
      ,dba_segments b
 WHERE a.index_name = b.segment_name
   AND a.owner      = b.owner
   AND a.OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
UNION ALL
SELECT b.owner
      ,a.table_name
      ,NULL
      ,'TABLE' object_type
      ,b.tablespace_name
      ,b.bytes
      ,b.blocks
  FROM dba_tables a
      ,dba_segments b
 WHERE a.table_name = b.segment_name
   AND a.owner      = b.owner
   AND a.OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
)
GROUP BY owner, table_name, index_name, object_type, tablespace_name
ORDER BY owner, object_type DESC, table_name
)
GROUP BY object_type 
        ,CASE
           WHEN bytes_in_M < 4   THEN
             'AUTO'
           WHEN bytes_in_M >= 4 AND bytes_in_M < 160 THEN
             '4M'
           ELSE
             '160M'
         END;
*/

PROMPT <P><P><H2 id="Section4.3">TEMP Space Allocation and Utilization</H2>
PROMPT <H3> Ensure that UNUSED is > 0 </H3>

CLEAR COLUMNS
COLUMN AVAILABLE_TEMP_GB FORMAT 999,999,999,999.99
COLUMN USED_GB FORMAT 999,999,999,999.99
COLUMN UNUSED_GB FORMAT 999,999,999,999.99
COLUMN FREE_GB FORMAT 999,999,999.99
COLUMN PCT_FREE FORMAT 999.99

SELECT t1.tablespace_name
      ,(t1.total_bytes_in_G + t2.unused_temp_in_G) "AVAILABLE_TEMP_GB"
      ,t1.used_bytes_in_G "USED_GB"
      ,t1.free_bytes_in_g "FREE_GB"
      ,t2.unused_temp_in_G "UNUSED_GB"
      ,(((t1.total_bytes_in_G + t2.unused_temp_in_G)-t1.used_bytes_in_G)/(t1.total_bytes_in_G + t2.unused_temp_in_G))*100  "PCT_FREE"
  FROM
(SELECT tablespace_name
      ,SUM((total_blocks*a.block_size)/(1024*1024*1024)) total_bytes_in_G
      ,SUM((used_blocks*a.block_size)/(1024*1024*1024))  used_bytes_in_G
      ,SUM((total_blocks*a.block_size)/(1024*1024*1024)-(used_blocks*32768)/(1024*1024*1024)) free_bytes_in_g
  FROM V$SORT_SEGMENT
      ,(SELECT to_number(value) block_size
          FROM v$parameter
         WHERE NAME = 'db_block_size')  a
 GROUP BY tablespace_name) t1
,
(select tablespace_name
      ,Sum(BYTES_USED + BYTES_FREE)/(1024*1024*1024) total_temp_in_G
      ,Sum(BYTES_USED)/(1024*1024*1024) used_temp_in_G
      ,sum(BYTES_FREE)/(1024*1024*1024) unused_temp_in_G
  from V$TEMP_SPACE_HEADER 
 GROUP BY tablespace_name) t2
WHERE t1.tablespace_name = t2.tablespace_name;


TTITLE OFF
REM CLEAR COLUMNS

CLEAR COLUMNS;
CLEAR BREAKS;
CLEAR COMPUTES;

PROMPT <P><P><H2 id="Section4.4">Datafile and Tempfile Sizes and Configuration</H2>
PROMPT <H3> Ensure that Datafiles are uniformally sized within a tablespace </H3>

BREAK ON TABLESPACE SKIP 1
COLUMN "SIZE (MB)"  FORMAT 999,999,999
COLUMN "BLOCKS"     FORMAT 999,999,999
COLUMN "FILE_NAME"  FORMAT A50
COLUMN "AUTOEXTEND" FORMAT A10

SELECT t1.TABLESPACE_NAME "TABLESPACE", 
       t1.FILE_NAME       "FILE NAME", 
       t1.BYTES/(1024*1024) "SIZE (MB)",
       t1.BLOCKS,
       t1.STATUS,
       t2.BLOCK_SIZE,
       (t1.INCREMENT_BY * t2.block_size) /(1024*1024) "INCREMENT SIZE (MB)",
       t1.AUTOEXTENSIBLE "AUTOEXTEND"
FROM   DBA_DATA_FILES  t1
      ,DBA_TABLESPACES t2
WHERE  t1.tablespace_name = t2.tablespace_name
UNION
SELECT t1.TABLESPACE_NAME "TABLESPACE", 
       t1.FILE_NAME       "FILE NAME", 
       t1.BYTES/(1024*1024) "SIZE (MB)",
       t1.BLOCKS,
       t1.STATUS,
       t2.BLOCK_SIZE,
       (t1.INCREMENT_BY * t2.block_size) /(1024*1024),
       t1.AUTOEXTENSIBLE "AUTOEXTEND"
FROM   DBA_TEMP_FILES  t1
      ,DBA_TABLESPACES t2
WHERE  t1.tablespace_name = t2.tablespace_name
ORDER  BY 1, 3 DESC;
CLEAR COLUMNS ;
CLEAR BREAKS;


PROMPT <P><P><H2 id="Section4.5">I/O Distribution Across Datafiles</H2>
PROMPT <H3> Look for extreme uneven I/O distribution. Also large 'Avg. blocks read per phyrd' may indicate table scans </H3>
PROMPT <H3> In Addition, Avg. Read Times should be less than 10 Millisecs.  Anything greater than that may indicate a I/O Subsystem Problem and Needs to be Looked at. indicate table scans </H3>

BREAK ON TABLESPACE_NAME SKIP 1
COLUMN FILE_NAME                        FORMAT A50
COLUMN "TOTAL IO"				    FORMAT 999,999,999,999
COLUMN PHYRDS                           FORMAT 999,999,999,999
COLUMN PHYWRTS                          FORMAT 999,999,999,999
COLUMN PHYBLKRD                         FORMAT 999,999,999,999
COLUMN READTIM                          FORMAT 999,999,999,999
COLUMN WRITETIM                         FORMAT 999,999,999,999
COLUMN "% OF TOTAL PHYRDS"              FORMAT 999.99
COLUMN "% OF TOTAL PHYWRTS"             FORMAT 999.99
COLUMN "AVG_BLKS_PER_PHYRD"     FORMAT 999.99
COLUMN "AVG_BLKS_PER_PHYWRT"    FORMAT 999.99
COLUMN "AVG_READ_TIME"          FORMAT 9,999.99
COLUMN "AVG_WRITE_TIME"         FORMAT 9,999.99

SELECT TABLESPACE_NAME,
       FILE_NAME, 
	     PHYRDS + PHYWRTS "TOTAL IO",
       PHYRDS,
       PHYWRTS,
       PHYBLKRD,
       PHYBLKRD / DECODE(PHYRDS, 0, 1, PHYRDS) "AVG_BLKS_PER_PHYRD",       
       PHYBLKWRT,
       PHYBLKWRT / DECODE(PHYWRTS, 0, 1, PHYWRTS) "AVG_BLKS_PER_PHYWRT",       
       READTIM,
       WRITETIM,
       Round(READTIM/ DECODE(PHYRDS,0,1, PHYRDS) *10,2) "AVG_READ_TIME",
       Round(WRITETIM/DECODE(PHYWRTS,0,1, PHYWRTS) *10,2) "AVG_WRITE_TIME"
--       Round(READTIM/PHYRDS*10,2) "AVG_READ_TIME",
--       Round(WRITETIM/PHYWRTS*10,2) "AVG_WRITE_TIME"
FROM   V$FILESTAT FS, 
       DBA_DATA_FILES DF
WHERE  FS.FILE# = DF.FILE_ID
ORDER BY TABLESPACE_NAME, "AVG_BLKS_PER_PHYRD" DESC;

CLEAR BREAKS;
CLEAR COLUMNS;

PROMPT <A href="#TopOfPage">Back to the Top of Report</A>


PROMPT <H1 id="Section5">Schema, Table and Index Information</H1>
PROMPT <OL>
PROMPT <LI> <A href="#Section5.1">  Count of Objects by Schema/Owner</A>
PROMPT <LI> <A href="#Section5.2">  Indications of CHAINED ROWS</A> 
PROMPT <LI> <A href="#Section5.21"> Check For Tables with a Large Number of Extents.</A> 
PROMPT <LI> <A href="#Section5.3">  Identifying WIDE tables, with more that 255 COLUMNS.</A> 
PROMPT <LI> <A href="#Section5.4">  Identifying LARGE Objects</A> 
PROMPT <LI> <A href="#Section5.5">  Identifying Objects with PARALLEL DEGREE Set.</A> 
PROMPT <LI> <A href="#Section5.6">  Check of Optimizer Statistics</A> 
PROMPT <LI> <A href="#Section5.61"> Count of Tables With and Without Stats</A> 
PROMPT <LI> <A href="#Section5.62"> Count of Indexes With and Without Stats</A> 
PROMPT <LI> <A href="#Section5.63"> Count of TABLES that have STALE statistics</A> 
PROMPT <LI> <A href="#Section5.64"> Count of EMPTY tables that have statistics</A> 
PROMPT <LI> <A href="#Section5.65"> Check if System/Workload Statistics Have Been Collected for the CBO Optimizer</A> 
PROMPT <LI> <A href="#Section5.7">  Count of triggers by Schemas</A> 
PROMPT <LI> <A href="#Section5.8">  Count of sequences in Schemas</A> 
PROMPT <LI> <A href="#Section5.9">  Index Cardinality</A> 
PROMPT <LI> <A href="#Section5.10"> Indexes on Small Tables</A>
PROMPT <LI> <A href="#Section5.11"> Possible Unused Indexes</A> 
PROMPT </OL>



/* 
 *--------------------------------------------------------------------------------------------
 *  Commented Out by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
/*
CLEAR COLUMNS; 

PROMPT <P><P><H2>Table: Table Count by Schema/Owner and Tablespaces</H2><P>

PROMPT <H3>Watch out for tables and indexes that don't belong to the Siebel application <P> Also ensure that those objects are stored in separate tablespaces</H3>

BREAK ON OWNER SKIP 1
COLUMN NO_OF_TABLES FORMAT 999,999

SELECT OWNER, 
       TABLESPACE_NAME,
       COUNT(1) NO_OF_TABLES
FROM   DBA_TABLES
GROUP  BY OWNER, TABLESPACE_NAME
ORDER  BY OWNER, TABLESPACE_NAME ;   

CLEAR COLUMNS;
CLEAR BREAKS; 


PROMPT <P><P><H2>Table: Index Count by Schema/Owner and Tablespaces</H2>

BREAK ON OWNER SKIP 1
COLUMN NO_OF_INDEXES FORMAT 999,999

SELECT OWNER, 
       TABLESPACE_NAME,
       COUNT(1) NO_OF_INDEXES
FROM   DBA_INDEXES
GROUP  BY OWNER, TABLESPACE_NAME
ORDER  BY OWNER, TABLESPACE_NAME ;
*/

/* 
 *--------------------------------------------------------------------------------------------
 *  Replace above with the following by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 

CLEAR COLUMNS; 

PROMPT <P><P><H2 id="Section5.1">Count of Objects by Schema/Owner</H2>
PROMPT <H3>Watch out for a large number of objects.  A large number of objects may affect the data dictionary performance</H3>

BREAK ON REPORT 
COLUMN OBJECT_COUNT FORMAT 999,999
COLUMN OWNER FORMAT A30
COMPUTE SUM OF OBJECT_COUNT ON REPORT
BREAK ON REPORT 
SELECT owner
      ,object_cnt "OBJECT_COUNT"
  FROM
(
SELECT owner
      ,COUNT(*) object_cnt
  FROM dba_objects
 GROUP BY owner
)
ORDER BY object_cnt DESC
;


PROMPT <P><P><H2 id="Section5.2">Indications of CHAINED ROWS</H2>
--PROMPT <H3>Tables should NOT have more than a few CHAINED ROWS.</H3>
--PROMPT <H3>Caution: The results of this information is only valid if Table Statistics are up to date.</H3>

--Select name, value from v$sysstat view WHERE NAME LIKE 'table fetch by rowid%'; 

COLUMN VALUE FORMAT 999,999,999,999

SELECT DECODE(CLASS,
   		 1, '(User)',
   		 2, '(Redo)',
   		 4, '(Enqueue)',
   		 8, '(Cache)',
   		 16, '(OS)',
   		 32, '(Real Application Clusters)',
   		 64, '(SQL)',
   		 128, '(Debug)'
       ) CLASS,
       NAME, 
       VALUE
FROM   V$SYSSTAT 
where name in ('table fetch by rowid', 'table fetch continued row') 
  and class = 64
ORDER  BY CLASS ASC;



/*
CLEAR COLUMNS;
CLEAR BREAKS; 
COLUMN CHAIN_COUNT FORMAT 999,999,999
COLUMN AVG_ROW_LEN FORMAT 999,999,999
COLUMN OBJECT_COUNT FORMAT 999,999,999


SELECT OWNER
      ,COUNT(*) OBJECT_COUNT
  FROM DBA_TABLES
 WHERE CHAIN_CNT > 1
 GROUP BY owner
 ORDER BY owner;

SELECT OWNER
      ,TABLE_NAME
      ,NUM_ROWS
      ,CHAIN_CNT   "CHAIN_COUNT"
      ,AVG_ROW_LEN "AVG_ROW_LEN"
  FROM DBA_TABLES
 WHERE CHAIN_CNT > 1
 ORDER BY CHAIN_CNT DESC;
*/

PROMPT <P><P><H2 id="Section5.21">Check For Tables with a Large Number of Extents.</H2>

COL segment_name FOR 	a25
COL segment_type FOR 	a12
COL tablespace_name FOR a15

SELECT owner, COUNT(*) OBJECT_COUNT
FROM
(
SELECT owner, segment_name,segment_type,tablespace_name,extents
FROM   dba_segments
WHERE  extents > 10000
)
GROUP BY owner
ORDER BY owner;

SELECT owner, segment_name,segment_type,tablespace_name,extents
FROM   dba_segments
WHERE  extents > 10000
order  by extents desc;


CLEAR COLUMNS
PROMPT <P><P><H2 id="Section5.3">Identifying WIDE tables, with more that 255 COLUMNS.</H2>
PROMPT <H3>Consider rebuilding wide tables with over 255 columns and moving the columns with NULLs to the end.</H3>

CLEAR COLUMNS;
CLEAR BREAKS; 
COLUMN COLUMN_COUNT FORMAT 999,999
COLUMN OBJECT_COUNT FORMAT 999,999

SELECT owner
      ,COUNT(*)  OBJECT_COUNT
  FROM 
(
SELECT COUNT(*) column_count
      ,owner
      ,table_name 
  FROM dba_tab_columns 
 GROUP BY owner
         ,table_name
)
WHERE column_count > 255
GROUP BY owner
ORDER BY owner
;

SELECT owner
      ,table_name 
      ,column_count "COLUMN_COUNT"
  FROM 
(
SELECT COUNT(*) column_count
      ,owner
      ,table_name 
  FROM dba_tab_columns 
 GROUP BY owner
         ,table_name
)
WHERE column_count > 255
ORDER BY column_count DESC
;

PROMPT <P><P><H2 id="Section5.4">Identifying LARGE Objects</H2>
--PROMPT <H3>Understand what LARGE Objects Exist</H3>
PROMPT <H3>LARGE Objects May benefit from PARTITIONing and/or PARALLEL Query</H3>
PROMPT <L1>  For objects > 500MB and < 5GB Consider DOP 4 </L1>
PROMPT <L1>  For objects > > 5GB Consider DOP 8 up to 32 </L1>
PROMPT <L1>  DOP should be set as a POWER of 2 and should not exceed 2*CPUs </L1>
PROMPT <L1>  DOP should not be set on INDEXes unless they are PARTITIONed </L1>
PROMPT <L1>  DOP should not be set on INDEXes unless they are PARTITIONed </L1>
PROMPT <L1>   </L1>


/* 
 *--------------------------------------------------------------------------------------------
 *  Commented Out by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
/*
COLUMN NO_OF_RECORDS FORMAT 999,999,999

SELECT OWNER
       TABLE_NAME,
       NUM_ROWS NO_OF_RECORDS
FROM   DBA_TABLES
WHERE  NUM_ROWS > 500000
ORDER  BY NO_OF_RECORDS DESC, OWNER, TABLE_NAME ;  
*/

/* 
 *--------------------------------------------------------------------------------------------
 *  Replaced above with the following by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
COLUMN TOTAL_BYTES_MB FORMAT 999,999,999
COLUMN TOTAL_BYTES_GB FORMAT 999,999,999
COLUMN OBJECT_COUNT FORMAT 999,999,999
COLUMN TABLE_SIZE FORMAT 999,999,999

SELECT owner
  ,CASE WHEN bytes_in_G >= .5 and bytes_in_G < 5 THEN '500MB - 5GB' ELSE '5GB or Larger' END Table_Size
      ,COUNT(*) OBJECT_COUNT
  FROM
(
SELECT owner
      ,table_name
      ,index_name
      ,object_type
      ,tablespace_name
      ,SUM(bytes)/(1024*1024)       bytes_in_M
      ,SUM(bytes)/(1024*1024*1024)  bytes_in_G
  FROM
(
SELECT b.owner
      ,a.table_name
      ,a.index_name
      ,'INDEX' object_type
      ,b.tablespace_name
      ,b.EXTENTS
      ,b.next_extent
      ,b.bytes
      ,b.blocks
  FROM dba_indexes a
      ,dba_segments b
 WHERE a.index_name = b.segment_name
   AND a.owner      = b.owner
UNION ALL
SELECT b.owner
      ,a.table_name
      ,NULL
      ,'TABLE' object_type
      ,b.tablespace_name
      ,b.EXTENTS
      ,b.next_extent
      ,b.bytes
      ,b.blocks
  FROM dba_tables a
      ,dba_segments b
 WHERE a.table_name = b.segment_name
   AND a.owner      = b.owner
)
GROUP BY owner, table_name, index_name, object_type, tablespace_name
)
WHERE bytes_in_M > 512
GROUP BY owner
      ,CASE WHEN bytes_in_G >= .5 and bytes_in_G < 5 THEN '500MB - 5GB' ELSE '5GB or Larger' END
ORDER BY 2 DESC
;

/*
SELECT owner
      ,table_name
      ,index_name
      ,object_type
      ,tablespace_name
      ,bytes_in_M "TOTAL BYTES MB"
      ,bytes_in_G "TOTAL BYTES GB"
  FROM
(
SELECT owner
      ,table_name
      ,index_name
      ,object_type
      ,tablespace_name
      ,SUM(bytes)/(1024*1024)       bytes_in_M
      ,SUM(bytes)/(1024*1024*1024)  bytes_in_G
  FROM
(
SELECT b.owner
      ,a.table_name
      ,a.index_name
      ,'INDEX' object_type
      ,b.tablespace_name
      ,b.EXTENTS
      ,b.next_extent
      ,b.bytes
      ,b.blocks
  FROM dba_indexes a
      ,dba_segments b
 WHERE a.index_name = b.segment_name
   AND a.owner      = b.owner
UNION ALL
SELECT b.owner
      ,a.table_name
      ,NULL
      ,'TABLE' object_type
      ,b.tablespace_name
      ,b.EXTENTS
      ,b.next_extent
      ,b.bytes
      ,b.blocks
  FROM dba_tables a
      ,dba_segments b
 WHERE a.table_name = b.segment_name
   AND a.owner      = b.owner
)
GROUP BY owner, table_name, index_name, object_type, tablespace_name
)
WHERE bytes_in_M > 512
ORDER BY bytes_in_M DESC
;
*/

PROMPT <P><P><H2 id="Section5.5">Identifying Objects with PARALLEL DEGREE Set.</H2></P></P>
PROMPT <H3>Apply the following guidelines on using PARALLEL on objects:  </H2>
PROMPT <P><UL>
PROMPT<LI>Consider using the PARALLEL hint on Queries first.</LI>
PROMPT<LI>Use of the DEFAULT should generally be avoided.</LI>
PROMPT<LI>For objects > 2MB and < 5GB Consider DOP 4 </LI>
PROMPT<LI>For objects > 5GB Consider DOP 8 up to 32 </LI>
PROMPT<LI>DOP should be set as a POWER of 2 and should not exceed 2*CPUs </LI>
PROMPT<LI>DOP should not be set on INDEXes unless they are PARTITIONed </LI>
PROMPT </UL></P>

CLEAR COLUMNS;
CLEAR BREAKS; 

SELECT OWNER 
      ,DEGREE
      ,COUNT(*) COUNT
FROM 
(
SELECT OWNER, TABLE_NAME, INDEX_NAME, TRIM(DEGREE) DEGREE FROM DBA_INDEXES
UNION ALL 
SELECT OWNER, TABLE_NAME, NULL, TRIM(DEGREE) DEGREE FROM DBA_TABLES
)
WHERE DEGREE != '1' AND DEGREE != '0'
GROUP BY owner, DEGREE
ORDER BY owner, DEGREE
;

/*
COLUMN OWNER FORMAT A20
COLUMN TABLE_NAME FORMAT A30
COLUMN INDEX_NAME FORMAT A30
COLUMN DEGREE FORMAT 999

SELECT OWNER 
      ,TABLE_NAME
      ,INDEX_NAME
      ,DEGREE
FROM 
(
SELECT OWNER, TABLE_NAME, INDEX_NAME, TRIM(DEGREE) DEGREE FROM DBA_INDEXES
UNION ALL 
SELECT OWNER, TABLE_NAME, NULL, TRIM(DEGREE) DEGREE FROM DBA_TABLES
)
WHERE DEGREE != '1' AND DEGREE != '0'
;
*/


PROMPT <P><P><H2>Table: Identifying PARALLEL operation DOWNGRADES.</H2><P>
PROMPT <H3>Parallel DOWNGRADES are an indicator of over use of Parallel Query.  NOTE:  This may not be accurate on 9i dbs</H3>

select name, value from v$sysstat where name like 'Parallel%';


PROMPT <H3></H3>
PROMPT <P><P><H2 id="Section5.6">Check of Optimizer Statistics</H2>
PROMPT <H3>It is vital for system health that stats are up to date.</H3>
/*
col tabname    format a20
col indname    format a18
col colname    format a15
col colexp     format a18
col conname    format a15
col srccond    format a30
col density    format 99999.99999999
*/
--PROMPT <H3>Tables</H3>
/*
select --+ rule
       owner, table_name tabname, to_char(last_analyzed,'MM-DD-YYYY HH24:MI:SS') last_analyzed,
       num_rows, blocks, avg_row_len, sample_size
from all_tables WHERE owner NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS')
order by owner, table_name;
*/

--PROMPT <H3>Histograms</H3>
/*
select 
       owner, table_name tabname, column_name, to_char(last_analyzed,'MM-DD-YYYY HH24:MI:SS') last_analyzed, 
       num_distinct, num_nulls, density, num_buckets
from dba_tab_columns
WHERE OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 
                          'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
  and num_buckets > 0
order by owner, table_name, column_name ;
*/
--PROMPT <H3>Indexes</H3>
/*
select --+ rule 
       a.owner, a.table_name tabname, a.index_name indname, 
       to_char(last_analyzed,'MM-DD-YYYY HH24:MI:SS') last_analyzed,
       a.leaf_blocks lfblk, a.distinct_keys dkeys, 
       a.avg_leaf_blocks_per_key alvlblk, a.avg_data_blocks_per_key avgdblk, a.clustering_factor cf, a.blevel
from all_indexes a
HERE owner NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS')
order by a.owner, a.table_name, a.index_name;
*/

PROMPT <P><P><H2 id="Section5.61">Count of Tables With and Without Stats</H2>

--PROMPT <H3>Count of Tables With and Without Stats</H3>

COLUMN NO_TABLES_WITHOUT_STATS FORMAT 999,999
COLUMN NO_TABLES_WITH_STATS    FORMAT 999,999

SELECT T2.OWNER, NO_TABLES_WITHOUT_STATS, NO_TABLES_WITH_STATS 
  FROM
(SELECT  OWNER
        ,COUNT(1) NO_TABLES_WITHOUT_STATS
   FROM   DBA_TABLES
  WHERE  LAST_ANALYZED IS NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
  GROUP  BY OWNER) T1
,(SELECT  OWNER
         ,COUNT(1) NO_TABLES_WITH_STATS
    FROM  DBA_TABLES
   WHERE  LAST_ANALYZED IS NOT NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
   GROUP  BY OWNER) T2
WHERE T1.OWNER (+) = T2.OWNER
UNION
SELECT T1.OWNER, NO_TABLES_WITHOUT_STATS, NO_TABLES_WITH_STATS 
  FROM
(SELECT  OWNER
        ,COUNT(1) NO_TABLES_WITHOUT_STATS
   FROM   DBA_TABLES
  WHERE  LAST_ANALYZED IS NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
  GROUP  BY OWNER) T1
,(SELECT  OWNER
         ,COUNT(1) NO_TABLES_WITH_STATS
    FROM  DBA_TABLES
   WHERE  LAST_ANALYZED IS NOT NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
   GROUP  BY OWNER) T2
WHERE T1.OWNER = T2.OWNER (+)
ORDER  BY OWNER;

PROMPT <P><P><H2 id="Section5.62">Count of Indexes With and Without Stats</H2>
--PROMPT <H3>Count of Indexes With and Without Stats</H3>

COLUMN NO_INDEXES_WITHOUT_STATS FORMAT 999,999
COLUMN NO_INDEXES_WITH_STATS    FORMAT 999,999

SELECT T2.OWNER, NO_INDEXES_WITHOUT_STATS, NO_INDEXES_WITH_STATS 
  FROM
(SELECT  OWNER
        ,COUNT(1) NO_INDEXES_WITHOUT_STATS
   FROM   DBA_INDEXES
  WHERE  LAST_ANALYZED IS NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
  GROUP  BY OWNER) T1
,(SELECT  OWNER
         ,COUNT(1) NO_INDEXES_WITH_STATS
    FROM  DBA_INDEXES
   WHERE  LAST_ANALYZED IS NOT NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
   GROUP  BY OWNER) T2
WHERE T1.OWNER (+) = T2.OWNER
UNION
SELECT T1.OWNER, NO_INDEXES_WITHOUT_STATS, NO_INDEXES_WITH_STATS 
  FROM
(SELECT  OWNER
        ,COUNT(1) NO_INDEXES_WITHOUT_STATS
   FROM   DBA_INDEXES
  WHERE  LAST_ANALYZED IS NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
  GROUP  BY OWNER) T1
,(SELECT  OWNER
         ,COUNT(1) NO_INDEXES_WITH_STATS
    FROM  DBA_INDEXES
   WHERE  LAST_ANALYZED IS NOT NULL
--    AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
   GROUP  BY OWNER) T2
WHERE T1.OWNER = T2.OWNER (+)
ORDER  BY OWNER;

PROMPT <P><P><H2 id="Section5.63">Count of TABLES that have STALE statistics</H2>
PROMPT <H3>NOTE:  For 9i databases you need to run dbms_stats.gather_schema_stats with the LIST STALE option </H3>

COLUMN NO_TALBES_WITH_STALE_STATS    FORMAT 999,999

SELECT OWNER
      ,COUNT(1) NO_TALBES_WITH_STALE_STATS 
  FROM DBA_TAB_STATISTICS 
 WHERE STALE_STATS = 'YES' 
   and table_name not like 'BIN%'
 GROUP BY OWNER 
 ORDER BY OWNER;

PROMPT <P><P><H2 id="Section5.64">Count of EMPTY tables that have statistics</H2>
PROMPT <H3>Reports of poor performance with stats on EMPTY TABLES. </H3>

COLUMN EMPTY_TABLES_WITH_STATS FORMAT 999,999

SELECT OWNER, 
       COUNT(1) EMPTY_TABLES_WITH_STATS
FROM   DBA_TABLES
WHERE  LAST_ANALYZED IS NOT NULL AND NUM_ROWS = 0
GROUP  BY OWNER
ORDER  BY OWNER;

CLEAR COLUMNS;
CLEAR BREAKS; 

PROMPT <P><P><H2 id="Section5.65">Check if System/Workload Statistics Have Been Collected for the CBO Optimizer</H2>

PROMPT <H3>Results must show values other than null for CPUSPEED, MREADTIM, SREADTIM etc. See Note 149560.1 </H3>
--PROMPT <H3>NOTE:  For 9i Systems if not data displayed, then System/Workload Statistics Have NOT Been Collected  </H3>

PROMPT <L1>where </L1>
PROMPT <L1>=> sreadtim : wait time to read single block, in milliseconds </L1>
PROMPT <L1>=> mreadtim : wait time to read a multiblock, in milliseconds </L1>
PROMPT <L1>=> cpuspeed : cycles per second, in millions </L1>

select * from sys.aux_stats$;

PROMPT <P><P><H2 id="Section5.7">Count of triggers by Schemas</H2>
PROMPT <P><P><H2>Table: Count of triggers by Schemas </H2>

COLUMN NO_OF_TRIGGERS FORMAT 999,999

SELECT TABLE_OWNER, 
--       TABLE_NAME, 
       COUNT(1) NO_OF_TRIGGERS
FROM   DBA_TRIGGERS
WHERE TABLE_OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
GROUP  BY TABLE_OWNER;
--      ,TABLE_NAME ;

PROMPT <P><P><H2 id="Section5.8">Count of sequences in Schemas</H2>
PROMPT <H3>Be aware of sequences with a small CACHE_SIZE </H3>

COLUMN SEQUENCE_OWNER FORMAT a15
COLUMN SEQUENCE_NAME FORMAT a25
COLUMN INCR FORMAT 999
COLUMN CYCLE FORMAT A5
COLUMN ORDER FORMAT A5

SELECT SEQUENCE_OWNER,
 	 SEQUENCE_NAME,
 	 MIN_VALUE,
 	 MAX_VALUE,
 	 INCREMENT_BY INCR,
 	 CYCLE_FLAG CYCLE,
 	 ORDER_FLAG "ORDER",
 	 CACHE_SIZE,
 	 LAST_NUMBER
  FROM DBA_SEQUENCES
WHERE SEQUENCE_OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
ORDER BY SEQUENCE_OWNER
;

/*

PROMPT <P><P><H2>Table: List of Schema tables that have custom attributes that can potentially affect performance</H2><P>

PROMPT <H3>Check for tables and indexes that have custom attribute/storage parameters that are non-standard </H3>

COLUMN "INITIAL_EXTENT (KB)"   FORMAT 999,999,999
COLUMN "NEXT_EXTENT (KB)"      FORMAT 999,999,999

SELECT TABLE_NAME,
       TABLESPACE_NAME,
       INITIAL_EXTENT/1024 "INITIAL_EXTENT (KB)", 
       NEXT_EXTENT/1024    "NEXT_EXTENT (KB)",
       CASE WHEN BUFFER_POOL         = 'DEFAULT'  THEN '** OK **' ELSE '** ' || RTRIM(BUFFER_POOL)         || ' **' END BUFFER_POOL,
       CASE WHEN CLUSTER_NAME        IS NULL      THEN '** OK **' ELSE '** ' || RTRIM(CLUSTER_NAME)        || ' **' END CLUSTER_NAME,
       CASE WHEN IOT_NAME            IS NULL      THEN '** OK **' ELSE '** ' || RTRIM(IOT_NAME)            || ' **' END IOT_NAME,
       CASE WHEN INI_TRANS           =  1         THEN '** OK **' ELSE '** ' || INI_TRANS                  || ' **' END INI_TRANS,
       CASE WHEN FREELISTS           IS NULL OR FREELISTS = 1	    THEN '** OK **' ELSE '** ' || FREELISTS                  || ' **' END FREELISTS,
       CASE WHEN FREELIST_GROUPS     IS NULL OR FREELIST_GROUPS = 1     THEN '** OK **' ELSE '** ' || FREELIST_GROUPS            || ' **' END FREELIST_GROUPS,
       CASE WHEN LOGGING             =  'YES'     THEN '** OK **' ELSE '** ' || RTRIM(LOGGING)             || ' **' END LOGGING,
       CASE WHEN TRIM(DEGREE)        =  '1'       THEN '** OK **' ELSE '** ' || DEGREE                     || ' **' END DEGREE,
       CASE WHEN LTRIM(RTRIM(CACHE)) =  'N'       THEN '** OK **' ELSE '** ' || RTRIM(CACHE)               || ' **' END CACHE,
       CASE WHEN LAST_ANALYZED       IS NOT NULL  THEN '** OK **' ELSE '** NOT ANALYZED **'                         END LAST_ANALYZED,
       CASE WHEN PARTITIONED         =  'NO'      THEN '** OK **' ELSE '** ' || RTRIM(PARTITIONED)         || ' **' END PARTITIONED,
       CASE WHEN IOT_TYPE            IS NULL      THEN '** OK **' ELSE '** ' || RTRIM(IOT_TYPE)            || ' **' END IOT_TYPE,
       CASE WHEN USER_STATS          = 'NO'       THEN '** OK **' ELSE '** ' || RTRIM(USER_STATS)          || ' **' END USER_STATS,
       CASE WHEN MONITORING          = 'NO'       THEN '** OK **' ELSE '** ' || RTRIM(MONITORING)          || ' **' END MONITORING
FROM   DBA_TABLES
WHERE   
       (BUFFER_POOL         <> 'DEFAULT'
         OR CLUSTER_NAME    IS NOT NULL
         OR IOT_NAME        IS NOT NULL
         OR INI_TRANS       <> 1
         OR (FREELISTS       <> 1 AND FREELISTS IS NOT NULL)
         OR (FREELIST_GROUPS <> 1 AND FREELIST_GROUPS IS NOT NULL)
         OR LOGGING         <> 'YES'
         OR TRIM(DEGREE)    <> '1'
         OR LTRIM(RTRIM(CACHE))    <> 'N'
         OR LAST_ANALYZED   IS NULL
         OR PARTITIONED     <> 'NO'
         OR IOT_TYPE        IS NOT NULL
         OR USER_STATS      <> 'NO'
--         OR MONITORING      <> 'NO'
       )
ORDER  BY OWNER, TABLE_NAME 
;
*/

/*
PROMPT <P><P><H2>Table: List of Schema indexes that have custom attributes that can potentially affect performance</H2>

SELECT INDEX_NAME,
       TABLE_NAME,
       TABLESPACE_NAME,
       INDEX_TYPE,
       CASE WHEN COMPRESSION     != 'ENABLED' THEN '** OK **' ELSE '** ' || COMPRESSION            || ' **' END COMPRESSION,
       CASE WHEN BUFFER_POOL     =  'DEFAULT' THEN '** OK **' ELSE '** ' || RTRIM(BUFFER_POOL)     || ' **' END BUFFER_POOL,
       CASE WHEN INI_TRANS       =  2         THEN '** OK **' ELSE '** ' || INI_TRANS              || ' **' END INI_TRANS,
       CASE WHEN FREELISTS           IS NULL OR FREELISTS = 1	    THEN '** OK **' ELSE '** ' || FREELISTS                  || ' **' END FREELISTS,
       CASE WHEN FREELIST_GROUPS     IS NULL OR FREELIST_GROUPS = 1     THEN '** OK **' ELSE '** ' || FREELIST_GROUPS            || ' **' END FREELIST_GROUPS,
--       CASE WHEN FREELISTS       IS NULL	    THEN '** OK **' ELSE '** ' || FREELISTS              || ' **' END FREELISTS,
--       CASE WHEN FREELIST_GROUPS IS NULL	    THEN '** OK **' ELSE '** ' || FREELIST_GROUPS        || ' **' END FREELIST_GROUPS,
       CASE WHEN TRIM(LOGGING)   =  'YES'     THEN '** '||TRIM(LOGGING)||' **' ELSE '** ' || TRIM(LOGGING)         || ' **' END LOGGING,
       CASE WHEN TRIM(DEGREE)    =  '1'       THEN '** OK **' ELSE '** ' || DEGREE                 || ' **' END DEGREE,
       CASE WHEN LAST_ANALYZED   IS NOT NULL  THEN '** OK **' ELSE '** NOT ANALYZED **'                     END LAST_ANALYZED,
       CASE WHEN PARTITIONED     =  'NO'      THEN '** OK **' ELSE '** ' || RTRIM(PARTITIONED)     || ' **' END PARTITIONED
FROM   DBA_INDEXES
WHERE  INDEX_TYPE != 'LOB'
  AND 
       (    COMPRESSION      = 'ENABLED'
         OR BUFFER_POOL      <> 'DEFAULT'
         OR INI_TRANS        <> 2
         OR (FREELISTS       <> 1 AND FREELISTS IS NOT NULL)
         OR (FREELIST_GROUPS <> 1 AND FREELIST_GROUPS IS NOT NULL)
--         OR FREELISTS       <> 1
--         OR FREELIST_GROUPS <> 1
--         OR TRIM(LOGGING)    !=  'YES'
         OR TRIM(DEGREE)     <> '1'
         OR LAST_ANALYZED    IS NULL
         OR PARTITIONED      <> 'NO'      
        )
ORDER  BY OWNER, INDEX_NAME
;
*/

PROMPT <P><P><H2 id="Section5.9">Index Cardinality</H2>
PROMPT <P><P><H2>Table: Count of Normal (B-Tree) indexes that have Low Cardinality Indexed Column(s) (Low Number of Distinct Values)</H2>

COLUMN table_owner FORMAT a25
COLUMN SEQUENCE_NAME FORMAT a25
COLUMN distinct_keys FORMAT 9,999,999,999
COLUMN TABLE_ROW_COUNT FORMAT 99,999,999,999
COLUMN INDEX COUNT FORMAT 99,999,999,999
COLUMN UNIQUE_INDEX_KEY_RATIO FORMAT A22

SELECT table_owner, count(*) "INDEX COUNT"
FROM
(
select table_owner, i.table_name, index_name, i.distinct_keys, 
t.num_rows AS TABLE_ROW_COUNT,
TO_CHAR(ROUND(i.distinct_keys/t.num_rows*100,2),'999,999.99') || '%' AS UNIQUE_INDEX_KEY_RATIO
from dba_indexes i, dba_tables t 
where table_owner not in ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','OLAPSYS','SYSMAN')
and index_type = 'NORMAL' and t.owner = i.table_owner and t.table_name = i.table_name
and uniqueness <> 'UNIQUE' 
and t.num_rows > 1000
and (distinct_keys/t.num_rows) < .1
)
GROUP BY table_owner;

/*
select table_owner, i.table_name, index_name, i.distinct_keys, 
t.num_rows AS TABLE_ROW_COUNT,
TO_CHAR(ROUND(i.distinct_keys/t.num_rows*100,2),'999,999.99') || '%' AS UNIQUE_INDEX_KEY_RATIO
from dba_indexes i, dba_tables t 
where table_owner not in ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','OLAPSYS','SYSMAN')
and index_type = 'NORMAL' and t.owner = i.table_owner and t.table_name = i.table_name
and uniqueness <> 'UNIQUE' 
and t.num_rows > 1000
and (distinct_keys/t.num_rows) < .1
order by table_owner, i.table_name, i.index_name;
*/


PROMPT <P><P><H2>Table: Count of Bitmap indexes that have High Cardinality Indexed Column(s)</H2>

SELECT table_owner, count(*) "INDEX COUNT"
FROM
(
select table_owner, i.table_name, index_name, i.distinct_keys, 
t.num_rows AS TABLE_ROW_COUNT,
TO_CHAR(ROUND(i.distinct_keys/t.num_rows*100,2),'999.99') || '%' AS UNIQUE_INDEX_KEY_RATIO
from dba_indexes i, dba_tables t 
where table_owner not in ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','OLAPSYS','SYSMAN')
and index_type = 'BITMAP'
and t.owner = i.table_owner and t.table_name = i.table_name
and t.num_rows > 0
and i.distinct_keys/t.num_rows > .30
)
GROUP BY table_owner;

/*
select table_owner, i.table_name, index_name, i.distinct_keys, 
t.num_rows AS TABLE_ROW_COUNT,
TO_CHAR(ROUND(i.distinct_keys/t.num_rows*100,2),'999.99') || '%' AS UNIQUE_INDEX_KEY_RATIO
from dba_indexes i, dba_tables t 
where table_owner not in ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','OLAPSYS','SYSMAN')
and index_type = 'BITMAP'
and t.owner = i.table_owner and t.table_name = i.table_name
and t.num_rows > 0
and i.distinct_keys/t.num_rows > .30
order by table_owner, i.table_name, i.index_name;
*/

PROMPT <P><P><H2 id="Section5.10">Indexes On Small Tables</H2>
PROMPT <P><P><H2>Table: Count of indexes On Small Tables (Probably Not Needed)</H2>

SELECT table_owner, count(*) "INDEX COUNT"
FROM
(
select table_owner, t.table_name, index_name, distinct_keys, 
t.num_rows AS TABLE_ROW_COUNT
from dba_indexes i, dba_tables t where t.num_rows < 1000
and t.owner not in ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','OLAPSYS','SYSMAN','CTXSYS','EXFSYS')
and t.owner = i.table_owner and t.table_name = i.table_name
)
GROUP BY table_owner;

/*
select table_owner, t.table_name, index_name, distinct_keys, 
t.num_rows AS TABLE_ROW_COUNT
from dba_indexes i, dba_tables t where t.num_rows < 1000
and t.owner not in ('SYS','SYSTEM','OUTLN','DBSNMP','WMSYS','OLAPSYS','SYSMAN','CTXSYS','EXFSYS')
and t.owner = i.table_owner and t.table_name = i.table_name
order by 1,2,3;
*/


PROMPT <P><P><H2 id="Section5.11">Possible Unused Indexes</H2>
PROMPT <P><P><H2>Table: Count of indexes That Have Not Been Recently Used (May Not Be Needed)</H2>

BREAK ON TABLE_OWNER NODUP ON TABLE_NAME NODUP ON INDEX_NAME NODUP
COLUMN COLUMN_NAME FORMAT A35
COLUMN INDEX_NAME FORMAT A35
COLUMN TABLE_OWNER FORMAT A15

SELECT table_owner, count(*) "INDEX COUNT"
FROM
(
select i.table_owner, i.table_name, i.index_name, column_name 
from dba_indexes i, dba_ind_columns c
where i.table_owner not in ('SYS','SYSTEM','PERFSTAT','DIP','DBSNMP') 
and  i.table_owner not like '%SYS%'
and i.uniqueness <> 'UNIQUE' 
and c.index_owner = i.owner and c.index_name=i.index_name
and not exists (select 1 from dba_hist_sql_plan
where object_type like 'INDEX%' and object_owner = i.owner and object_name = i.index_name)
)
GROUP BY table_owner;

/*
select i.table_owner, i.table_name, i.index_name, column_name 
from dba_indexes i, dba_ind_columns c
where i.table_owner not in ('SYS','SYSTEM','PERFSTAT','DIP','DBSNMP') 
and  i.table_owner not like '%SYS%'
and i.uniqueness <> 'UNIQUE' 
and c.index_owner = i.owner and c.index_name=i.index_name
and not exists (select 1 from dba_hist_sql_plan
where object_type like 'INDEX%' and object_owner = i.owner and object_name = i.index_name)
order by 1,2,3,column_position;
*/

PROMPT <A href="#TopOfPage">Back to the Top of Report</A>


PROMPT <H1 id="Section6">Basic Performance Information</H1>
PROMPT <OL>
PROMPT <LI> <A href="#Section6.1"> Oracle Buffer Pools</A>
PROMPT <LI> <A href="#Section6.2"> Oracle Buffers Current Usage</A>
PROMPT <LI> <A href="#Section6.3"> Oracle Buffers Cache Usage by Owner, Top 20 Consumers</A>
PROMPT <LI> <A href="#Section6.4"> Current SGA Library Summary</A>
PROMPT <LI> <A href="#Section6.5"> Library hit ratio</A>
PROMPT <LI> <A href="#Section6.6"> Data Dictionary hit ratio</A>
PROMPT <LI> <A href="#Section6.7"> BUFFER POOL HIT RATIOs</A>
PROMPT <LI> <A href="#Section6.8"> Buffer Cache Advisory - Default Block Size</A>
PROMPT <LI> <A href="#Section6.9"> Buffer Cache Advisory - Non Default Block Size</A>
PROMPT <LI> <A href="#Section6.10"> PGA Target Advice Histogram</A>
PROMPT <LI> <A href="#Section6.11"> PGA Statistics</A> 
PROMPT <LI> <A href="#Section6.12"> Statistics on workarea executions</A>
--PROMPT <LI> <A href="#Section6.13"> PGA Target Advisory</A>
--PROMPT <LI> <A href="#Section6.14"> Shared Pool Advisory</A> 
--PROMPT <LI> <A href="#Section6.15"> Shared Pool Advisory - from row cache hits</A> 
--PROMPT <LI> <A href="#Section6.16"> SGA Target Advisory</A> 
--PROMPT <LI> <A href="#Section6.17"> Combind SGA Target and PGA Advisory</A> 
PROMPT <LI> <A href="#Section6.18"> Redo Log Space Requests > 0</A> 
PROMPT <LI> <A href="#Section6.19"> Latch Contention</A> 
PROMPT <LI> <A href="#Section6.20"> Contention Statistics from V$WAITSTAT</A> 
PROMPT <LI> <A href="#Section6.21"> Performance Statistics metrics/values from V$SYSSTAT table</A> 
PROMPT <LI> <A href="#Section6.22"> System Events metrics/values from V$SYSTEM_EVENT table</A> 
PROMPT <LI> <A href="#Section6.23"> Statistics metrics/values from V$RESOURCE_LIMIT table</A> 
PROMPT <LI> <A href="#Section6.24"> Top Resource Intensive SQL</A> 
PROMPT </OL>

PROMPT <P><P><H2 id="Section6.1">Oracle Buffer Pools</H2>

/* 
 *--------------------------------------------------------------------------------------------
 *  Commented out by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
--PROMPT <H3>Only for standard block size. Non-standard block sizes use DEFAULT buffer pool</H3>

COLUMN "BUFFER NAME"			FORMAT a20
COLUMN "BLOCK SIZE (BYTES)"		FORMAT 9,999,999,999
COLUMN "CURRENT SIZE(MB)"		FORMAT 9,999,999,999
COLUMN "BUFFERS ALLOCATED"		FORMAT 9,999,999,999

SELECT NAME "BUFFER NAME", 
       BLOCK_SIZE "BLOCK SIZE (BYTES)", 
       CURRENT_SIZE "CURRENT SIZE(MB)", 
       BUFFERS "BUFFERS ALLOCATED"
FROM   V$BUFFER_POOL;


/* 
 *--------------------------------------------------------------------------------------------
 *  Added by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
PROMPT <P><P><H2 id="Section6.2">Oracle Buffers Current Usage</H2>

COLUMN "BUFFER POOL"			FORMAT a20
COLUMN "BLOCK SIZE (BYTES)"		FORMAT 9,999,999,999
COLUMN "CURRENT SIZE(MB)"		FORMAT 9,999,999,999
COLUMN "BLOCKS ALLOCATED"		FORMAT 9,999,999,999

SELECT b.buffer_pool "BUFFER POOL"
      ,c.block_size "BLOCK SIZE (BYTES)"
      ,sum(a.number_of_blocks) "BLOCKS ALLOCATED"
      ,(sum(a.number_of_blocks)*(c.block_size/1024))/1024 "CURRENT SIZE(MB)"
  FROM (SELECT o.object_name 
              ,o.object_type
              ,nvl(o.subobject_name,'x') subobject_name_join
              ,o.subobject_name
              ,o.owner
              ,count(*) number_of_blocks
          FROM dba_objects o
              ,v$bh        bh
         WHERE o.data_object_id = bh.objd
         GROUP BY o.object_name
                 ,nvl(o.subobject_name,'x')
                 ,o.subobject_name
                 ,o.owner
                 ,o.object_type) a
       ,dba_segments             b
       ,(SELECT to_number(value) block_size
           FROM v$parameter
          WHERE NAME = 'db_block_size')  c
 WHERE b.segment_name   = a.object_name
   AND b.owner          = a.owner
   AND b.segment_type   = a.object_type
   AND a.subobject_name_join = nvl(b.partition_name,'x')
 GROUP BY b.buffer_pool, c.block_size
 ORDER BY b.buffer_pool;


 
/* 
 *--------------------------------------------------------------------------------------------
 *  Added by psodia 4/30/2010
 *--------------------------------------------------------------------------------------------
*/ 
PROMPT <P><P><H2 id="Section6.3">Oracle Buffers Cache Usage by Owner, Top 20 Consumers</H2>

COLUMN "OWNER"			FORMAT a30
COLUMN "CURRENT SIZE(MB)"		FORMAT 9,999,999,999
COLUMN "BLOCKS ALLOCATED"		FORMAT 9,999,999,999

SELECT *
FROM
(
SELECT owner "OWNER"
      ,SUM(megabytes) "CURRENT SIZE(MB)"
 FROM 
(
SELECT a.owner
      ,c.block_size
      ,sum(a.number_of_blocks) number_of_blocks
      ,(sum(a.number_of_blocks)*(c.block_size/1024))/(1024) megabytes
  FROM (SELECT o.object_name 
              ,o.object_type
              ,nvl(o.subobject_name,'x') subobject_name_join
              ,o.subobject_name
              ,o.owner
              ,count(*) number_of_blocks
          FROM dba_objects o
              ,v$bh        bh
         WHERE o.data_object_id = bh.objd
         GROUP BY o.object_name
                 ,nvl(o.subobject_name,'x')
                 ,o.subobject_name
                 ,o.owner
                 ,o.object_type) a
       ,dba_segments             b
       ,(SELECT to_number(value) block_size
           FROM v$parameter
          WHERE NAME = 'db_block_size')  c
 WHERE b.segment_name   = a.object_name
   AND b.owner          = a.owner
   AND b.segment_type   = a.object_type
   AND a.subobject_name_join = nvl(b.partition_name,'x')
 GROUP BY a.owner, c.block_size
)
 GROUP BY owner
 ORDER BY SUM(megabytes) DESC
)
WHERE ROWNUM < 21;


PROMPT <P><P><H2 id="Section6.4">Current SGA Library Summary</H2>

COLUMN LIBRARY 		FORMAT A15 HEADING 'LIBRARY|NAME'
COLUMN GETS 		FORMAT 999,999,999,999 
COLUMN GETHITRATIO	FORMAT 990.99 
COLUMN PINS 		FORMAT 999,999,999,999 
COLUMN PINHITRATIO 	FORMAT 990.99 
COLUMN RELOADS 		FORMAT 999,999,999 
COLUMN INVALIDATIONS 	FORMAT 999,999,999 
SELECT INITCAP(NAMESPACE) LIBRARY, 
       GETS , 
       GETHITRATIO, 
       PINS , 
       PINHITRATIO , 
       RELOADS , 
	 INVALIDATIONS 
  FROM V$LIBRARYCACHE 
/ 

--PROMPT <P><P><H2>Table: Current STATSPACK Snapshots in Database</H2>

--select snap_id, to_char(s.snap_time,' dd Mon YYYY HH24:mi:ss') snap_date, snap_level from stats$snapshot s ;

PROMPT <P><P><H2 id="Section6.5">Library hit ratio - should be at least > 0.9, , else increase shared_pool_size - Caution Use Advisory!</H2>

COLUMN LIBRARY_HIT_RATIO      FORMAT 999.99
COLUMN EXECUTIONS             FORMAT 999,999,999,999
COLUMN CACHE_MISSES           FORMAT 999,999,999,999

SELECT SUM(PINS)    EXECUTIONS,
       SUM(RELOADS) CACHE_MISSES,
       (1 - (SUM(RELOADS)/SUM(PINS))) LIBRARY_HIT_RATIO
FROM   V$LIBRARYCACHE ;


PROMPT <P><P><H2 id="Section6.6">Data Dictionary hit ratio - should be > 0.95, else increase shared_pool_size - Caution Use Advisory!</H2>

COLUMN DATA_DICTIONARY_MISSES FORMAT 999,999,999,999,999
COLUMN DATA_DICTIONARY_GETS   FORMAT 999,999,999,999,999
COLUMN DATA_DICT_HIT_RATIO    FORMAT 999.99

SELECT SUM(GETS) DATA_DICTIONARY_GETS,
       SUM(GETMISSES) DATA_DICTIONARY_MISSES,
       (1 - (SUM(GETMISSES)/SUM(GETS))) DATA_DICT_HIT_RATIO
FROM   V$ROWCACHE ;


PROMPT <P><P><H2 id="Section6.7">BUFFER POOL HIT RATIOs</H2>

PROMPT <L1>Default Buffer Pool hit ratio - should be > 0.95, else increase db_cache_size </L1>
PROMPT <L1>Keep Buffer Pool hit ratio - should be > 99%, else increase db_keep_cache_size </L1>
PROMPT <L1>Recycle buffer pool hit ratio - should be > 85%, else increase db_recycle_cache_size  </L1>
PROMPT <L1>For Version 9i and higher USE the BUFFER CACHE Advisory, as the hit ratio alone </L1>
PROMPT <L1>NOTE:  Ratios Cant can be excellent but performance still poor.  You must consider the cost of any physical I/O. </L1>

COLUMN BUFFER_POOL_HIT_RATIO         FORMAT 999.99
COLUMN PHYSICAL_READS                FORMAT 999,999,999,999,999
COLUMN DB_BLOCK_GETS                 FORMAT 999,999,999,999,999
COLUMN CONSISTENT_GETS               FORMAT 999,999,999,999,999
COLUMN KEEP_BUFFER_POOL_HIT_RATIO    FORMAT 999.99
COLUMN RECYCLE_BUFFER_POOL_HIT_RATIO FORMAT 999.99

SELECT NAME,
       PHYSICAL_READS, 
       DB_BLOCK_GETS, 
       CONSISTENT_GETS, 
       (1-(PHYSICAL_READS/(DB_BLOCK_GETS+CONSISTENT_GETS))) BUFFER_POOL_HIT_RATIO
FROM   V$BUFFER_POOL_STATISTICS 
WHERE  DB_BLOCK_GETS+CONSISTENT_GETS != 0 ;
--WHERE  NAME = 'DEFAULT' AND DB_BLOCK_GETS+CONSISTENT_GETS != 0 ;


/*
PROMPT <P><P><H2>Table: Keep Buffer Pool hit ratio - should be > 85%, else increase db_keep_cache_size </H2>

SELECT PHYSICAL_READS, 
       DB_BLOCK_GETS, 
       CONSISTENT_GETS, 
       (1-(PHYSICAL_READS/(DB_BLOCK_GETS+CONSISTENT_GETS))) KEEP_BUFFER_POOL_HIT_RATIO
FROM   V$BUFFER_POOL_STATISTICS 
WHERE  NAME = 'KEEP' AND DB_BLOCK_GETS+CONSISTENT_GETS != 0 ;

PROMPT <P><P><H2>Table: Recycle buffer pool hit ratio - should be > 85%, else increase db_recycle_cache_size  </H2>

SELECT PHYSICAL_READS, 
       DB_BLOCK_GETS, 
       CONSISTENT_GETS, 
       (1-(PHYSICAL_READS/(DB_BLOCK_GETS+CONSISTENT_GETS))) RECYCLE_BUFFER_POOL_HIT_RATIO
FROM   V$BUFFER_POOL_STATISTICS 
WHERE  NAME = 'RECYCLE' AND DB_BLOCK_GETS+CONSISTENT_GETS != 0 ;

*/

PROMPT <P><P><H2 id="Section6.8">Buffer Cache Advisory - Default Block Size - indicates estimated optimal buffer size - Best Buffer Cache Tuning Info</H2>

COLUMN size_for_estimate FORMAT 999,999,999,999 heading 'Cache Size (MB)'
COLUMN buffers_for_estimate FORMAT 999,999,999 heading 'Buffers'
COLUMN estd_physical_read_factor FORMAT 999.90 heading 'Estd Phys|Read Factor'
COLUMN estd_physical_reads FORMAT 999,999,999,999 heading 'Estd Phys| Reads'

SELECT size_for_estimate, buffers_for_estimate, estd_physical_read_factor, estd_physical_reads
FROM V$DB_CACHE_ADVICE
WHERE name = 'DEFAULT'
AND block_size = (SELECT value FROM V$PARAMETER WHERE name = 'db_block_size')
AND advice_status = 'ON';

PROMPT <P><P><H2 id="Section6.9">Buffer Cache Advisory - Non Default Block Size</H2>

COLUMN block_size FORMAT 999,999 heading 'Block Size'

SELECT block_size, size_for_estimate, buffers_for_estimate, estd_physical_read_factor, estd_physical_reads
FROM V$DB_CACHE_ADVICE
WHERE name = 'DEFAULT'
AND block_size <> (SELECT value FROM V$PARAMETER WHERE name = 'db_block_size')
AND advice_status = 'ON';

PROMPT <P><P><H2 id="Section6.10">PGA Target Advice Histogram</H2>

SELECT LOW_OPTIMAL_SIZE/1024 low_kb
      ,(HIGH_OPTIMAL_SIZE+1)/1024 high_kb
      ,OPTIMAL_EXECUTIONS
      ,ONEPASS_EXECUTIONS
      ,MULTIPASSES_EXECUTIONS
      ,round(ONEPASS_EXECUTIONS/(OPTIMAL_EXECUTIONS + ONEPASS_EXECUTIONS + MULTIPASSES_EXECUTIONS)*100, 2) onepass_perc
      ,round(MULTIPASSES_EXECUTIONS/(OPTIMAL_EXECUTIONS + ONEPASS_EXECUTIONS + MULTIPASSES_EXECUTIONS)*100, 2) multipass_perc
  FROM V$SQL_WORKAREA_HISTOGRAM
 WHERE TOTAL_EXECUTIONS != 0;

PROMPT <P><P><H2 id="Section6.11">PGA Statistics</H2>
PROMPT <P><H3>If 'Cache Hit percentage' is low and 'over allocation count' is high, then increase PGA_AGGREGATE_TARGET</H3>
COLUMN VALUE FORMAT 999,999,999,999 heading 'Estd Phys| Reads'

SELECT * FROM V$PGASTAT;

PROMPT <P><P><H2 id="Section6.12">Statistics on workarea executions</H2>

PROMPT <P><H3>This statistics is valid if PGA_AGGREGATE_TARGET parameter is set. If multi-pass is high, lot of disk sorting happens</H3>

SELECT NAME,
	 VALUE
  FROM V$SYSSTAT
 WHERE NAME LIKE 'workarea executions%' ;

/*
PROMPT <P><P><H2 id="Section6.13">PGA Target Advisory - indicates estimated optimal PGA size</H2>

SELECT round(PGA_TARGET_FOR_ESTIMATE/1024/1024) target_mb,
       ESTD_PGA_CACHE_HIT_PERCENTAGE cache_hit_perc,
       ESTD_OVERALLOC_COUNT
  FROM V$PGA_TARGET_ADVICE;


PROMPT <P><P><H2 id="Section6.14">Shared Pool Advisory - indicates estimate of time saved with more shared pool</H2>

SELECT shared_pool_size_for_estimate "Size of Shared Pool in MB",
       shared_pool_size_factor "Size Factor",
       estd_lc_time_saved "Time Saved in sec"
       FROM v$shared_pool_advice;

PROMPT <P><P><H2 id="Section6.15">Shared Pool Advisory - from row cache hits - all pct_succ_gets near 100% highly desirable</H2>

column parameter format a21
column pct_succ_gets format 999.9
column updates format 999,999,999

SELECT parameter
     , sum(gets)
     , sum(getmisses)
     , 100*sum(gets - getmisses) / sum(gets)  pct_succ_gets
     , sum(modifications)                     updates
  FROM V$ROWCACHE
 WHERE gets > 0
 GROUP BY parameter;

PROMPT <P><P><H2 id="Section6.16">SGA Target Advisory</H2>

COLUMN estd_physical_reads FORMAT 999,999,999,999 heading 'Estd Phys| Reads'

SELECT * from V$SGA_TARGET_ADVICE;

PROMPT <P><P><H2 id="Section6.17">Combind SGA Target and PGA Advisory</H2>
PROMPT <H3>This Advisory lists the estimated affect on response times by adjusting the size of the Shared Pool, DB Cache Size and the PGA </H3>
PROMPT <H3>for the current total memory size up to 2 times the current memory size </H3>
*/

/*
================================================================================
*  The following query predicts total response time for various PGA_AGGREGATE_TARGET
*  and SGA_TARGET size combinations.
*
*  Modify the filter values as the bottom to provide a range for TOTAL MEMORY
*  avlailabe for allocation to the SGA and PGA.  
*
*  The results are sorted by response_time, total_size DESC, sga_size, pga_size.
*
*  Use this query to determine the optimal SGA and PGA settings for a specific
*  amount of total available memory.  
*
*  WARNING:  This query is dependant on the current load of the database and is
*            is best run at or near the end of a peak load.
*
*            Also note that the predictions will change as you adjust the SGA
*            and PGA values.
*
*            As such you should run this query following each adjustment the SGA 
*            and PGA size values at the end of a peak load period, re-adjusting 
*            the SGA and PGA until you achieve optimal settings.
*            
================================================================================
*/

/*
--CLEAR
SELECT *
FROM
(
SELECT DISTINCT
       sp.response_time + bc.response_time + pga.response_time total_response_time
      ,sp.estd_sp_size
      ,bc.db_cache_size
      ,sp.estd_sp_size + bc.db_cache_size sga_target_size
      ,pga.target_size pga_aggregate_size
      ,sp.estd_sp_size + bc.db_cache_size + pga.target_size total_size
  FROM (SELECT 'Shared Pool' component
              ,shared_pool_size_for_estimate estd_sp_size
              ,estd_lc_time_saved_factor parse_time_factor
              ,CASE
                 WHEN current_parse_time_elapsed_s + adjustment_s < 0 THEN
                   0
                 ELSE
                   current_parse_time_elapsed_s + adjustment_s
               END response_time
          FROM (SELECT shared_pool_size_for_estimate
                      ,shared_pool_size_factor
                      ,estd_lc_time_saved_factor
                      ,a.estd_lc_time_saved
                      ,e.VALUE / 100 current_parse_time_elapsed_s
                      ,c.estd_lc_time_saved - a.estd_lc_time_saved adjustment_s
                  FROM v$shared_pool_advice a
                      ,(SELECT *
                          FROM v$sysstat
                         WHERE NAME = 'parse time elapsed') e
                      ,(SELECT estd_lc_time_saved
                          FROM v$shared_pool_advice
                         WHERE shared_pool_size_factor = 1) c)) sp 
      ,(SELECT 'DB ' || to_char(block_size / 1024) || 'K CACHE' component
              ,size_for_estimate db_cache_size
              ,estd_physical_read_factor phy_reads_factor
              ,round(estd_physical_reads * timeperio / 100) response_time
          FROM v$db_cache_advice
              ,(SELECT SUM(time_waited) /
                      decode(SUM(total_waits)
                            ,0
                            ,1
                            ,SUM(total_waits)) timeperio
                 FROM v$system_event
                WHERE event LIKE 'db file%read')
              ,(SELECT VALUE blocksize
                 FROM v$parameter
                WHERE NAME = 'db_block_size')
         where name = 'DEFAULT') bc
      ,(SELECT 'PGA Aggregate Target' component
              ,round(pga_target_for_estimate / 1048576) target_size
              ,estd_pga_cache_hit_percentage cache_hit_ratio
              ,round(((estd_extra_bytes_rw /
                     decode((b.blocksize * i.avg_blocks_per_io)
                             ,0
                             ,1
                             ,(b.blocksize * i.avg_blocks_per_io))) *
                     i.iotime) / 100) response_time
          FROM v$pga_target_advice
              ,(SELECT \*+AVG TIME TO DO AN IO TO TEMP TABLESPACE*\
                 AVG((readtim + writetim) /
                     decode((phyrds + phywrts)
                           ,0
                           ,1
                           ,(phyrds + phywrts))) iotime
                ,AVG((phyblkrd + phyblkwrt) /
                     decode((phyrds + phywrts)
                           ,0
                           ,1
                           ,(phyrds + phywrts))) avg_blocks_per_io
                  FROM v$tempstat) i
              ,(SELECT \* temp ts block size *\
                 VALUE blocksize
                  FROM v$parameter
                 WHERE NAME = 'db_block_size') b) pga
 WHERE sp.estd_sp_size + bc.db_cache_size + pga.target_size < (SELECT ((sum(to_number(VALUE)))/(1024*1024))*4 FROM v$parameter WHERE NAME IN ('sga_max_size', 'pga_aggregate_target'))
   AND sp.estd_sp_size + bc.db_cache_size + pga.target_size >= (SELECT (sum(to_number(VALUE)))/(1024*1024) FROM v$parameter WHERE NAME IN ('sga_max_size', 'pga_aggregate_target'))
 ORDER BY 1
         ,6 DESC
         ,4
         ,5
);
*/

/*
PROMPT <P><P><H2>Table: Key Metrics for Rollback Segments</H2><P>

PROMPT <H3>MANUAL MODE: Watch out for shrinks/wraps happening too often which may call for adjustment to the OPTIMAL_SIZE for the rollback segments </H3>

COLUMN "SIZE (KB)"            FORMAT 999,999,999
COLUMN "HIGH WATER MARK (KB)" FORMAT 999,999,999
COLUMN "CURRENT # OF EXTENTS" FORMAT 999,999,999
COLUMN SHRINKS                FORMAT 999,999,999
COLUMN WRAPS                  FORMAT 999,999,999

SELECT RN.NAME          "ROLLBACK SEGMENT",
	 RS.RSSIZE/1024 	"SIZE (KB)",
	 RS.OPTSIZE OPTIMAL_SIZE,
       RS.SHRINKS,
       RS.WRAPS,
	 RS.EXTENDS,
	 RS.HWMSIZE/1024 	"HIGH WATER MARK (KB)",
	 RS.EXTENTS	"CURRENT # OF EXTENTS",
	 RS.AVESHRINK "AVERAGE SHRINK",
	 RS.AVEACTIVE "AVERAGE ACTIVE"
FROM 	V$ROLLNAME RN,
	V$ROLLSTAT RS
WHERE RS.USN = RN.USN;
*/
/*
PROMPT <P><P><H2>Table: Undo Space Usage information</H2><P>
PROMPT <H3> </H3>

COLUMN "TBLSPC USED" 		 	FORMAT 999
COLUMN "BLKS USED"			FORMAT 999,999,999
COLUMN "# OF TXNS"			FORMAT 999,999,999
COLUMN "LONGEST QRY (in secs)"	FORMAT 999,999
COLUMN "CONCURRENT # OF TXNS"		FORMAT 999,999,999
COLUMN "# STEAL UNEXPIRED EXTENTS"	FORMAT 999,999,999
COLUMN "SNAPSHOT TOO OLD"		FORMAT 999

SELECT TO_CHAR(BEGIN_TIME, 'MM-DD-YY HH24:MI:SS') BEGIN_TIME,
       TO_CHAR(END_TIME, 'MM-DD-YY HH24:MI:SS') END_TIME,
       UNDOTSN "TBLSPC USED",
       UNDOBLKS "BLKS USED",
       TXNCOUNT "# OF TXNS",
       MAXQUERYLEN "LONGEST QRY (in secs)",
       MAXCONCURRENCY "CONCURRENT # OF TXNS",
       UNXPSTEALCNT "# STEAL UNEXPIRED EXTENTS",
       SSOLDERRCNT "SNAPSHOT TOO OLD"
  FROM V$UNDOSTAT
 WHERE ROWNUM < 100;
*/


PROMPT <P><P><H2 id="Section6.18">Redo Log Space Requests > 0 - Increase LOG_BUFFER init.ora parameter</H2>

SELECT  SUBSTR(NAME,1,25) NAME, 
        SUBSTR(VALUE,1,15) "VALUE (Near 0?)" 
  FROM  V$SYSSTAT 
 WHERE  NAME = 'redo log space requests'; 

PROMPT <P><P><H2 id="Section6.19">Latch Contention</H2>
PROMPT <P><P><H2>Table: Latch Contention</H2>

PROMPT <H3> Latch Contention, if misses/gets > 1% and/or immediate_misses/(immediate_gets + immediate_misses) > 1% </H3>

COLUMN LATCH_NAME                FORMAT A25
COLUMN MISSES                    FORMAT 999,999,999
COLUMN IMMEDIATE_GETS            FORMAT 999,999,999
COLUMN IMMEDIATE_MISSES          FORMAT 999,999,999

SELECT  SUBSTR(LN.NAME, 1, 20) LATCH_NAME, 
        GETS, 
        MISSES, 
        IMMEDIATE_GETS, 
        IMMEDIATE_MISSES 
  FROM  V$LATCH l, V$LATCHNAME ln 
 WHERE  ln.NAME in ('redo allocation', 'redo copy') 
   and  ln.LATCH# = l.LATCH#; 

PROMPT <P><P><H2 id="Section6.20">Contention Statistics from V$WAITSTAT</H2>

SELECT * 
  FROM V$WAITSTAT
 WHERE COUNT > 0 
 ORDER BY COUNT DESC ;

PROMPT <P><P><H2 id="Section6.21">Performance Statistics metrics/values from V$SYSSTAT table</H2>

COLUMN VALUE FORMAT 999,999,999,999

SELECT DECODE(CLASS,
   		 1, '(User)',
   		 2, '(Redo)',
   		 4, '(Enqueue)',
   		 8, '(Cache)',
   		 16, '(OS)',
   		 32, '(Real Application Clusters)',
   		 64, '(SQL)',
   		 128, '(Debug)'
       ) CLASS,
       NAME, 
       VALUE
FROM   V$SYSSTAT 
ORDER  BY CLASS ASC ;

/*
PROMPT <P><P><H2>Table: Datafile I/O Statistics </H2>

SELECT PHYRDS,
       PHYWRTS,
       PHYBLKRD "BLOCKS READ",
       PHYBLKWRT "BLOCKS WRITTEN",
       READTIM/100 "READ TIME (in secs)",
       WRITETIM/100 "WRITE TIME (in secs)"
  FROM V$FILESTAT
 ORDER BY 1 DESC ;
*/

PROMPT <P><P><H2 id="Section6.22">System Events metrics/values from V$SYSTEM_EVENT table</H2>

COLUMN EVENT         FORMAT A32
COLUMN TOT_SECS_WAIT FORMAT 999,999,999,999
COLUMN AVG_WAIT_SECS FORMAT 999,999,999,999.99

PROMPT <P><P><H2>Table: Time Spent Waiting on Event by Wait Class </H2>
SELECT WAIT_CLASS, 
	 SUM(TIME_WAITED)/100 TOT_SECS_WAIT, 
	 AVG(AVERAGE_WAIT)/100 AVG_WAIT_SECS
FROM 	V$SYSTEM_EVENT 
WHERE WAIT_CLASS <> 'Idle'
GROUP BY WAIT_CLASS
ORDER BY 2 desc ;

PROMPT <P><P><H2>Table: List of System Events Order by Avg Wait Time </H2>
SELECT EVENT, 
	 TOTAL_WAITS, 
	 TOTAL_TIMEOUTS, 
	 TIME_WAITED/100 TOT_SECS_WAIT, 
	 AVERAGE_WAIT/100 AVG_WAIT_SECS
FROM 	V$SYSTEM_EVENT
WHERE WAIT_CLASS <> 'Idle'
ORDER BY TOT_SECS_WAIT DESC;


PROMPT <P><P><H2 id="Section6.23">Statistics metrics/values from V$RESOURCE_LIMIT table</H2>

SELECT *
FROM   V$RESOURCE_LIMIT;

PROMPT <P><P><H2 id="Section6.24">Top Resource Intensive SQL</H2>
PROMPT <P><P><H2>Table: List of Top 30 Most Resource Intensive SQL </H2>
COLUMN SQL_TEXT     FORMAT A40 
COLUMN CPU_TIME_IN_SECS     FORMAT 9,999,999,999
COLUMN ELAPSED_TIME_IN_SECS FORMAT 9,999,999,999
COLUMN IO_WAIT_TIME_IN_SECS FORMAT 9,999,999,999
COLUMN EXECUTIONS    FORMAT 9,999,999,999
COLUMN DISK_READS FORMAT 9,999,999,999
COLUMN DIRECT_WRITES FORMAT 999,999,999
COLUMN BUFFER_GETS FORMAT 9,999,999,999


SELECT * FROM 
(SELECT SQL_TEXT, SQL_ID, EXECUTIONS, 
ROUND(CPU_TIME/1000000) AS CPU_TIME_IN_SECS, 
ROUND(ELAPSED_TIME/1000000) AS ELAPSED_TIME_IN_SECS,
DISK_READS,
DIRECT_WRITES, BUFFER_GETS, 
ROUND(USER_IO_WAIT_TIME/1000000) AS IO_WAIT_TIME_IN_SECS
FROM V$SQL 
ORDER BY CPU_TIME DESC NULLS LAST)
WHERE ROWNUM < 31;

PROMPT <P><P><H2>Table: Buffer Busy Waits in Segment Statistics</H2>

select segment_name
      ,object_type
      ,total_buff_busy_waits
from 
(select owner||'.'||object_name as segment_name
       ,object_type
       ,value as total_buff_busy_waits
   from v$segment_statistics
  where statistic_name in ('buffer busy waits')
 order by total_buff_busy_waits desc)
where rownum <=20 ;

PROMPT <P><P><H2>Table: Read by Other Session Waits in Segment Statistics</H2>

select segment_name
      ,object_type
      ,total_read_other_waits
  from 
(select owner||'.'||object_name as segment_name
      ,object_type
      ,value as total_read_other_waits
from v$segment_statistics
where statistic_name in ('read by other session')
  AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'XDB', 'IX', 'WMSYS', 'CTXSYS', 'OLAPSYS', 'ORDSYS', 'ORDPLUGINS', 'MDSYS', 'OUTLN', 'DBSNMP', 'EXFSYS', 'DMSYS')
order by total_read_other_waits DESC
)
where rownum <=20 ;
*/

PROMPT <A href="#TopOfPage">Back to the Top of Report</A>

PROMPT <H1 id="Section7">Oracle Roles, User and Security Information</H1>

PROMPT <OL>
PROMPT <LI> <A href="#Section7.1"> Roles configured in the database</A> 
PROMPT <LI> <A href="#Section7.2"> Roles other than 'DBA', 'IMP_FULL_DATABASE', 'EXP_FULL_DATABASE', 'AQ_ADMINISTRATOR_ROLE'</A> 
PROMPT <LI> <A href="#Section7.3"> Profiles defined in DBA_PROFILES</A> 
PROMPT <LI> <A href="#Section7.4"> Database user-ids that have been expired/locked out</A> 
PROMPT </OL>

PROMPT <P><P><H2 id="Section7.1">Roles configured in the database</H2>

SELECT ROLE,
       PASSWORD_REQUIRED
FROM   DBA_ROLES ;


PROMPT <P><P><H2 id="Section7.2">Roles other than 'DBA', 'IMP_FULL_DATABASE', 'EXP_FULL_DATABASE', 'AQ_ADMINISTRATOR_ROLE'</H2>

SELECT ROLE NON_BASIC_ROLES,
       PRIVILEGE,
       ADMIN_OPTION
FROM   ROLE_SYS_PRIVS
WHERE ROLE NOT IN ('DBA','IMP_FULL_DATABASE','EXP_FULL_DATABASE','AQ_ADMINISTRATOR_ROLE');


PROMPT <P><P><H2 id="Section7.3">Profiles defined in DBA_PROFILES</H2>

COLUMN RESOURCE_TYPE FORMAT A15

SELECT PROFILE, 
       RESOURCE_TYPE, 
       RESOURCE_NAME, 
       LIMIT
FROM   DBA_PROFILES
ORDER  BY PROFILE, RESOURCE_TYPE ;


PROMPT <P><P><H2 id="Section7.4">Database user-ids that have been expired/locked out</H2>

SELECT SUM(TOTAL_USERS)        TOTAL_USERS,
       SUM(LOCKED_USER_COUNT)  LOCKED_USER_COUNT,
       SUM(EXPIRED_USER_COUNT) EXPIRED_USER_COUNT
FROM  (
        SELECT COUNT(1) TOTAL_USERS, 
               0        LOCKED_USER_COUNT,
               0        EXPIRED_USER_COUNT
        FROM   DBA_USERS
        UNION
        SELECT 0,
               COUNT(1),
               0
        FROM   DBA_USERS
        WHERE  LOCK_DATE IS NOT NULL
        UNION
        SELECT 0,
               0,
               COUNT(1)
        FROM   DBA_USERS
        WHERE  EXPIRY_DATE IS NOT NULL AND
               EXPIRY_DATE <= SYSDATE 
       ) ;


PROMPT <A href="#TopOfPage">Back to the Top of Report</A>
PROMPT </BODY>
PROMPT </HTML>
SET MARKUP HTML OFF ;
SPOOL OFF
