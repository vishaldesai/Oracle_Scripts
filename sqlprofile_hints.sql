--10g

select attr_val from sys.sqlprof$ p, sys.sqlprof$attr a
where p.sp_name = 'first_rows' 
and p.signature = a.signature
and p.category = a.category;


--11g

SELECT extractValue(value(h),'.') AS hint
FROM sys.sqlobj$data od, sys.sqlobj$ so,
     table(xmlsequence(extract(xmltype(od.comp_data),'/outline_data/hint'))) h
WHERE so.name = 'first_rows'
AND so.signature = od.signature
AND so.category = od.category
AND so.obj_type = od.obj_type
AND so.plan_id = od.plan_id;