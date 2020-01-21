/******************************************************************************
### CleanNumeric ###

Returns the input text as an numeric if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an numeric.

__Returns:__ `numeric`
******************************************************************************/
create or replace function CleanNumeric (i text) returns numeric as
$func$
select case
            when test[1] in ('', '.') then null
            else cast(cast(test[1] as float) as numeric)
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



