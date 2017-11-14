--select fhir_search::jsonb val from fhir_search('{"resourceType":"CodeSystem","queryString":"_page=2"}');


-- fhir_codesystem_search
CREATE OR REPLACE FUNCTION get_value_of_param(params text, key text)
RETURNS text as
$BODY$
begin
return (
 with t as (
  select string_to_array(regexp_split_to_table(params, '&'), '=') a
 )

 select a[2] from t
 where a[1] = key
 limit 1
);
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION fhir_codesystem_search(query json)
  RETURNS json AS
$BODY$
declare __count integer;
declare __page integer;
begin 
 __count := coalesce(get_value_of_param((query ->> 'queryString'), '_count'), '3') ::integer;
 __page := coalesce(get_value_of_param((query ->> 'queryString'), '_page'), '0') ::integer;

return (

with last_ver as ( -- список последних версий
 select 
  rbv.refbook_id, max(rbv.id) id
 from mdm_refbook_version rbv
 group by rbv.refbook_id
),

valid_list as (
 select lv.id from last_ver lv
 join mdm_refbook_column rbc on rbc.refbook_version_id = lv.id
 group by lv.id having sum(case when is_display_name then 1 else 0 end) <= 1 and sum(case when is_unique_key then 1 else 0 end) = 1
),

data as (
 select rbv.id, rbv.refbook_id from valid_list vl
 join mdm_refbook_version rbv on rbv.id = vl.id
 join mdm_refbook rb on rb.id = rbv.refbook_id
 -- фильтры
),

ready_data as (
 select refbook_id id from data
 -- сортировка, paging 
 limit __count
 offset __page
)

select 
(
 '{' ||
 '"resourceType": "Bundle"' ||
 ',"type": "searchset"' ||
 ',"total": ' || (select count(1) from data)::text ||
 ',"entry": [' || string_agg(fhir_get_codesystem_by_id(id)::text, ', ') || ']'
 '}' 
)::json val
  
from ready_data

);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;








CREATE OR REPLACE FUNCTION fhir_search(query json)
  RETURNS json AS
$BODY$
begin
return (
 select 
  case 
   when (query ->> 'resourceType') = 'CodeSystem' then fhir_codesystem_search(query) 
   else '{}'
  end val 
);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


--select coalesce(get_value_of_param('a=2&b=3&c=345', 'd'), '10')