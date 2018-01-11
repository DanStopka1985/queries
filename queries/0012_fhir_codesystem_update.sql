
CREATE OR REPLACE FUNCTION fhir.fhir_codesystem_update(_id text, query json)
  RETURNS json AS
$BODY$

with 
_cols as (
 select 
  json_array_elements(
    (
      json_array_elements(
        (query ->> 'concept')::json
      ) ->> 'property'
    )::json 
  ) ->> 'code' col
),

cols(col) as ( -- все имена колонок
 values('__code'), ('__display') union all
 select distinct col from _cols
),

new_cols(col, new_col_id) as (
 select col, nextval('cnm.refbook_column_id_seq') new_col_id from cols join cnm.refbook rb on rb.id::text = _id
),

tt as (
 select 
  json_array_elements((query ->> 'concept')::json) rec, nextval('cnm.record_id_seq') new_rec_id from cnm.refbook rb where rb.id::text = _id
),

val_set as (
select 
 cols.col,
 tt.new_rec_id,
 cols.new_col_id,
 case 
  when cols.col = '__code' then rec ->> 'code'
  when cols.col = '__display' then rec ->> 'display'
  else 
   (with q as (
     select json_array_elements((rec ->> 'property')::json) v
    )
    select (v ->> 'valueString')::text from q where v ->> 'code' = cols.col 
   )
 end v
  
from new_cols cols
join tt on 
 cols.col = '__code' and (rec ->> 'code') != '' or
 cols.col = '__display' and (rec ->> 'display') != '' or
 cols.col not in ('__code', '__display') and position(cols.col in (rec ->> 'property')) != 0
),

new_rb as (
 select _id::integer new_rb_id, nextval('cnm.refbook_version_id_seq') new_rbv_id, query ->> 'title' full_name, query ->> 'version' "version" from cnm.refbook where id::text = _id::text
),

ins_new_rbv as (
 insert into cnm.refbook_version(id, date, version, refbook_id)
 select new_rbv_id, current_date, version, new_rb_id from new_rb
 returning *
),

ins_new_columns as (
 insert into cnm.refbook_column(id, name, title, refbook_version_id, is_display_name, is_unique_key)
 select new_col_id, col, col, new_rbv_id, col = '__display', col = '__code' from new_cols cols cross join new_rb
 returning *
),

ins_new_records as (
 insert into cnm.record(id, refbook_version_id)
 select new_rec_id, new_rbv_id from tt cross join new_rb
 returning *
),

ins_new_record_column as (
 insert into cnm.record_column(id, record_id, column_id, value)
 select nextval('cnm.record_column_id_seq') new_rc_id, new_rec_id, new_col_id, v from val_set
 returning *
)

select 
('{
   "resourceType": "OperationOutcome",
   "text":    {
      "status": "generated"      
   },
   "issue": [   {
      "severity": "information",
      "code": "informational",
      "diagnostics": "CodeSystem/'  || refbook_id || '/_history/' || id || ' created"' || ' 
      }
      ]
  }'
)::json val

from ins_new_rbv r

$BODY$
  LANGUAGE sql VOLATILE

