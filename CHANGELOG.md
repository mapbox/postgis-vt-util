Changelog
=========

v1.1.0
------

- New function `Sieve` which filters inner and outer rings from a multipolygon
  based on a minimum area threshold.
- Z function converted to SQL from PL/PGSQL.
- ZRes function converted to SQL from PL/PGSQL and overloaded to accept both
  floats and integers.

v1.0.0
------

This version brings lots of code cleanup and reorganization, with many
backwards-incompatible changes.

- `lib.sql` has been renamed to the more specific `postgis-vt-util.sql`
- Underscores have been removed from function names, following PostGIS'
  convention
    - `clean_int` -> `CleanInt`
    - `clean_numeric` -> `CleanNumeric`
    - `tile_bbox` -> `TileBBox`
    - `merc_buffer` -> `MercBuffer`
    - `merc_dwithin` -> `MercDWithin`
    - `merc_length` -> `MercLength`
    - We've also moved to CamelCase for all other functions, but PostgreSQL is
      not case-sensitive in this regard so it's purely stylistic.
- `LabelGrid` no longer takes a pixel size parameter. You should now pre-
  multiply this into the grid size before calling the function.
- `TileBBox` now takes an optional SRID parameter to reproject the output.
- Several new functions have been added. See the README for descriptions.
    - `Bounds`
    - `LargestPart`
    - `MakeArc`
    - `OrientedEnvelope`
    - `SmartShrink`


v0.3.0
------

- New function: `tile_bbox`


v0.2.0
------

- New function: `clean_numeric`


v0.1.0
------

- Initial release with 9 functions:
    - `clean_int`
    - `labelgrid`
    - `linelabel`
    - `merc_buffer`
    - `merc_dwithin`
    - `merc_length`
    - `topoint`
    - `z`
    - `zres`

