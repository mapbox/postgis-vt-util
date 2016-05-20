/******************************************************************************
### Smooth ###

Smooths the vertices of an input geometry using a simple moving-average-like
approach. The output will have the same number of vertices as the input.

There are 4 versions of the function, one each for inputs of linestring,
multilinestring, polygon, & multipolygon.

__Parameters:__

- `geometry` g - A linestring, multilinestring, polygon, or multipolygon

__Returns:__ `geometry` - a smoothed geometry of the same type and SRID as
the input.
******************************************************************************/

-- LINESTRING --

create or replace function Smooth (g geometry(linestring))
    returns geometry(linestring)
    language plpgsql immutable as
$func$
declare
    i int := 1;
    points geometry(point)[];
begin
    -- Keep the start point the same:
    points := array[ST_StartPoint(g)];
    -- For each vertex in the input linestring (except the first and last)
    -- calculate a new position based on the centroid of the original
    -- position and the positions of the immediate neighbor vertices:
    while i < (ST_NPoints(g) - 1) loop
        points := points || ST_Centroid(ST_Collect(array[
            ST_PointN(g, i), ST_PointN(g, i + 1), ST_PointN(g, i + 2)
        ]));
        i := i + 1;
    end loop;
    -- Keep the end point the same:
    points := points || ST_EndPoint(g);
    -- Turn the softened points back into a linestring
    return ST_MakeLine(points);
end;
$func$;


-- MULTILINESTRING --

create or replace function Smooth (g geometry(multilinestring))
    returns geometry(multilinestring)
    language sql immutable as
$func$
-- This is just a wrapper to call the linestring version of the function
-- for each part of the multilinestring:
select ST_Collect(Smooth(geom))
from (select (ST_Dump(g)).geom) as exploded;
$func$;


-- RING --
-- A helper function used by the polygon version of Smooth for each ring.
-- It's almost the same as Smooth(linestring) except the position of the
-- start point and end point are also smoothed (so it may also be useful
-- as a standalone function in some cases).

create or replace function SmoothRing (g geometry(linestring))
    returns geometry(linestring)
    language plpgsql immutable as
$func$
declare
    i int := 1;
    points geometry(point)[];
begin
    -- Special handling for the first point to average it with the 2nd
    -- and 2nd-last points:
    points := array[ST_Centroid(ST_Collect(array[
        ST_PointN(g, ST_NPoints(g) - 1),
        ST_PointN(g, 1),
        ST_PointN(g, 2)
    ]))];
    -- For each vertex in the input linestring (except the first and last)
    -- calculate a new position based on the centroid of the original
    -- position and the positions of the immediate neighbor vertices:
    while i < (ST_NPoints(g) - 1) loop
        points := points || ST_Centroid(ST_Collect(array[
            ST_PointN(g, i), ST_PointN(g, i + 1), ST_PointN(g, i + 2)
        ]));
        i := i + 1;
    end loop;
    -- Match the end point with the start point:
    points := points || points[1];
    -- Turn the softened points back into a polygon
    return ST_MakeLine(points);
end;
$func$;


-- POLYGON --

create or replace function Smooth (g geometry(polygon))
    returns geometry(polygon)
    language sql immutable as
$func$
select ST_MakePolygon(SmoothRing(ST_ExteriorRing(g)), (
    select array_agg(SmoothRing(ST_ExteriorRing(geom)))
    from ST_DumpRings(g) as rings
    where path[1] > 0
));
$func$;


-- MULTIPOLYGON --

create or replace function Smooth (g geometry(multipolygon))
    returns geometry(multipolygon)
    language sql immutable as
$func$
-- This is just a wrapper to call the polygon version of the function
-- for each part of the multipolygon:
select ST_Collect(Smooth(geom))
from (select (ST_Dump(g)).geom) as exploded;
$func$;
