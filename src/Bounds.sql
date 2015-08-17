/******************************************************************************
### Bounds ###

Returns an array of the bounding coordinates of the input geometry -
`{xmin, ymin, xmax, ymax}`. Useful for interfacing with software outside of
PostGIS, among other things.

If an SRID is specified the output will be the bounds of the reprojected
geometry, not a reprojected bounding box.

__Parameters:__

- `geometry` g - Any geometry
- `integer` srid (optional) - The desired output SRID of the bounds, if
  different from the input.

__Returns:__ `float[]` - an array of 4 floats, `{xmin, ymin, xmax, ymax}`
******************************************************************************/
create or replace function Bounds (g geometry, srid integer = null)
    returns float[]
    language plpgsql immutable as
$func$
begin
    if srid is not null then
        g := ST_Transform(g, srid);
    end if;

    return array[
        ST_XMin(g),
        ST_YMin(g),
        ST_XMax(g),
        ST_YMax(g)
    ];
end;
$func$;


