#!/usr/bin/env bash
set -u

passcount=0
failcount=0
runcount=0
testtotal=$(grep -c '^tf ' "$0")

psqld="psql -AtqX -d testing_postgis_vt_util"
$psqld -f "$(dirname "$0")/../postgis-vt-util.sql" &> /dev/null

function tf() {
    # tf (test a function)
    # Usage: tf function_name argument expected-output
    runcount=$((runcount+1))
    result=$($psqld -c "COPY (SELECT $1($2)) TO STDOUT;")
    if [[ "$result" == "$3" ]]; then
        echo -e "ok $runcount - $1($2)"
        passcount=$((passcount+1))
    else
        echo "not ok $runcount - $1($2)"
        echo "    expected: '$3'"
        echo "    actual: '$result'"
        failcount=$((failcount+1))
    fi
}

echo "TAP version 13"
echo "1..$testtotal"

# Bounds
tf Bounds "ST_GeomFromText('LINESTRING(100 100, 300 300)', 3857)" \
    "{100,100,300,300}"
tf Bounds "ST_GeomFromText('LINESTRING(100 100, 300 300)', 3857), 4326" \
    "{0.000898315284119521,0.00089831528408666,0.00269494585235856,0.0026949458513567}"

# CleanInt
tf CleanInt "'123'"            "123"
tf CleanInt "'foobar'"         "\\N"
tf CleanInt "'2147483647'"     "2147483647"  # largest possible int
tf CleanInt "'-2147483648'"    "-2147483648"  # smallest possible int
tf CleanInt "'9999999999'"     "\\N"  # out of range, returns null
tf CleanInt "'123.456'"        "123"  # round down
tf CleanInt "'456.789'"        "457"  # round up

# CleanNumeric
tf CleanNumeric "'123'"            "123"
tf CleanNumeric "'foobar'"         "\\N"
tf CleanNumeric "'123.456'"        "123.456"
tf CleanNumeric "'456.789'"        "456.789"

# LabelGrid
tf LabelGrid "ST_GeomFromText('POINT(100 -100)',900913), 64*9.5546285343" \
    "POINT(305.7481130976 -305.7481130976)"

# LargestPart
tf LargestPart "ST_GeomFromText('POLYGON((10 10, 10 20, 20 20, 20 10, 10 10))')" \
    "010300000001000000050000000000000000002440000000000000244000000000000024400000000000003440000000000000344000000000000034400000000000003440000000000000244000000000000024400000000000002440"
tf LargestPart "ST_GeomFromText('MULTIPOLYGON(\
    ((-20 -20, -20 20, -10 20, -10 -20, -20 -20)),\
    ((10 10, 10 20, 20 20, 20 10, 10 10)))')" \
    "0103000000010000000500000000000000000034C000000000000034C000000000000034C0000000000000344000000000000024C0000000000000344000000000000024C000000000000034C000000000000034C000000000000034C0"
tf LargestPart "ST_GeomFromText('LINESTRING(0 0, 10 0)')" \
    "0102000000020000000000000000000000000000000000000000000000000024400000000000000000"
tf LargestPart "ST_GeomFromText('MULTILINESTRING((0 0, 10 0),(0 10, 20 10))')" \
    "0102000000020000000000000000000000000000000000244000000000000034400000000000002440"
tf LargestPart "ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(0 0, 0 10),\
    POLYGON((10 10, 10 20, 20 20, 20 10, 10 10)))')" \
    "010300000001000000050000000000000000002440000000000000244000000000000024400000000000003440000000000000344000000000000034400000000000003440000000000000244000000000000024400000000000002440"

# LineLabel
tf LineLabel "14, 'Foobar', ST_GeomFromText('POINT(0 0)',900913)" "t"
tf LineLabel "14, 'Foobar', ST_GeomFromText('LINESTRING(0 0, 0 300)',900913)" "f"
tf LineLabel "15, 'Foobar', ST_GeomFromText('LINESTRING(0 0, 0 300)',900913)" "t"

# MakeArc
tf floor "ST_Length(MakeArc(ST_MakePoint(0,0), ST_MakePoint(20,10), ST_MakePoint(40,0)))" \
    "46"

# MercBuffer
tf floor "ST_Area(MercBuffer(ST_GeomFromText('LINESTRING(0 0, 1000 1000)', 900913), 500))" \
    "2194574"
tf floor "ST_Area(MercBuffer(ST_GeomFromText('POINT(0 8500000)', 900913), 500))" \
    "3207797"

# MercDWithin
tf MercDWithin "ST_GeomFromText('POINT(0 0)',3857), ST_GeomFromText('POINT(60 0)',3857), 50.0" \
    "f"
tf MercDWithin "ST_GeomFromText('POINT(0 8500000)',3857), ST_GeomFromText('POINT(60 8500000)',3857), 50.0" \
    "t"

# MercLength
tf MercLength "ST_GeomFromText('LINESTRING(0 0, 10000 0)', 900913)" \
    "10000"
tf MercLength "ST_GeomFromText('LINESTRING(0 8500000, 10000 8500000)', 900913)" \
    "4932.24215371697"

# OrientedEnvelope
tf ST_AsText "OrientedEnvelope(ST_GeomFromText('LINESTRING(0 0, 10 10, 8 12)'))" \
    "POLYGON((8 12,10 10,0 0,-2 2,8 12))"

# Sieve
tf ST_AsText "Sieve(ST_GeomFromText('MULTIPOLYGON(\
    ((0 0,0 100,100 100,100 0,0 0),(10 10,12 10,12 12,10 12,10 10),(50 50,60 50,60 60,50 60,50 50)),\
    ((200 200,200 202,202 202,202 200,200 200)),\
    ((300 300,300 350,350 350,350 300,300 300)))'),10)" \
    "MULTIPOLYGON(((0 0,0 100,100 100,100 0,0 0),(50 50,60 50,60 60,50 60,50 50)),((300 300,300 350,350 350,350 300,300 300)))"

# SmartShrink
tf floor "ST_Area(SmartShrink(ST_Buffer(ST_MakePoint(0,0),5000),0.5,true))" \
    "44602035"
tf floor "ST_Area(SmartShrink(ST_Buffer(ST_MakePoint(0,0),5000),0.5,false))" \
    "49222695"

# TileBBox
tf ST_AsText "ST_SnapToGrid(TileBBox(0,0,0),0.01)" \
    "POLYGON((-20037508.34 20037508.34,-20037508.34 -20037508.34,20037508.34 -20037508.34,20037508.34 20037508.34,-20037508.34 20037508.34))"
tf ST_AsText "ST_SnapToGrid(TileBBox(11,585,783),0.01)" \
    "POLYGON((-8590298.99 4715858.9,-8590298.99 4696291.02,-8570731.11 4696291.02,-8570731.11 4715858.9,-8590298.99 4715858.9))"
tf ST_AsText "ST_SnapToGrid(TileBBox(0,0,0,4326),0.01)" \
    "POLYGON((-180 85.05,-180 -85.05,180 -85.05,180 85.05,-180 85.05))"

# ToPoint
tf ToPoint "ST_GeomFromText('POINT(0 0)',900913)" \
    "010100002031BF0D0000000000000000000000000000000000"
tf ToPoint "ST_GeomFromText('POLYGON EMPTY',900913)" "\\N"
tf ToPoint "ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',900913)" \
    "010100002031BF0D0000000000000014400000000000001440"
tf ToPoint "ST_GeomFromText('POLYGON((0 0, 10 0, 0 10, 10 10, 0 0))',900913)" \
    "010100002031BF0D0000000000000014400000000000000440"
tf ToPoint "ST_GeomFromText('MULTIPOLYGON(((0 0, 10 0, 10 10, 0 10, 0 0)))',900913)" \
    "010100002031BF0D0000000000000014400000000000001440"
tf ToPoint "ST_GeomFromText('MULTIPOLYGON(((0 0, 10 0, 10 10, 0 10, 0 0)), ((20 20, 30 20, 30 30, 20 30, 20 20)))',900913)" \
    "010100002031BF0D0000000000000014400000000000001440"
tf ToPoint "ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 20 20, 0 30, 5 15, 0 10, 0 0))',900913)" \
    "010100002031BF0D00ABAAAAAAAAAA25400000000000803140"


# Z
tf Z "1000000000" "\\N"
tf Z "500000000" "0"
tf Z "1000" "19"
tf Z "0" "\\N"
tf Z "NULL" "\\N"

# ZRes
tf ZRes "0" "156543.033928041"
tf ZRes "19" "0.29858214173897"
tf ZRes "0.5" "110692.640838034"
tf ZRes "NULL" "\\N"

if [[ $failcount -eq 0 ]]; then
    echo -n "# ok - "
else
    echo -n "# not ok - "
fi
echo "$passcount / $testtotal tests passed"

exit $failcount
