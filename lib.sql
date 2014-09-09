---------------------------------------
-- converts mapnik's !scale_denominator! param to web mercator zoom
CREATE OR REPLACE FUNCTION public.z(scaledenominator numeric)
 RETURNS integer
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    -- Don't bother if the scale is larger than ~zoom level 0
    if scaledenominator > 600000000 then
        return null;
    end if;
    return round(log(2,559082264.028/scaledenominator));
end;
$function$;

---------------------------------------
-- early label placement helper. Snap geometry to a grid sized
-- for point places at the given zoom level and return a string "hash"
-- for deduping.
CREATE OR REPLACE FUNCTION public.labelgrid(geometry geometry(Geometry, 900913), grid_width numeric, pixel_width numeric)
 RETURNS text
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if pixel_width = 0 then
        return 'null';
    end if;
    return st_astext(st_snaptogrid(
            geometry,
            grid_width/2*pixel_width,  -- x origin
            grid_width/2*pixel_width,  -- y origin
            grid_width*pixel_width,    -- x size
            grid_width*pixel_width     -- y size
    ));
end;
$function$;

---------------------------------------
-- early label placement filter -- determine whether a label text will
-- fit on a given line at a given zoom level.
CREATE OR REPLACE FUNCTION public.linelabel(zoom numeric, label text, geometry geometry(Geometry, 900913))
 RETURNS boolean
 LANGUAGE plpgsql IMMUTABLE
AS $function$
begin
    if zoom > 20 or st_length(geometry) = 0 then
        -- if length is 0 geom is (probably) a point; keep it
        return true;
    else
        return length(label) BETWEEN 1 AND st_length(geometry)/(2^(20-zoom));
    end if;
end;
$function$;