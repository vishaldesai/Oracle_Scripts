--------------------------------------------------------------------------------
-- File name:   exasnap_install.sql (Exadata Snapper install) BETA
--
-- Purpose:     Install required objects for the Exadata Snapper
--
-- Author:      Tanel Poder ( http://blog.tanelpoder.com | tanel@tanelpoder.com )
--
-- Copyright:   (c) 2012 All Rights Reserved
-- 
-- Usage:       1) Make sure that you have SELECT ANY DICTIONARY privileges
--                 or direct SELECT grants on the V$ views referenced in this
--                 script
--
--              2) Run @exasnap_install.sql to create the objects
--
--              3) Use the EXASNAP.BEGIN_SNAP procedure/function to take snapshots
--                 of running sessions performance data
--
--              Look into exasnap.sql for more usage info.
--
-- Other:       This is still a pretty raw script in development and will
--              probably change a lot once it reaches v1.0.
--   
--              Exadata Snapper doesn't currently purge old data from its repository
--              so if you use this version heavily, you may want to truncate the
--              ex_ tables manually (should reporting get slow). I'll add the 
--              purging feature in the future.
--              
--------------------------------------------------------------------------------

COL snap_name FOR A20
COL snap_time FOR A30
COL snap_type FOR A10
COL taken_by  FOR A10
COL comm      FOR A100

DROP TABLE ex_snapshot;
DROP TABLE ex_session;
DROP TABLE ex_sesstat;
DROP SEQUENCE ex_snap_seq;
DROP PACKAGE exasnap;
DROP TYPE exastat_result_t;
DROP TYPE exastat_result_r;

CREATE SEQUENCE ex_snap_seq ORDER NOCACHE;

CREATE TABLE ex_snapshot (
    snap_id   NUMBER    NOT NULL
  , snap_time TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
  , snap_name VARCHAR2(100) NOT NULL
  , snap_type VARCHAR2(100) NOT NULL
  , taken_by  VARCHAR2(100) DEFAULT user NOT NULL
  , comm      VARCHAR2(4000)
)
/

ALTER TABLE ex_snapshot ADD CONSTRAINT ex_snapshot_pk PRIMARY KEY (snap_id);

CREATE TABLE ex_session (
    snap_id                                  NUMBER         NOT NULL
  , snap_time                                TIMESTAMP      NOT NULL
  , inst_id                                  NUMBER         NOT NULL
  , sid                                      NUMBER         NOT NULL
  , serial#                                  NUMBER         NOT NULL
  , qc_inst                                  NUMBER
  , qc_sid                                   NUMBER
  , qc_serial#                               NUMBER
  , username                                 VARCHAR2(100)
  , sql_id                                   VARCHAR2(100)
  , dfo_tree                                 NUMBER
  , server_set                               NUMBER
  , server#                                  NUMBER
  , actual_degree                            NUMBER
  , requested_degree                         NUMBER
  , server_name                              VARCHAR2(100)
  , spid                                     VARCHAR2(100)
)
/

ALTER TABLE ex_session ADD CONSTRAINT ex_session_pk PRIMARY KEY (snap_id, inst_id, sid, serial#);


CREATE TABLE ex_sesstat (
    snap_id   NUMBER    NOT NULL
  , snap_time TIMESTAMP NOT NULL
  , inst_id   NUMBER    NOT NULL
  , sid       NUMBER    NOT NULL
  , serial#   NUMBER    NOT NULL
  , stat_name VARCHAR2(100) NOT NULL
  , value     NUMBER    NOT NULL
)
/

ALTER TABLE ex_sesstat ADD CONSTRAINT ex_sesstat_pk PRIMARY KEY (snap_id, inst_id, sid, serial#, stat_name);

CREATE OR REPLACE TYPE exastat_result_r AS OBJECT (name VARCHAR2(200));
/

CREATE OR REPLACE TYPE exastat_result_t AS TABLE OF exastat_result_r;
/


CREATE OR REPLACE PACKAGE exasnap AS
    FUNCTION begin_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user) RETURN NUMBER;
    FUNCTION end_snap  (p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user) RETURN NUMBER;
    FUNCTION take_snap (p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user, p_snap_type IN VARCHAR2 DEFAULT 'SNAP') RETURN NUMBER;

    PROCEDURE begin_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user);
    PROCEDURE end_snap  (p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user); 
    PROCEDURE take_snap (p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user, p_snap_type IN VARCHAR2 DEFAULT 'SNAP'); 

    FUNCTION display_snap(begin_snap IN NUMBER DEFAULT NULL, end_snap IN NUMBER DEFAULT NULL, detail IN VARCHAR2 DEFAULT '%' ) RETURN exastat_result_t PIPELINED;

END exasnap;
/

CREATE OR REPLACE PACKAGE BODY exasnap AS

    FUNCTION begin_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user) RETURN NUMBER IS
    BEGIN
        RETURN take_snap(p_sid, p_name, 'BEGIN');
    END begin_snap;

    FUNCTION end_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user) RETURN NUMBER IS
    BEGIN
        RETURN take_snap(p_sid, p_name, 'END');
    END end_snap;

    FUNCTION take_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user, p_snap_type IN VARCHAR2 DEFAULT 'SNAP') 
      RETURN NUMBER IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        seq        NUMBER;
        ts         TIMESTAMP := SYSTIMESTAMP;
        lv_sid     NUMBER := TO_NUMBER(REGEXP_SUBSTR(p_sid, '^\d+'));
        lv_inst_id NUMBER := NVL(REPLACE(REGEXP_SUBSTR(p_sid, '@\d+'), '@', ''),SYS_CONTEXT('USERENV','INSTANCE'));
    BEGIN
        SELECT ex_snap_seq.NEXTVAL INTO seq FROM dual;
 
        INSERT INTO ex_snapshot VALUES (seq, ts, p_name, p_snap_type, user, NULL);

        INSERT INTO ex_session
        SELECT
            seq
          , ts
          , pxs.inst_id         
          , pxs.sid             
          , pxs.serial#         
          , pxs.qcinst_id       qc_inst
          , pxs.qcsid           qc_sid
          , pxs.qcserial#       qc_serial#
          , s.username          username
          , s.sql_id
          , pxs.server_group    dfo_tree
          , pxs.server_set
          , pxs.server#
          , pxs.degree          actual_degree
          , pxs.req_degree      requested_degree
          , p.server_name
          , p.spid
        FROM
            gv$px_session pxs
          , gv$session    s
          , gv$px_process p
        WHERE
            pxs.qcsid = lv_sid
        AND pxs.qcinst_id = lv_inst_id
        --AND s.sid     = pxs.qcsid
        AND s.sid     = pxs.sid
        AND s.serial# = pxs.serial#
        --AND s.serial# = pxs.qcserial# -- null
        AND p.sid     = pxs.sid
        AND pxs.inst_id = s.inst_id
        AND s.inst_id = p.inst_id
        UNION ALL
        SELECT
            seq
          , ts
          , s.inst_id         
          , s.sid              
          , s.serial#
          , null -- qcinst
          , null -- qcsid
          , null -- qcserial
          , s.username
          , s.sql_id
          , null -- dfo_tree (server_group)
          , null -- server_set
          , null -- server#
          , null -- degree
          , null -- req_degree
          , s.program -- server_name
          , p.spid
        FROM
            gv$session s
          , gv$process p
        WHERE
            s.inst_id = p.inst_id
        AND s.paddr = p.addr
        AND s.sid = lv_sid
        AND s.inst_id = lv_inst_id;

        INSERT INTO ex_sesstat
        SELECT
            seq
          , ts
          , ss.inst_id
          , ss.sid
          , s.serial# 
          , sn.name stat_name
          , ss.value
        FROM
            gv$sesstat ss
          , gv$statname sn
          , gv$session s
        WHERE
            ss.inst_id = s.inst_id
        AND ss.inst_id = sn.inst_id
        AND s.inst_id = sn.inst_id
        AND s.sid = ss.sid
        AND sn.statistic# = ss.statistic#
        AND (s.inst_id, s.sid, s.serial#) IN (SELECT inst_id, sid, serial# FROM ex_session WHERE snap_id = seq)
        AND (ss.inst_id, ss.sid) IN (SELECT inst_id, sid FROM ex_session WHERE snap_id = seq);

        IF p_snap_type IN ('BEGIN','END') THEN
            NULL;
        ELSE
            NULL;
        END IF;

        COMMIT;

        RETURN seq;
    END take_snap;

    PROCEDURE begin_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user) IS
       tmp_id NUMBER;
    BEGIN
       tmp_id := begin_snap(p_sid);
    END begin_snap;

    PROCEDURE end_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user) IS
       tmp_id NUMBER;
    BEGIN
       tmp_id := end_snap(p_sid);
    END end_snap;

    PROCEDURE take_snap(p_sid IN VARCHAR2 DEFAULT TO_CHAR(SYS_CONTEXT('userenv','sid')), p_name IN VARCHAR2 DEFAULT user, p_snap_type IN VARCHAR2 DEFAULT 'SNAP') IS
       tmp_id NUMBER;
    BEGIN
       tmp_id := take_snap(p_sid, p_name, 'SNAP');
    END take_snap;

    FUNCTION display_snap(begin_snap IN NUMBER DEFAULT NULL, end_snap IN NUMBER DEFAULT NULL, detail IN VARCHAR2 DEFAULT '%' ) RETURN exastat_result_t PIPELINED IS
    BEGIN
        NULL;
    END display_snap;

END exasnap;
/

SHOW ERR;

