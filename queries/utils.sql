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

-- example
-- select urldecode_arr('title=%D0%9A')
-- result "title=К"
CREATE OR REPLACE FUNCTION urldecode_arr(url text)
  RETURNS text AS
$BODY$
DECLARE ret text;

BEGIN
 BEGIN

    WITH STR AS (
      SELECT

      -- array with all non encoded parts, prepend with '' when the string start is encoded
      case when $1 ~ '^%[0-9a-fA-F][0-9a-fA-F]'
           then array['']
           end
      || regexp_split_to_array ($1,'(%[0-9a-fA-F][0-9a-fA-F])+', 'i') plain,

      -- array with all encoded parts
      array(select (regexp_matches ($1,'((?:%[0-9a-fA-F][0-9a-fA-F])+)', 'gi'))[1]) encoded
    )
    SELECT  string_agg(plain[i] || coalesce( convert_from(decode(replace(encoded[i], '%',''), 'hex'), 'utf8'),''),'')
    FROM STR,
      (SELECT  generate_series(1, array_upper(encoded,1)+2) i FROM STR)blah

    INTO ret;

  EXCEPTION WHEN OTHERS THEN
    raise notice 'failed: %',url;
    return $1;
  END;

  RETURN coalesce(ret,$1); -- when the string has no encoding;

END;

$BODY$
  LANGUAGE plpgsql IMMUTABLE STRICT