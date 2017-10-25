column lt_type 		heading "TYPE"		format a4
column lt_name		heading "LOCK NAME"	format a30
column lt_id1_tag	heading "ID1 MEANING"	format a25	word_wrap
column lt_id2_tag	heading "ID2 MEANING"	format a25	word_wrap
column lt_us_user	heading "USR"		format a3
column lt_description	heading "DESCRIPTION"	format a60	word_wrap

prompt Show lock type info from V$LOCK_TYPE for lock &1

select
	type 	lt_type,
	name 	lt_name,
	id1_tag	lt_id1_tag,
	id2_tag	lt_id2_tag,
	is_user	lt_is_user,
	description	lt_description
from 
	v$lock_type 
where 
	upper(type) like upper('&1')
/

