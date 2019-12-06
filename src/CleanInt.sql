/******************************************************************************
### CleanInt ###

Returns the input text as an integer if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an integer.

__Returns:__ `integer`
******************************************************************************/
create or replace function CleanInt (i text)
    returns integer
    language plpgsql immutable
    parallel safe as
$func$
begin
    return cast(cast(i as float) as integer);
exception
    when invalid_text_representation then
        return null;
    when numeric_value_out_of_range then
        return null;
end;
$func$;


