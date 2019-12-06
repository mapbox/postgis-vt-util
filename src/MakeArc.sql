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
    language plpgsql immutable
    parallel safe as
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


