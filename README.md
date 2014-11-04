postgis-vt-util
========

postgres helper functions for making vector tiles in [Mapbox Studio]()

## `z`

Given the !scale_denominator! mapnik token, returns a zoom level. Lets you to control at which zoom levels features appear.

**Arguments:** !scale_denominator! [mapnik token]

**Example:**

```sql
( select
    some, attributes,
    geom_generalized
  from your_table
  where z(!scale_denominator!) in (10,11,12)
  union ALL
  select
    some, attributes,
    geom_not_generalized
  from your_table
  where z(!scale_denominator!) >= 13
) as data
```

## labelgrid

De-duplicates features based on a given grid size, letting you control feature density. All features are snapped to a grid, but only 1 feature per grid cell is returend when selecting `DISTINCT ON` the labelgrid function.

**Arguments:** geometry [geometry], grid size [an integer that divides evenly into 256], `!pixel_width!` [mapnik token]

**Example:**

## topoint

Performs a per-vector tile [point-on-surface](http://postgis.net/docs/ST_PointOnSurface.html)operation, returning a point geometry for a given polygon geometry. Good for generating only one label for polygon features.

**Arguments:** geometry [geometry]

**Example:**

## linelabel

Select only those line geometries long enough to be labeled; drops all line geometries too short for mapnik to place a label. Linelabel compares line length to the length of a user-supplied label field.

**Arguments:** label [text field], geometry [geometry]

**Example:**


