/******************************************************************************
### CleanNumeric ###

Returns the input text as an numeric if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an numeric.

__Returns:__ `numeric`
******************************************************************************/
create or replace function CleanNumeric (i text)
    returns numeric
    language plpgsql immutable
    parallel safe as
$$
begin
    return cast(cast(i as float) as numeric);
exception
    when invalid_text_representation then
        return null;
    when numeric_value_out_of_range then
        return null;
end;
$$;


