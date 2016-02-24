PostGIS Vector Tile Utils
=========================

A set of PostgreSQL functions that are useful when creating vector tile sources,
either at the query stage in [Mapbox Studio][1] or in the earlier data
preparation stages.

[1]: http://mapbox.com/mapbox-studio

Installation
------------

Everything you need is in `postgis-vt-util.sql`. This project is also
available [as an NPM module][2] if that's useful to your workflow.

[2]: https://www.npmjs.com/package/postgis-vt-util

Load the file into your database with `psql` or whatever your usual method is.
Eg:

    psql -U <username> -d <dbname> -f postgis-vt-util.sql

Function Reference
------------------

<!-- DO NOT EDIT BELOW THIS LINE - AUTO-GENERATED FROM SQL COMMENTS -->

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


### CleanInt ###

Returns the input text as an integer if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an integer.

__Returns:__ `integer`


### CleanNumeric ###

Returns the input text as an numeric if possible, otherwise null.

__Parameters:__

- `text` i - Text that you would like as an numeric.

__Returns:__ `numeric`


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


### MercLength ###

Wrapper for ST_Length that adjusts distance by latitude to approximate real-
world measurements. Assumes input geometries are Web Mercator.  Accuracy
decreases for larger y-axis ranges of the input.

__Parameters:__

- `geometry` g - A (multi)linestring geometry.

__Returns:__ `numeric`


### OrientedEnvelope ###

Returns an oriented minimum-bounding rectangle for a geometry.

__Parameters:__

- `geometry` g - A geometry.

__Returns:__ `geometry(polygon)`


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

