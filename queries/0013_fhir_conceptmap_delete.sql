CREATE OR REPLACE FUNCTION fhir.fhir_conceptmap_delete(__id text)
  RETURNS json AS
$BODY$

with refbooks as (
  select id, m.source_refbook_id, m.target_refbook_id, m.id mapping_id from cnm.refbook_mapping m where m.id::text = __id
),

all_unique_columns as (
  select
    c.id
  from cnm.refbook_column c
  join refbooks r on (r.source_refbook_id = c.refbook_version_id or r.target_refbook_id = c.refbook_version_id) and c.is_unique_key
),

del_column_mapping as (
-- 123120	123115
  delete from cnm.refbook_column_mapping cm
  using all_unique_columns uc
  where uc.id = cm.source_column_id or uc.id = cm.target_column_id
),

del_record_mapping as (
  delete from cnm.record_mapping rm
  using refbooks r
  where rm.source_refbook_id = r.source_refbook_id or rm.source_refbook_id = r.target_refbook_id
),

del_mapping as (
  delete from cnm.refbook_mapping rm using refbooks r where r.mapping_id = rm.id
  returning rm.id
)

select ('{"id":' || id::text || '}')::json val from del_mapping;

$BODY$
  LANGUAGE sql VOLATILE;
