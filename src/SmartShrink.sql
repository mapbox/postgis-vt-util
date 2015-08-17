/******************************************************************************
### SmartShrink ###

Buffers a polygon progressively (on an exponential scale) until the
area of the result hits a certain threshold ratio to the original area.
The result is also simplified with a tolerance matching the inset
distance.

__Parameters:__

- `geometry` g - A (multi)polygon.
- `float` ratio - The threshold for how much smaller (by area) you want
  the shrunk polygon to be compared to the original. Eg a value of 0.6
  would result in a polygon that is at least 60% as large as the input.
- `boolean` simplify - Defaults to false. Whether or not you would
  like the shrunk geometry simplified.

__Returns:__ `geometry`
******************************************************************************/
create or replace function SmartShrink(
        geom geometry,
        ratio float,
        simplify boolean = false
    )
    returns geometry
    language plpgsql immutable as
$func$
declare
    full_area float := ST_Area(geom);
    buf0 geometry;
    buf1 geometry := geom;
    d0 float := 0;
    d1 float := 2;
begin
    while ST_Area(buf1) > (full_area * ratio) loop
        d0 := d1;
        d1 := d1 * 2;
        buf0 := buf1;
        buf1 := ST_Buffer(geom, -d1, 'quad_segs=0');
    end loop;
    if simplify = true then
        return ST_SimplifyPreserveTopology(buf0, d0);
    else
        return buf0;
    end if;
end;
$func$;


