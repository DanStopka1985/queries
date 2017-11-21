SET plv8.start_proc = 'plv8_init'; 

select fhir_create_resource('{"resource":{
 "resourceType": "CodeSystem",
 "status": "unknown",
 "content": "complete",
 "concept": [
  {
   "code": "a",
   "display": "a1"
  },

  {
   "code": "b",
   "display": "b1"
  }
 ]
}}
'::json
)

--c264d52a-1548-4fc9-bac7-970cdb747e4c