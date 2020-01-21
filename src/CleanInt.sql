/******************************************************************************
### CleanInt ###

Returns the input text as an integer if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an integer.

__Returns:__ `integer`
******************************************************************************/
create or replace function CleanInt (i text) returns integer as
$func$
select case
            when test[1] in ('', '.') then null
            else
                case
                    when cast(test[1] as numeric) > 2147483647 then null
                    when cast(test[1] as numeric) < -2147483648 then null
                    else cast(cast(test[1] as float) as integer)
                end
        end as result
from (
    select array_agg(i) as test
    from (
        select (regexp_matches($1, '^[\ ]*?([-+]?[0-9]*\.?[0-9]*?(e[-+]?[0-9]+)?)[\ ]*?$', 'i'))[1] i
    ) t
) _;
$func$
language sql 
strict immutable cost 50
parallel safe;

