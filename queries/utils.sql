-- utils

-- example 
-- select get_value_of_param('_page=8&_count=12', '_count') 
-- result 12
CREATE OR REPLACE FUNCTION get_value_of_param(params text, key text)
RETURNS text as
$BODY$
begin
return (
 with t as (
  select string_to_array(regexp_split_to_table(params, '&'), '=') a
 )

 select a[2] from t
 where a[1] = key
 limit 1
);
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;