postgis-vt-util
========

postgres helper functions for making vector tiles in [Mapbox Studio]()

## z

Given the !scale_denominator! mapnik token, returns a zoom level. Lets you to control at which zoom levels features appear.

**Arguments:** !scale_denominator! [mapnik token]

**Example:**

```sql
( SELECT
    some, attributes,
    geom_generalized
  FROM your_table
  where z(!scale_denominator!) in (10,11,12)
  union ALL
  SELECT
    some, attributes,
    geom_not_generalized
  FROM your_table
  where z(!scale_denominator!) >= 13
) as data
```

## labelgrid

De-duplicates features based on a given grid size, letting you control feature density. All features are snapped to a grid, but only 1 feature per grid cell is returend when selecting `DISTINCT ON` the labelgrid function.

**Arguments:** geometry [geometry], grid size [an integer that divides evenly into 256], `!pixel_width!` [mapnik token]

**Example:**

```sql
( SELECT
    disctinct on(labelgrid(geom, 128, !pixel_width!))
    some, other, attributes
  FROM your_table
) AS data
```

## linelabel

Select only those line geometries long enough to be labeled; drops all line geometries too short for mapnik to place a label. Linelabel compares line length to the length of a user-supplied label field.

**Arguments:** zoom [integer], label [text field], geometry [geometry]

**Example:**

```sql
( SELECT
    name, geom
  FROM your_table
  WHERE linelabel(z(!scale_denominator!), name, geom)
) AS data
```

## merc_buffer

Wrapper for ST_Buffer that adjusts distance by latitude to approximate real-world measurements. Assumes input geometries are Web Mercator and input distances are real-world meters. Accuracy decreases for larger buffer distances and at extreme latitudes.

**Arguments:** geometry [geometry], distance in meters [numeric]

## merc_dwithin

Wrapper for ST_DWithin that adjusts distance by latitude to approximate real-world measurements. Assumes input geometries are Web Mercator and input distances are real-world meters. Accuracy decreases for larger distances and at extreme latitudes.

**Arguments:** geometry a [geometry], geometry b [geometry], distance in meters [numeric]

## merc_length

Wrapper for ST_Length that adjusts distance by latitude to approximate real-world measurements. Assumes input geometries are Web Mercator. Accuracy decreases for larger y-axis ranges of the input.

**Arguments:** geometry [geometry]
