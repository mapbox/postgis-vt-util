/******************************************************************************
### MakeArc ###

Creates a CircularString arc based on 3 input points.

__Parameters:__

- `geometry(point)` p0 - The starting point of the arc.
- `geometry(point)` p1 - A point along the path of th arc.
- `geometry(point)` p2 - The end point of the arc.

__Returns:__ `geometry(linestring)`
******************************************************************************/
create or replace function MakeArc (
        p0 geometry(point),
        p1 geometry(point),
        p2 geometry(point)
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
        ST_SRID(p0)
    ));
end;
$func$;


