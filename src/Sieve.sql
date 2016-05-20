/******************************************************************************
### Sieve ###

Filters small rings (both inner and outer) from a multipolygon based on area.

__Parameters:__

- `geometry` g - A multipolygon
- `float` area_threshold - the minimum ring area to keep.

__Returns:__ `geometry` - a polygon or multipolygon
******************************************************************************/
create or replace function Sieve (g geometry, area_threshold float)
    returns geometry
    language sql immutable as
$func$
    with exploded as (
        -- First use ST_Dump to explode the input multipolygon
        -- to individual polygons.
        select (ST_Dump(g)).geom
    ), rings as (
        -- Next use ST_DumpRings to turn all of the inner and outer rings
        -- into their own separate polygons.
        select (ST_DumpRings(geom)).geom from exploded
    ) select
        -- Finally, build the multipolygon back up using only the rings
        -- that are larger than the specified threshold area.
            ST_SetSRID(ST_BuildArea(ST_Collect(geom)), ST_SRID(g))
        from rings
        where ST_Area(geom) > area_threshold;
$func$;

create or replace function Sieve (g geometry, area_threshold integer)
    returns geometry
    language sql immutable as
$func$
    with exploded as (
        -- First use ST_Dump to explode the input multipolygon
        -- to individual polygons.
        select (ST_Dump(g)).geom
    ), rings as (
        -- Next use ST_DumpRings to turn all of the inner and outer rings
        -- into their own separate polygons.
        select (ST_DumpRings(geom)).geom from exploded
    ) select
        -- Finally, build the multipolygon back up using only the rings
        -- that are larger than the specified threshold area.
            ST_SetSRID(ST_BuildArea(ST_Collect(geom)), ST_SRID(g))
        from rings
        where ST_Area(geom) > area_threshold;
$func$;


