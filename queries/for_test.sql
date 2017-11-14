/*__count := coalesce(get_value_of_param(('{"resourceType":"CodeSystem","queryString":"_page=1\u0026_count=10\u0026title=t"}'::json ->> 'queryString'), '_count'), '3') ::integer;
 __page := coalesce(get_value_of_param(('{"resourceType":"CodeSystem","queryString":"_page=1\u0026_count=10\u0026title=t"}'::json ->> 'queryString'), '_page'), '0') ::integer;
 _title := get_value_of_param(('{"resourceType":"CodeSystem","queryString":"_page=1\u0026_count=10\u0026title=t"}'::json ->> 'queryString'), 'title');
*/
--'{"resourceType":"CodeSystem","queryString":"_page=1\u0026_count=10\u0026title=t"}'

--select fhir_get_codesystem_by_id(37145)

with last_ver as ( -- список последних версий
 select 
  rbv.refbook_id, max(37145) id
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
 where (upper(rb.full_name) like ('T%'))
),

ready_data as (
 select refbook_id id from data
 -- сортировка, paging 
 -- limit __count
 -- offset __page
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



--select upper(get_value_of_param(('{"resourceType":"CodeSystem","queryString":"_page=1\u0026_count=10\u0026title=t"}'::json ->> 'queryString'), 'title')) || '%'


select urldecode_arr('title=%D0%9A')


CREATE OR REPLACE FUNCTION urldecode_arr(url text)
  RETURNS text AS
$BODY$
DECLARE ret text;

BEGIN
 BEGIN

    WITH STR AS (
      SELECT
      
      -- array with all non encoded parts, prepend with '' when the string start is encoded
      case when $1 ~ '^%[0-9a-fA-F][0-9a-fA-F]' 
           then array[''] 
           end 
      || regexp_split_to_array ($1,'(%[0-9a-fA-F][0-9a-fA-F])+', 'i') plain,
      
      -- array with all encoded parts
      array(select (regexp_matches ($1,'((?:%[0-9a-fA-F][0-9a-fA-F])+)', 'gi'))[1]) encoded
    )
    SELECT  string_agg(plain[i] || coalesce( convert_from(decode(replace(encoded[i], '%',''), 'hex'), 'utf8'),''),'')
    FROM STR, 
      (SELECT  generate_series(1, array_upper(encoded,1)+2) i FROM STR)blah

    INTO ret;

  EXCEPTION WHEN OTHERS THEN  
    raise notice 'failed: %',url;
    return $1;
  END;   

  RETURN coalesce(ret,$1); -- when the string has no encoding;

END;

$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT