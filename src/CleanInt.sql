/******************************************************************************
### CleanInt ###

Returns the input text as an integer if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an integer.

__Returns:__ `integer`
******************************************************************************/
create or replace function CleanInt (i text) returns integer as
$body$
declare n numeric := substring(i from '^\s*([-+]?(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee][-+]?\d+)?)\s*$');
begin
    if n not between -2147483648 and 2147483647 then
        return null;
    else
        return n::float8::integer;
    end if;
end;
$body$
language plpgsql
strict immutable cost 20
parallel safe;
