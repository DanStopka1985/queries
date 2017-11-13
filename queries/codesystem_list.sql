--fhir_codesystem_search

-- последние версии
-- c уникальными колонками (=1)
-- отображаемая колонка (<=1)

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
 -- фильтры, сортировки, paging
 limit 10
)

select refbook_id, fhir_get_codesystem_by_id(refbook_id) from data
 