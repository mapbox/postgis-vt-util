/******************************************************************************
### Sieve ###

Filters small rings (both inner and outer) from a multipolygon based on area.

__Parameters:__

- `geometry` g - A multipolygon
- `anyelement` area_threshold - the minimum ring area to keep. Type must be either `float` or `integer`.

__Returns:__ `geometry` - a polygon or multipolygon
******************************************************************************/
create or replace function Sieve (g geometry, area_threshold anyelement)
    returns geometry
    language plpgsql immutable as
$func$
begin

  -- DRY up code by defining one function for both integer and float inputs
  -- define an empty polygon for the error detail to maintain geometry return type for any
  -- functions that wrap this and expect a geometry to come back when we raise an exception
  if pg_typeof(area_threshold) != all(array['integer', 'float']::regtype[]) then
    raise exception using
      errcode='INVAL',
      message='Invalid parameter input in sieve- area_threshold must be either integer or float.',
      detail=ST_GeomFromText('POLYGON EMPTY', ST_SRID(g));
  end if;

  if not st_isvalid(g) then
    raise exception using
      errcode='INVAL',
      message='Invalid input geometry in sieve- will return null. See exception detail for location.',
      detail=ST_SetSRID(location(ST_IsValidDetail(g)), ST_SRID(g));
  end if;

  return (
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
      where ST_Area(geom) > area_threshold
  );

end;
$func$;
