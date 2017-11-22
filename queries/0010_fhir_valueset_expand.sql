CREATE OR REPLACE FUNCTION fhir.fhir_valueset_expand(query json)
  RETURNS json AS
$BODY$
begin
return (

with 
/*query as ( 
 select '{"resourceType":"ValueSet","id":"37116","versionId":"37577"}'::json query
),*/

t as (
 select fhir.fhir_read_resource((query::jsonb || jsonb_build_object('resourceType', 'CodeSystem'))::json) val --from query
),

tt as (
 select jsonb_array_elements((val ->> 'concept')::jsonb)::jsonb val from t
),

ttt as (
 select 
  val ->> 'code' code,
  val ->> 'display' display
 from tt 
),

expansion as (
 select 
  ('{"total":' || count(1)::text || ',"contains": [' || string_agg(
    concat(
     '{"code":' || to_json(code),
     ',"display":' || to_json(display),
    '}'), 
    ',') ||
    ']}') ::json expansion
from ttt
)

select 
 fhir.fhir_read_resource((query::jsonb || jsonb_build_object('resourceType', 'ValueSet'))::json)::jsonb ||
 jsonb_build_object('expansion', (select expansion from expansion)) val 


);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE;