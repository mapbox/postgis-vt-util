#!/usr/bin/env bash
set -e -u -o pipefail

passcount=0
failcount=0

psql="psql -U postgres -d testdb"
$psql -f $(dirname $0)/../lib.sql

function tf() {
    # tf (test a function)
    # Usage: tf function_name argument expected-output
    result=$($psql -c "COPY (SELECT $1($2)) TO STDOUT;")
    if [[ "$result" == "$3" ]]; then
        echo -e "✔ $2 ⇒ '$result' "
        passcount=$((passcount+1))
    else
        echo -e "✘ $2 ⇒ '$result' "
        echo "  ⤷ expected: '$3'"
        failcount=$((failcount+1))
    fi
}

echo -e "testing clean_int:"
tf clean_int "'123'"            "123"
tf clean_int "'foobar'"         "\\N"
tf clean_int "'2147483647'"     "2147483647"  # largest possible int
tf clean_int "'-2147483648'"    "-2147483648"  # smallest possible int
tf clean_int "'9999999999'"     "\\N"  # out of range, returns null
tf clean_int "'123.456'"        "123"  # round down
tf clean_int "'456.789'"        "457"  # round up

echo -e "testing clean_numeric:"
tf clean_numeric "'123'"            "123"
tf clean_numeric "'foobar'"         "\\N"
tf clean_numeric "'123.456'"        "123.456"  
tf clean_numeric "'456.789'"        "456.789"

echo -e "testing z:"
tf z "1000000000" "\\N"
tf z "500000000" "0"
tf z "1000" "19"

echo -e "testing zres:"
tf zres "0" "156543.033928041"
tf zres "19" "0.29858214173897"

echo -e "testing linelabel:"
tf linelabel "14, 'Foobar', ST_GeomFromText('POINT(0 0)',900913)" "t"
tf linelabel "14, 'Foobar', ST_GeomFromText('LINESTRING(0 0, 0 300)',900913)" "f"
tf linelabel "15, 'Foobar', ST_GeomFromText('LINESTRING(0 0, 0 300)',900913)" "t"

echo -e "testing labelgrid:"
tf labelgrid "ST_GeomFromText('POINT(100 -100)',900913), 64, 9.5546285343" \
    "POINT(305.7481130976 -305.7481130976)"

echo -e "testing topoint:"
tf topoint "ST_GeomFromText('POINT(0 0)',900913)" \
    "010100002031BF0D0000000000000000000000000000000000"
tf topoint "ST_GeomFromText('POLYGON EMPTY',900913)" "\\N"
tf topoint "ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',900913)" \
    "010100002031BF0D0000000000000014400000000000001440"
tf topoint "ST_GeomFromText('POLYGON((0 0, 10 0, 0 10, 10 10, 0 0))',900913)" \
    "010100002031BF0D0000000000000014400000000000000440"

echo -e "testing merc_buffer:"
tf floor "ST_Area(merc_buffer(ST_GeomFromText('LINESTRING(0 0, 1000 1000)', 900913), 500))" \
    "2194574"
tf floor "ST_Area(merc_buffer(ST_GeomFromText('POINT(0 8500000)', 900913), 500))" \
    "3207797"

echo -e "testing merc_dwithin:"
tf merc_dwithin "ST_GeomFromText('POINT(0 0)',3857), ST_GeomFromText('POINT(60 0)',3857), 50.0" \
    "f"
tf merc_dwithin "ST_GeomFromText('POINT(0 8500000)',3857), ST_GeomFromText('POINT(60 8500000)',3857), 50.0" \
    "t"

echo -e "testing merc_length:"
tf merc_length "ST_GeomFromText('LINESTRING(0 0, 10000 0)', 900913)" \
    "10000"
tf merc_length "ST_GeomFromText('LINESTRING(0 8500000, 10000 8500000)', 900913)" \
    "4932.24215371697"

echo -e "testing tile_bbox:"
tf st_astext "st_snaptogrid(tile_bbox(0,0,0),0.01)" \
    "POLYGON((-20037508.34 20037508.34,-20037508.34 -20037508.34,20037508.34 -20037508.34,20037508.34 20037508.34,-20037508.34 20037508.34))"
tf st_astext "st_snaptogrid(tile_bbox(11,585,783),0.01)" \
    "POLYGON((-8590298.99 4715858.9,-8590298.99 4696291.02,-8570731.11 4696291.02,-8570731.11 4715858.9,-8590298.99 4715858.9))"

# summary:
echo -e "$passcount tests passed | $failcount tests failed"

exit $failcount
