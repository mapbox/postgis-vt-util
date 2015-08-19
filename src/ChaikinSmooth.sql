/******************************************************************************
### ChaikinSmooth ###

Smooths a line or polygon using George Chaikin's corner-cutting algorithm.

<http://www.idav.ucdavis.edu/education/CAGDNotes/Chaikins-Algorithm.pdf>

__Parameters:__

- `geometry` g - A (multi)linestring or (multi)polygon
- `integer`steps - Number of smoothing iterations to run. Defaults to 1.

__Returns:__ `geometry`
******************************************************************************/
create or replace function ChaikinSmooth (g geometry, steps integer = 1)
    returns geometry
    language plpgsql immutable as
$func$
declare
    polygon boolean := (GeometryType(g) like '%POLYGON');
    newpart geometry(point)[];
    newgeom geometry;
    i integer = 0;
    part record;
    pt integer; -- point total
    pi integer; -- point index
    p0 geometry(point);
    p1 geometry(point);
begin
    if polygon then
        g := ST_Boundary(g);
    end if;

    while i < steps loop

        for part in (select (ST_Dump(g)).geom) loop

            -- First step - subdivide all of the segments
            pt := (ST_NumPoints(part.geom) * 2) + 1;
            pi := 1;
            while pi < pt loop
                part.geom := ST_AddPoint(part.geom, ST_Centroid(ST_Collect(
                        ST_PointN(part.geom, pi),
                        ST_PointN(part.geom, pi + 1))),
                        pi);
                pi := pi + 2;
            end loop;

            -- Second step - build smoothed version
            pt := ST_NumPoints(part.geom);
            pi := 1;
            newpart := null;
            while pi < pt loop
                if not polygon and pi = 1 then
                    -- start points of lines should not change
                    newpart := array[ST_PointN(part.geom, 1)];
                else
                    newpart := newpart || ST_Centroid(ST_Collect(
                            ST_PointN(part.geom, pi),
                            ST_PointN(part.geom, pi + 1)
                        ));
                end if;
                pi := pi + 1;
            end loop;

            if polygon then
                -- close the polygon
                newpart := newpart || newpart[1];
            end if;

            if newgeom is null then
                newgeom := ST_MakeLine(newpart);
            else
                newgeom := ST_Collect(newgeom, ST_MakeLine(newpart));
            end if;

        end loop;

        g := newgeom;
        newgeom := null;
        i := i + 1;

    end loop;

    if polygon then
        return ST_Buildarea(g);
    else
        return g;
    end if;

end;
$func$;
