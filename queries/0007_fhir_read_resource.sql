CREATE OR REPLACE FUNCTION fhir.fhir_read_resource(query json)
  RETURNS json AS
$BODY$
begin
return (
select 
 case 
  when (query ->> 'resourceType') = 'CodeSystem' then fhir.fhir_get_codesystem_by_id((query ->> 'id'), (query ->> 'versionId'))
  when (query ->> 'resourceType') = 'ValueSet' then fhir.fhir_get_valueset_by_id((query ->> 'id'), (query ->> 'versionId'))
  else '{}'
 end val
);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- example
-- select fhir_read_resource('{"resourceType":"CodeSystem", "id": "37116"}'::json)
-- select fhir_get_valueset_by_id(37116)
-- select fhir_read_resource('{"resourceType":"ValueSet", "id": "37116"}'::json)