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
        distance / pg_catalog.cos(pg_catalog.radians(ST_Y(ST_Transform(ST_Centroid(g1),4326))))
    );
end;
$func$;


