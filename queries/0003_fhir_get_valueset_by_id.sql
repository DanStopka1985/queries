CREATE OR REPLACE FUNCTION fhir_get_valueset_by_id(cs_id integer)
  RETURNS json AS
$BODY$
begin
return (

with 

last_ver as ( -- Беру последнюю версию справочника
 select 
  rbv.id
 from cnm.refbook_version rbv 
 where rbv.refbook_id::text = (cs_id)::text
 order by rbv.id desc limit 1
),

valid_list as ( -- Есть уникальная колонка, притом только одна. И не более одной отображаемой колонки. -- здесь список из одного элемента
 select 
  lv.id vid
 from last_ver lv 
 join cnm.refbook_column rbc on rbc.refbook_version_id = lv.id
 group by lv.id having sum(case when is_display_name then 1 else 0 end) <= 1 and sum(case when is_unique_key then 1 else 0 end) = 1
)

select 
 concat(
 '{',
 '"resourceType": "ValueSet"', 
 ', "id": ' || to_json(rb.id::text), 
 ', "date": ' || to_json(to_char(rbv.date, 'yyyy-mm-dd')),
 ', "status": "active"',
 ', "version": ' || to_json(rbv.version), 
 ', "title": ' || to_json(coalesce(rb.full_name,'')),
 ', "publisher": ' || to_json(rbsc.name),

 ', "compose": {',
    '"include": [',
      '{',
        '"system": "<base_url>/CodeSystem/' || rb.id || '"',
      '}',
    ']',
  '}',
 '}'  
 )::json val
from valid_list vl
join cnm.refbook_version rbv on rbv.id = vl.vid
join cnm.refbook rb on rb.id = rbv.refbook_id
join cnm.refbook_source rbsc on rbsc.id = rb.source_id

);
end;
$BODY$
  LANGUAGE plpgsql VOLATILE;

