CREATE OR REPLACE FUNCTION fhir.fhir_conceptmap_create(query json)
  RETURNS json AS
$BODY$

with
_group as (
  select json_array_elements((query ->> 'group')::json) _group limit 1
),

_common as (
  select
   coalesce(_group ->> 'source_version', (select max(id)::text from cnm.refbook_version where refbook_id::text = (_group ->> 'source')))::integer source_version_id,
   coalesce(_group ->> 'target_version', (select max(id)::text from cnm.refbook_version where refbook_id::text = (_group ->> 'target')))::integer target_version_id
  from _group
),

_mapping_rows as (
  select json_array_elements((_group ->>'element')::json)::json "row" from _group
),

mapping_rows as (
  select
    "row" ->> 'code' source_code,
    json_array_elements(("row" ->> 'target')::json) ->> 'code' target_code
  from _mapping_rows
),

common as (
  select max(src.id) src_id, max(trc.id) trc_id from _common c
  join cnm.refbook_column src on src.refbook_version_id = c.source_version_id and src.is_unique_key
  join cnm.refbook_column trc on trc.refbook_version_id = c.target_version_id and trc.is_unique_key
  having max(src.id) = min(src.id) and max(trc.id) = min(trc.id)
),

src as (
  select src.value, src.column_id, src.record_id id from cnm.record_column src join common c on c.src_id = src.column_id
),

trc as (
  select trc.value, trc.column_id, trc.record_id id from cnm.record_column trc join common c on c.trc_id = trc.column_id
),

result_mapping as (
  select source_code, src.id source_record_id, target_code, trc.id target_record_id from mapping_rows mr
  cross join _common _c
  cross join common c
  join src on src.column_id = c.src_id and src.value = mr.source_code
  join trc on trc.column_id = c.trc_id and trc.value = mr.target_code
),

rb_mapping as (
  insert into cnm.refbook_column_mapping(source_column_id, target_column_id)
  select c.src_id, c.trc_id from common c
  returning *
),

record_mapping as (
  insert into cnm.record_mapping(target_record_id, source_record_id, source_refbook_id)
  select rm.target_record_id, rm.source_record_id, _c.source_version_id from result_mapping rm cross join _common _c
),

result as (
  insert into cnm.refbook_mapping(id, source_refbook_id, target_refbook_id)
  select nextval('cnm.refbook_mapping_id_seq'), _c.source_version_id, _c.target_version_id from _common _c

  returning id
)

select ('{"id":' || id::text || '}')::json val from result;
$BODY$
  LANGUAGE sql VOLATILE;