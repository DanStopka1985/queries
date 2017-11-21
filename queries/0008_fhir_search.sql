CREATE OR REPLACE FUNCTION fhir.fhir_search(query json)
  RETURNS json AS
$BODY$
begin
return (
 select
  case
   when (query ->> 'resourceType') = 'CodeSystem' then fhir.fhir_codesystem_search(query)
   when (query ->> 'resourceType') = 'ValueSet' then fhir.fhir_valueset_search(query)
   else '{}'
  end val
);

end;
$BODY$
  LANGUAGE plpgsql VOLATILE;