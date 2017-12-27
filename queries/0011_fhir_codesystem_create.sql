/*CREATE OR REPLACE FUNCTION fhir.fhir_codesystem_create(query json)
  RETURNS json AS
$BODY$
begin
return (
select '{"впа":"пепй1"}'
);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE;
*/




-- 1 получить все колонки
/*
with t(j) as (
select '{
 "resourceType": "CodeSystem",
 "publisher":"1",
 "concept":[
     { 	
 	"code":"a",
 	"display":"aa",
 	"property":[
 	{
 	  "code":"a1",
 	  "valueString":"aaa"
 	} ,
 	{
 	  "code":"a2",
 	  "valueString":"aaaa"
 	} 
 	]
     },
     { 	
 	"code":"b",
 	"display":"bb",
 	"property":[
 	{
 	  "code":"b1",
 	  "valueString":"aaa"
 	} ,
 	{
 	  "code":"b2",
 	  "valueString":"aaaa"
 	} 
 	]
     }
  ]
 
}'::json

),

tt as (
 select (j ->> 'concept')::json concept from t
),

ttt as (
 select ((json_array_elements(concept) ->> 'property'))::json properties from tt	
)

select json_array_elements(properties) ->> 'code' from ttt 

*/


with t(j) as (
select '{
 "resourceType": "CodeSystem",
 "version": "v1",
 "publisher":"1",
 "title":"test",
 "concept":[
     { 	
 	"code":"a",
 	"display":"aa",
 	"property":[
 	{
 	  "code":"a1",
 	  "valueString":"aaa"
 	} ,
 	{
 	  "code":"a2",
 	  "valueString":"aaaa"
 	} 
 	]
     },
     { 	
 	"code":"b",
 	"display":"bb",
 	"property":[
 	{
 	  "code":"a1",
 	  "valueString":"aaat54"
 	} ,
 	{
 	  "code":"b1",
 	  "valueString":"aaa"
 	} ,
 	{
 	  "code":"b2",
 	  "valueString":"aaaa1"
 	} 
 	]
     }
  ]
 
}'::json

),

_cols as (
 select 
  json_array_elements(
    (
      json_array_elements(
        (j ->> 'concept')::json
      ) ->> 'property'
    )::json 
  ) ->> 'code' col
 from t
),

cols(col) as ( -- все имена колонок
 values('__code'), ('__display') union all
 select distinct col from _cols
),

new_cols(col, new_col_id) as (
 select col, nextval('cnm.refbook_column_id_seq') new_col_id from cols
),

tt as (
 select 
  json_array_elements((j ->> 'concept')::json) rec, nextval('cnm.record_id_seq') new_rec_id
 from t
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
 select nextval('cnm.refbook_id_seq') new_rb_id, nextval('cnm.refbook_version_id_seq') new_rbv_id, j ->> 'title' full_name, j ->> 'version' "version" from t
),

ins_new_rb as (
 insert into cnm.refbook(id, object_id, source_id, full_name, short_name)
 select new_rb_id, new_rb_id, 1, full_name, full_name from new_rb
 returning *
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
'{
   "resourceType": "OperationOutcome",
   "text":    {
      "status": "generated",
      "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><h1>Operation Outcome<\/h1><table border=\"0\"><tr><td style=\"font-weight: bold;\">INFORMATION<\/td><td>[]<\/td><td><pre>Successfully created resource &quot;CodeSystem/' || refbook_id || '/_history/' || id || '&quot; <\/pre><\/td>\r\n\t\t\t\t\t\r\n\t\t\t\t\r\n\t\t\t<\/tr>\r\n\t\t<\/table>\r\n\t<\/div>"
   },
   "issue": [   {
      "severity": "information",
      "code": "informational",
      "diagnostics": "Successfully created resource \"CodeSystem/' || refbook_id || '/_history/' || id || '
   }]
}
'

from ins_new_rbv r


 -- 407 - пример справочника с пропертями


-- 37325;38045;"" чистить
-- select * from cnm.refbook_version where id = 38046



-- 1. Возврат ресурса
-- 2. добавление source
-- 3. работа через контроллер
-- 4. кириллические имена колонок из description
-- 5. какие-то валидации
-- 6. оптимизация добавления(?)




 