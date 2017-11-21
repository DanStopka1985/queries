create schema if not exists fhir;

create table if not exists fhir.settings (
 id serial primary key,
 code text,
 definition text,
 text_value text,
 int_value integer,
 default_text_value text,
 default_int_value integer,
 check(coalesce(default_text_value, default_int_value::text) is not null)
);

insert into fhir.settings(code, definition, default_text_value)
select 'baseURL', 'адрес FHIRAPI', 'http://acme.ru' where not exists (select 1 from fhir.settings where code = 'baseURL');

insert into fhir.settings(code, definition, default_int_value)
select 'codesystemSearchCount', 'количество отображаемых CodeSystem, если не указан параметр _count', 5 where not exists (select 1 from fhir.settings where code = 'codesystemSearchCount');

insert into fhir.settings(code, definition, default_int_value)
select 'valuesetSearchCount', 'количество отображаемых ValueSet, если не указан параметр _count', 6 where not exists (select 1 from fhir.settings where code = 'valuesetSearchCount');