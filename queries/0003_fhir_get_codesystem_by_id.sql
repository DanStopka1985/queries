CREATE OR REPLACE FUNCTION fhir.fhir_get_codesystem_by_id(cs_id integer)
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
),

_columns as ( -- колонки
 select 
  rbc.id,
  rbc.is_unique_key,
  rbc.is_display_name,
  rbc.name  
 from valid_list vl 
 join cnm.refbook_column rbc on rbc.refbook_version_id = vl.vid 
),

_records as ( -- записи
 select 
  id
 from cnm.record rec 
 join valid_list c on c.vid = rec.refbook_version_id
),

data as ( -- данные для concept в виде компонентов json
 select 
  r.id,
  case 
   when is_unique_key then '"code": ' || to_json(rc.value)
   when is_display_name then '"display": ' || to_json(rc.value) 
   else '{"code": ' || to_json(c.name) || ', "valueString": ' || to_json(rc.value) || '}' 
  end f,
  case when is_unique_key or is_display_name then 0 else 1 end l  
 from cnm.record_column rc
 join _records r on rc.record_id = r.id
 join _columns c on rc.column_id = c.id

 order by r.id, case when is_unique_key then 0 when is_display_name then 1 else 2 end
),

gd as ( -- сгруппированные данные (json) (код, отображение и проперти)
 select 
  id, 
  case 
   when l = 0 then string_agg(f, ',')
   when l = 1 then
    '"properties": [' || string_agg(f, ',') || ']' 
  end l
 from data 
 group by id, l order by id, l
),

ggd as ( -- сгруппированные данные (json set по всем записям)(код, отображение и проперти)
 select '{' || string_agg(l, ',') || '}' l from gd group by id
)

select 

 concat(
 '{',
   '"resourceType": "CodeSystem"'
   ', "id": "' || rb.id || '"',
   ', "date": "' || to_char(rbv.date, 'yyyy-mm-dd') || '"',
   ', "status": "unknown"',
   ', "content": "complete"'   
   ', "version": "' || rbv.version || '"', 
   ', "title": "' || coalesce(rb.full_name,'') || '"',
   ', "publisher": "' || rbsc.name || '"',
   ', "count": "' || (select count(1) from ggd) || '"',
   (select ', "concept": [' || string_agg(l, ',') || ']' from ggd),
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

-- example
-- select fhir_get_codesystem_by_id(37116)