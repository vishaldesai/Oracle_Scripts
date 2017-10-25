column "Diskgroup" heading "Diskgroup Name"
column "Imbalance" heading "Percent|Imbalance"
column "Variance"  heading "Percent|Disk Size|Variance"
column "MinFree"   heading "Minimum|Percent|Free"
column "DiskCnt"   heading "Disk|Count"
column "Type"      heading "Diskgroup|Redundancy"

select
	/* Name of the Diskgroup */ 
	g.name 
	"Diskgroup",
	/* Percent diskgroup allocation is imbalanced */ 
	100*(max((d.total_mb-d.free_mb)/d.total_mb)-min((d.total_mb-d.free_mb)/d.total_mb))/max((d.total_mb-d.free_mb)/d.total_mb) 
	"Imbalance",
	/* Percent different between largest and smallest disk */ 
	100*(max(d.total_mb)-min(d.total_mb))/max(d.total_mb) 
	"Variance",
	/* The disk withe the least free space as a percent of total space */ 
	100*(min(d.free_mb/d.total_mb)) 
	"MinFree",
	/* Number of disks in diskgroup */ 
	count(*) 
	"DiskCnt",
	/* Disk Redundancy */ 
	g.type 
	"Type"
from	v$asm_disk d,
		v$asm_diskgroup g
where	d.group_number=g.group_number
and	d.group_number <>0
and	d.state = 'NORMAL'
and	d.mount_status='CACHED'
group
by	g.name,g.type;

column "Diskgroup" heading "Diskgroup Name"
column "PImbalance" heading "Partner|Count|Imbalance"
column "SImbalance" heading "Partner|Space|Imbalance"
column "Inactive" heading "Inactive|Partnership|Count"
column "FailGrpCnt" heading "Failgroup|Count"

SELECT g.name "Diskgroup",
  MAX(p.cnt)-MIN(p.cnt) "PImbalance",
  100 *(MAX(p.pspace)-MIN(p.pspace))/MAX(p.pspace) "SImbalance",
  COUNT(distinct p.fgrp) "FailGrpCnt",
  SUM(p.inactive)/2 "Inactive"
FROM v$asm_diskgroup g ,
  (SELECT x.grp grp,
    x.disk disk,
    SUM(x.active) cnt,
    greatest(SUM(x.total_mb/a.total_mb),0.0001) pspace,
    a.failgroup fgrp,
    COUNT(*)-SUM(x.active) inactive
  FROM v$asm_disk a ,
    (SELECT v.grp grp,
      v.disk disk,
      z.total_mb*v.active_kfdpartner total_mb,
      v.active_kfdpartner active
    FROM x$kfdpartner v,
      v$asm_disk z
    WHERE v.number_kfdpartner = z.disk_number
    AND v.grp                 = z.group_number
    ) x
  WHERE a.group_number = x.grp
  AND a.disk_number    = x.disk
  AND a.group_number  <> 0
  AND a.state          = 'NORMAL'
  AND a.mount_status   = 'CACHED'
  GROUP BY x.grp,
    x.disk,
    a.failgroup
  ) p
WHERE g.group_number = p.grp
GROUP BY g.name ;



column "Partnerdisk" heading "Partner|Disks" format a30
column "PartnerdiskCell" heading "Partnerdisk|Cell" format a30
set pages 200
SELECT disk,
  cell,
  LISTAGG(NUMBER_KFDPARTNER, ',') WITHIN GROUP (ORDER BY NUMBER_KFDPARTNER) AS "Partnerdisk",
  LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd) AS "PartnerdiskCell",
  CASE
    WHEN instr(LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd),cell ) =0    THEN 'OK'
    WHEN instr(LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd),cell ) >0    THEN 'ERROR'
  END AS status
FROM
  (SELECT disk,
    CASE
      WHEN DISK>= 0 AND DISK <=11 THEN 1
      WHEN DISK>=12 AND DISK <=23 THEN 2
      WHEN DISK>=24 AND DISK <=35 THEN 3
      WHEN DISK>=36 AND DISK <=47 THEN 4
      WHEN DISK>=48 AND DISK <=59 THEN 5
      WHEN DISK>=60 AND DISK <=71 THEN 6
      WHEN DISK>=72 AND DISK <=83 THEN 7
    END AS cell,
    NUMBER_KFDPARTNER,
    CASE
      WHEN NUMBER_KFDPARTNER>= 0 AND NUMBER_KFDPARTNER <=11 THEN 1
      WHEN NUMBER_KFDPARTNER>=12 AND NUMBER_KFDPARTNER <=23 THEN 2
      WHEN NUMBER_KFDPARTNER>=24 AND NUMBER_KFDPARTNER <=35 THEN 3
      WHEN NUMBER_KFDPARTNER>=36 AND NUMBER_KFDPARTNER <=47 THEN 4
      WHEN NUMBER_KFDPARTNER>=48 AND NUMBER_KFDPARTNER <=59 THEN 5
      WHEN NUMBER_KFDPARTNER>=60 AND NUMBER_KFDPARTNER <=71 THEN 6
      WHEN NUMBER_KFDPARTNER>=72 AND NUMBER_KFDPARTNER <=83 THEN 7
    END AS pd
  FROM V$ASM_DISK A,
       X$KFDPARTNER B
  WHERE B.NUMBER_KFDPARTNER = A.DISK_NUMBER
  AND GRP                   =1
  AND name LIKE 'DATA%'
  ORDER BY 1 ASC
  )
GROUP BY disk,cell;

column "Partnerdisk" heading "Partner|Disks" format a30
column "PartnerdiskCell" heading "Partnerdisk|Cell" format a30
set pages 200
select disk, cell, 
LISTAGG(NUMBER_KFDPARTNER, ',') WITHIN GROUP (ORDER BY NUMBER_KFDPARTNER) AS "Partnerdisk",
LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd) AS "PartnerdiskCell",
case when instr(LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd),cell ) =0 then 'OK'
     when instr(LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd),cell ) >0 then 'ERROR' end as status
from (
select disk,
case 	when DISK>= 0 and DISK<=11 then 1
	when DISK>=12 and DISK<=23 then 2
	when DISK>=24 and DISK<=35 then 3
	when DISK>=36 and DISK<=47 then 4
	when DISK>=48 and DISK<=59 then 5
	when DISK>=60 and DISK<=71 then 6
	when DISK>=72 and DISK<=83 then 7
end as cell,
NUMBER_KFDPARTNER,
case 	when NUMBER_KFDPARTNER>= 0 and NUMBER_KFDPARTNER<=11 then 1
	when NUMBER_KFDPARTNER>=12 and NUMBER_KFDPARTNER<=23 then 2
	when NUMBER_KFDPARTNER>=24 and NUMBER_KFDPARTNER<=35 then 3
	when NUMBER_KFDPARTNER>=36 and NUMBER_KFDPARTNER<=47 then 4
	when NUMBER_KFDPARTNER>=48 and NUMBER_KFDPARTNER<=59 then 5
	when NUMBER_KFDPARTNER>=60 and NUMBER_KFDPARTNER<=71 then 6
	when NUMBER_KFDPARTNER>=72 and NUMBER_KFDPARTNER<=83 then 7
end as pd
from V$ASM_DISK A, X$KFDPARTNER B
where B.NUMBER_KFDPARTNER = A.DISK_NUMBER
and GRP=2
and name like 'DBFS%'
order by 1 asc)
group by disk,cell
/

column "Partnerdisk" heading "Partner|Disks" format a30
column "PartnerdiskCell" heading "Partnerdisk|Cell" format a30
set pages 200
select disk, cell, 
LISTAGG(NUMBER_KFDPARTNER, ',') WITHIN GROUP (ORDER BY NUMBER_KFDPARTNER) AS "Partnerdisk",
LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd) AS "PartnerdiskCell",
case when instr(LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd),cell ) =0 then 'OK'
     when instr(LISTAGG(pd, ',') WITHIN GROUP (ORDER BY pd),cell ) >0 then 'ERROR' end as status
from (
select disk,
case 	when DISK>= 0 and DISK<=11 then 1
	when DISK>=12 and DISK<=23 then 2
	when DISK>=24 and DISK<=35 then 3
	when DISK>=36 and DISK<=47 then 4
	when DISK>=48 and DISK<=59 then 5
	when DISK>=60 and DISK<=71 then 6
	when DISK>=72 and DISK<=83 then 7
end as cell,
NUMBER_KFDPARTNER,
case 	when NUMBER_KFDPARTNER>= 0 and NUMBER_KFDPARTNER<=11 then 1
	when NUMBER_KFDPARTNER>=12 and NUMBER_KFDPARTNER<=23 then 2
	when NUMBER_KFDPARTNER>=24 and NUMBER_KFDPARTNER<=35 then 3
	when NUMBER_KFDPARTNER>=36 and NUMBER_KFDPARTNER<=47 then 4
	when NUMBER_KFDPARTNER>=48 and NUMBER_KFDPARTNER<=59 then 5
	when NUMBER_KFDPARTNER>=60 and NUMBER_KFDPARTNER<=71 then 6
	when NUMBER_KFDPARTNER>=72 and NUMBER_KFDPARTNER<=83 then 7
end as pd
from V$ASM_DISK A, X$KFDPARTNER B
where B.NUMBER_KFDPARTNER = A.DISK_NUMBER
and GRP=3
and name like 'RECO%'
order by 1 asc)
group by disk,cell
/

