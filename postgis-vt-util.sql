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


/******************************************************************************
### CleanInt ###

Returns the input text as an integer if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an integer.

__Returns:__ `integer`
******************************************************************************/
create or replace function CleanInt (i text)
    returns integer
    language plpgsql immutable as
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


/******************************************************************************
### CleanNumeric ###

Returns the input text as an numeric if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an numeric.

__Returns:__ `numeric`
******************************************************************************/
create or replace function CleanNumeric (i text)
    returns numeric
    language plpgsql immutable as
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


/******************************************************************************
### LabelGrid ###

Returns a "hash" of a geometry's position on a specified grid to use in a GROUP
BY clause. Useful for limiting the density of points or calculating a localized
importance ranking.

This function is most useful on point geometries intended for label placement
(eg points of interest) but will accept any geometry type. It is usually used
as part of either a `DISTINCT ON` expression or a `rank()` window function.

__Parameters:__

- `geometry` g - A geometry.
- `numeric` grid_size - The cell size of the desired grouping grid.

__Returns:__ `text` - A text representation of the labelgrid cell

__Example Mapbox Studio query:__

```sql
(   SELECT * FROM (
        SELECT DISTINCT ON (LabelGrid(geom, 64*!pixel_width!)) * FROM (
            SELECT id, name, class, population, geom FROM city_points
            WHERE geom && !bbox!
        ) AS raw
        ORDER BY LabelGrid(geom, 64*!pixel_width!), population DESC, id
    ) AS filtered
    ORDER BY population DESC, id
) AS final
```
******************************************************************************/
create or replace function LabelGrid (
        g geometry,
        grid_size numeric
    )
    returns text
    language plpgsql immutable as
$func$
begin
    if grid_size <= 0 then
        return 'null';
    end if;
    if GeometryType(g) <> 'POINT' then
        g := (select (ST_DumpPoints(g)).geom limit 1);
    end if;
    return ST_AsText(ST_SnapToGrid(
        g,
        grid_size/2,  -- x origin
        grid_size/2,  -- y origin
        grid_size,    -- x size
        grid_size     -- y size
    ));
end;
$func$;


/******************************************************************************
### LargestPart ###

Returns the largest single part of a multigeometry.

- Given a multipolygon or a geometrycollection containing at least one polygon,
  this function will return the single polygon with the largest area.
- Given a multilinestring or a geometrycollection containing at least one
  linestring and no polygons, this function will return the single linestring
  with the longest length.
- Given a single point, line, or polygon, the original geometry will be
  returned.
- Given any other geometry type the result of `ST_GeometryN(<geom>, 1)` will be
  returned. (See the documentation for that function.)

__Parameters:__

- `geometry` g - A geometry.

__Returns:__ `geometry` - The largest single part of the input geometry.
******************************************************************************/
create or replace function LargestPart (g geometry)
    returns geometry
    language plpgsql immutable as
$func$
begin
    -- Non-multi geometries can just pass through
    if GeometryType(g) in ('POINT', 'LINESTRING', 'POLYGON') then
        return g;
    -- MultiPolygons and GeometryCollections that contain Polygons
    elsif not ST_IsEmpty(ST_CollectionExtract(g, 3)) then
        return (
            select geom
            from (
                select (ST_Dump(ST_CollectionExtract(g,3))).geom
            ) as dump
            order by ST_Area(geom) desc
            limit 1
        );
    -- MultiLinestrings and GeometryCollections that contain Linestrings
    elsif not ST_IsEmpty(ST_CollectionExtract(g, 2)) then
        return (
            select geom
            from (
                select (ST_Dump(ST_CollectionExtract(g,2))).geom
            ) as dump
            order by ST_Length(geom) desc
            limit 1
        );
    -- Other geometry types are not really handled but we at least try to
    -- not return a MultiGeometry.
    else
        return ST_GeometryN(g, 1);
    end if;
end;
$func$;


/******************************************************************************
### LineLabel ###

This function tries to estimate whether a line geometry would be long enough to
have the given text placed along it at the specified scale.

It is useful in vector tile queries to filter short lines from zoom levels
where they would be unlikely to have text places on them anyway.

__Parameters:__

- `numeric` zoom - The Web Mercator zoom level you are considering.
- `text` label - The label text that you will be placing along the line.
- `geometry(linestring)` g - A line geometry.

__Returns:__ `boolean`
******************************************************************************/
create or replace function LineLabel (
        zoom numeric,
        label text,
        g geometry
    )
    returns boolean
    language plpgsql immutable as
$func$
begin
    if zoom > 20 or ST_Length(g) = 0 then
        -- if length is 0 geom is (probably) a point; keep it
        return true;
    else
        return length(label) between 1 and ST_Length(g)/(2^(20-zoom));
    end if;
end;
$func$;


/******************************************************************************
### MakeArc ###

Creates a CircularString arc based on 3 input points.

__Parameters:__

- `geometry(point)` p0 - The starting point of the arc.
- `geometry(point)` p1 - A point along the path of the arc.
- `geometry(point)` p2 - The end point of the arc.
- `integer` srid (optional) - Sets the SRID of the output geometry. Useful
  when input points have no SRID. If not specified the SRID of the first
  input geometry will be assigned to the output.

__Returns:__ `geometry(linestring)`

__Examples:__


```sql
SELECT MakeArc(
    ST_MakePoint(-100, 0),
    ST_MakePoint(0, 100),
    ST_MakePoint(100, 0),
    3857
);
```
******************************************************************************/
create or replace function MakeArc (
        p0 geometry(point),
        p1 geometry(point),
        p2 geometry(point),
        srid integer default null
    )
    returns geometry
    language plpgsql immutable as
$func$
begin
    return ST_CurveToLine(ST_GeomFromText(
        'CIRCULARSTRING('
            || ST_X(p0) || ' ' || ST_Y(p0) || ', '
            || ST_X(p1) || ' ' || ST_Y(p1) || ',  '
            || ST_X(p2) || ' ' || ST_Y(p2) || ')',
        coalesce(srid, ST_SRID(p0))
    ));
end;
$func$;


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
        distance / cos(radians(ST_Y(ST_Transform(ST_Centroid(g),4326))))
    );
end;
$func$;


/******************************************************************************
### MercDWithin ###

Wrapper for ST_DWithin that adjusts distance by latitude to approximate real-
world measurements. Assumes input geometries are Web Mercator and input
distances are real-world meters. Accuracy decreases for larger distances and at
extreme latitudes.

__Parameters:__

- `geometry` g1 - The first geometry.
- `geometry` g2 - The second geometry.
- `numeric` distance - The maximum distance to check against

__Returns:__ `boolean`
******************************************************************************/
create or replace function MercDWithin (
        g1 geometry,
        g2 geometry,
        distance numeric
    )
    returns boolean
    language plpgsql immutable as
$func$
begin
    return ST_Dwithin(
        g1,
        g2,
        distance / cos(radians(ST_Y(ST_Transform(ST_Centroid(g1),4326))))
    );
end;
$func$;


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


/******************************************************************************
### OrientedEnvelope ###

Returns an oriented minimum-bounding rectangle for a geometry.

__Parameters:__

- `geometry` g - A geometry.

__Returns:__ `geometry(polygon)`
******************************************************************************/
create or replace function OrientedEnvelope (g geometry)
    returns geometry(polygon)
    language plpgsql immutable as
$func$
declare
    p record;
    p0 geometry(point);
    p1 geometry(point);
    ctr geometry(point);
    angle_min float;
    angle_cur float;
    area_min float;
    area_cur float;
begin
    -- Approach is based on the rotating calipers method:
    -- <https://en.wikipedia.org/wiki/Rotating_calipers>
    g := ST_ConvexHull(g);
    ctr := ST_Centroid(g);
    for p in (select (ST_DumpPoints(g)).geom) loop
        p0 := p1;
        p1 := p.geom;
        if p0 is null then
            continue;
        end if;
        angle_cur := ST_Azimuth(p0, p1) - pi()/2;
        area_cur := ST_Area(ST_Envelope(ST_Rotate(g, angle_cur, ctr)));
        if area_cur < area_min or area_min is null then
            area_min := area_cur;
            angle_min := angle_cur;
        end if;
    end loop;
    return ST_Rotate(ST_Envelope(ST_Rotate(g, angle_min, ctr)), -angle_min, ctr);
end;
$func$;


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


/******************************************************************************
### TileBBox ###

Given a Web Mercator tile ID as (z, x, y), returns a bounding-box
geometry of the area covered by that tile.

__Parameters:__

- `integer` z - A tile zoom level.
- `integer` x - A tile x-position.
- `integer` y - A tile y-position.
- `integer` srid - SRID of the desired target projection of the bounding
  box. Defaults to 3857 (Web Mercator).

__Returns:__ `geometry(polygon)`
******************************************************************************/
create or replace function TileBBox (z int, x int, y int, srid int = 3857)
    returns geometry
    language plpgsql immutable as
$func$
declare
    max numeric := 20037508.34;
    res numeric := (max*2)/(2^z);
    bbox geometry;
begin
    bbox := ST_MakeEnvelope(
        -max + (x * res),
        max - (y * res),
        -max + (x * res) + res,
        max - (y * res) - res,
        3857
    );
    if srid = 3857 then
        return bbox;
    else
        return ST_Transform(bbox, srid);
    end if;
end;
$func$;


/******************************************************************************
### ToPoint ###

Helper to wrap ST_PointOnSurface, ST_MakeValid. This is needed because
of a ST_PointOnSurface bug in geos < 3.3.8 where POLYGON EMPTY can pass
through as a polygon geometry.

__Parameters:__

- `geometry` g - A geometry.

__Returns:__ `geometry(point)`

__Example:__

```sql
-- Create an additional point geometry colums for labeling
ALTER TABLE city_park ADD COLUMN geom_label geometry(point);
UPDATE city_park SET geom_label = ToPoint(geom);
```
******************************************************************************/
create or replace function ToPoint (g geometry)
    returns geometry(point)
    language plpgsql immutable as
$func$
begin
    g := ST_MakeValid(g);
    if GeometryType(g) = 'POINT' then
        return g;
    elsif ST_IsEmpty(g) then
        -- This should not be necessary with Geos >= 3.3.7, but we're getting
        -- mystery MultiPoint objects from ST_MakeValid (or somewhere) when
        -- empty objects are input.
        return null;
    else
        return ST_PointOnSurface(g);
    end if;
end;
$func$;


/******************************************************************************
### ZRES ###

Takes a web mercator zoom level and returns the pixel resolution for that
scale, assuming 256x256 pixel tiles. Non-integer zoom levels are accepted.

__Parameters:__

- `float` z - A Web Mercator zoom level.

__Returns:__ `float`

__Examples:__

```sql
-- Delete all polygons smaller than 1px square at zoom level 10
DELETE FROM water_polygons WHERE sqrt(ST_Area(geom)) < ZRes(10);

-- Simplify geometries to a resolution appropriate for zoom level 10
UPDATE water_polygons SET geom = ST_Simplify(geom, ZRes(10));
```
******************************************************************************/
create or replace function ZRes (z integer)
  returns float
  language sql
  immutable
  returns null on null input
$func$
SELECT (40075016.6855785/(256*2^z));
$func$;


/******************************************************************************
### Z ###

Returns a Web Mercator integer zoom level given a scale denominator.

Useful with Mapnik's !scale_denominator! token in vector tile source
queries.

__Parameters:__

- `numeric` scale_denominator - The denominator of the scale, eg `250000`
  for a 1:250,000 scale.

__Returns:__ `integer`

__Example Mapbox Studio query:__

```sql
( SELECT * FROM roads
  WHERE Z(!scale_denominator!) >= 12
) AS data
```
******************************************************************************/
create or replace function z (numeric)
  returns integer
  language sql
  immutable
  returns null on null input
as $func$
select
  case
    -- Don't bother if the scale is larger than ~zoom level 0
    when $1 > 600000000 or $1 = 0 then null
    else cast (round(log(2,559082264.028/$1)) as integer)
  end;
$func$;


