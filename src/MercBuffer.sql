/******************************************************************************
### MercBuffer ###

Wraps ST_Buffer to adjust the buffer distance by latitude in order to
approximate real-world measurements. Assumes input geometries are Web Mercator
and input distances are real-world meters. Accuracy decreases for larger buffer
distances and at extreme latitudes.

__Parameters:__

- `geometry` g - A geometry to buffer.
- `numeric` distance - The distance you would like to buffer, in real-world
  meters.

__Returns:__ `geometry`
******************************************************************************/
create or replace function MercBuffer (g geometry, distance numeric)
    returns geometry
    language plpgsql immutable as
$func$
begin
    return ST_Buffer(
        g,
        distance / pg_catalog.cos(pg_catalog.radians(ST_Y(ST_Transform(ST_Centroid(g),4326))))
    );
end;
$func$;


