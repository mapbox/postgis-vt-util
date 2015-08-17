/******************************************************************************
### MercLength ###

Wrapper for ST_Length that adjusts distance by latitude to approximate real-
world measurements. Assumes input geometries are Web Mercator.  Accuracy
decreases for larger y-axis ranges of the input.

__Parameters:__

- `geometry` g - A (multi)linestring geometry.

__Returns:__ `numeric`
******************************************************************************/
create or replace function MercLength (g geometry)
    returns numeric
    language plpgsql immutable as
$func$
begin
    return ST_Length(g) * cos(radians(ST_Y(ST_Transform(ST_Centroid(g),4326))));
end;
$func$;


