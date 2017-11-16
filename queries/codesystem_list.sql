﻿--select fhir_search::jsonb val from fhir_search('{"resourceType":"CodeSystem","queryString":"_page=2"}');

CREATE OR REPLACE FUNCTION fhir_codesystem_search(query json)
  RETURNS json AS
$BODY$
declare _params text;
        __count integer;
        __page integer;
        _title text;
        _date text;
        __id text;
        _publisher text;
        _status text;
        __sort text;
        r json;
begin 
 _params := urldecode_arr(query ->> 'queryString');
 __count := coalesce(get_value_of_param(_params, '_count'), '3') ::integer;
 __page := coalesce(get_value_of_param(_params, '_page'), '0') ::integer;
 _title := get_value_of_param(_params, 'title');
 __id := get_value_of_param(_params, '_id');
 _date := get_value_of_param(_params, 'date');
 _publisher := get_value_of_param(_params, 'publisher');
 _status := get_value_of_param(_params, 'status');
 __sort := get_value_of_param(_params, '_sort');

execute '

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
 left join mdm_refbook_source rbsc on rbsc.id = rb.source_id
 -- фильтры
 where 
  ($1 is null or upper(rb.full_name) like upper($1) || ''%'') and
  ($2 is null or $2 = rb.id::text) and
  ($3 is null or to_char(rbv.date, ''yyyy-mm-dd'') like $3 || ''%'') and
  ($4 is null or rbsc.name like $4 || ''%'') and
  ($5 is null or $5 = ''unknown'')
),

ready_data as (
 select refbook_id id from data
 -- сортировка, paging 
 limit $6
 offset $7
)

select 
(
 ''{'' ||
 ''"resourceType": "Bundle"'' ||
 '',"type": "searchset"'' ||
 '',"total": '' || (select count(1) from data)::text ||
 '',"entry": ['' || string_agg(fhir_get_codesystem_by_id(id)::text, '', '') || '']''
 ''}'' 
)::json val 
  
from ready_data;
'
into r
using _title, __id, _date, _publisher, _status, __count, __page
;

return r;

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