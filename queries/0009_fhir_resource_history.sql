CREATE OR REPLACE FUNCTION fhir.fhir_resource_history(query json)
  RETURNS json AS
$BODY$
begin
return (

with vs as ( -- все версии справочника
 select id from cnm.refbook_version where refbook_id::text = (query ->> 'id')::text
),

valid_list as ( -- валидные версии справочника (уникальная колонка 1 и только одна, отображаемые колонки - не больше одной)
 select vs.id from vs
 join cnm.refbook_column rbc on rbc.refbook_version_id = vs.id
 group by vs.id having sum(case when is_display_name then 1 else 0 end) <= 1 and sum(case when is_unique_key then 1 else 0 end) = 1
),

cmn as (
 select rbv.id csv_id, rbv.refbook_id from valid_list vl
 join cnm.refbook_version rbv on rbv.id = vl.id
 order by rbv.id desc
)

 select
  ('{"resourceType": "Bundle"' ||
  ', "type": "history"' ||
  ', "total": ' || (select count(1) from cmn) ||
  ', "entry": [' ||
    (
     select string_agg(
      concat(
       '{"resource":', fhir.fhir_read_resource((jsonb (query::jsonb || jsonb_build_object('versionId', csv_id::text)))::json)::text,
       '}')
     , ',') from cmn
    )
   || ']'
  '}')::json val

);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE;