#!/usr/bin/env bash
set -e -u -o pipefail

passcount=0
failcount=0

pgdb=testing_postgis_vt_util
psql="psql -q -U postgres"
psqld="$psql -d $pgdb"
$psql -c "drop database $pgdb" || true
$psql -c "create database $pgdb"
$psqld -c "create extension if not exists postgis"
$psqld -f "$(dirname "$0")/../postgis-vt-util.sql"

function tf() {
    # tf (test a function)
    # Usage: tf function_name argument expected-output
    result=$($psqld -c "COPY (SELECT $1($2)) TO STDOUT;")
    if [[ "$result" == "$3" ]]; then
        echo -e "✔ $2 ⇒ '$result' "
        passcount=$((passcount+1))
    else
        echo -e "✘ $2 ⇒ '$result' "
        echo "  ⤷ expected: '$3'"
        failcount=$((failcount+1))
    fi
}

echo -e "testing CleanInt:"
tf CleanInt "'123'"            "123"
tf CleanInt "'foobar'"         "\\N"
tf CleanInt "'2147483647'"     "2147483647"  # largest possible int
tf CleanInt "'-2147483648'"    "-2147483648"  # smallest possible int
tf CleanInt "'9999999999'"     "\\N"  # out of range, returns null
tf CleanInt "'123.456'"        "123"  # round down
tf CleanInt "'456.789'"        "457"  # round up

echo -e "testing CleanNumeric:"
tf CleanNumeric "'123'"            "123"
tf CleanNumeric "'foobar'"         "\\N"
tf CleanNumeric "'123.456'"        "123.456"
tf CleanNumeric "'456.789'"        "456.789"

echo -e "testing Z:"
tf Z "1000000000" "\\N"
tf Z "500000000" "0"
tf Z "1000" "19"

echo -e "testing ZRes:"
tf ZRes "0" "156543.033928041"
tf ZRes "19" "0.29858214173897"

echo -e "testing LineLabel:"
tf LineLabel "14, 'Foobar', ST_GeomFromText('POINT(0 0)',900913)" "t"
tf LineLabel "14, 'Foobar', ST_GeomFromText('LINESTRING(0 0, 0 300)',900913)" "f"
tf LineLabel "15, 'Foobar', ST_GeomFromText('LINESTRING(0 0, 0 300)',900913)" "t"

echo -e "testing LabelGrid:"
tf LabelGrid "ST_GeomFromText('POINT(100 -100)',900913), 64*9.5546285343" \
    "POINT(305.7481130976 -305.7481130976)"

echo -e "testing ToPoint:"
tf ToPoint "ST_GeomFromText('POINT(0 0)',900913)" \
    "010100002031BF0D0000000000000000000000000000000000"
tf ToPoint "ST_GeomFromText('POLYGON EMPTY',900913)" "\\N"
tf ToPoint "ST_GeomFromText('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',900913)" \
    "010100002031BF0D0000000000000014400000000000001440"
tf ToPoint "ST_GeomFromText('POLYGON((0 0, 10 0, 0 10, 10 10, 0 0))',900913)" \
    "010100002031BF0D0000000000000014400000000000000440"

echo -e "testing MercBuffer:"
tf floor "ST_Area(MercBuffer(ST_GeomFromText('LINESTRING(0 0, 1000 1000)', 900913), 500))" \
    "2194574"
tf floor "ST_Area(MercBuffer(ST_GeomFromText('POINT(0 8500000)', 900913), 500))" \
    "3207797"

echo -e "testing MercDWithin:"
tf MercDWithin "ST_GeomFromText('POINT(0 0)',3857), ST_GeomFromText('POINT(60 0)',3857), 50.0" \
    "f"
tf MercDWithin "ST_GeomFromText('POINT(0 8500000)',3857), ST_GeomFromText('POINT(60 8500000)',3857), 50.0" \
    "t"

echo -e "testing MercLength:"
tf MercLength "ST_GeomFromText('LINESTRING(0 0, 10000 0)', 900913)" \
    "10000"
tf MercLength "ST_GeomFromText('LINESTRING(0 8500000, 10000 8500000)', 900913)" \
    "4932.24215371697"

echo -e "testing TileBBox:"
tf ST_AsText "ST_SnapToGrid(TileBBox(0,0,0),0.01)" \
    "POLYGON((-20037508.34 20037508.34,-20037508.34 -20037508.34,20037508.34 -20037508.34,20037508.34 20037508.34,-20037508.34 20037508.34))"
tf ST_AsText "ST_SnapToGrid(TileBBox(11,585,783),0.01)" \
    "POLYGON((-8590298.99 4715858.9,-8590298.99 4696291.02,-8570731.11 4696291.02,-8570731.11 4715858.9,-8590298.99 4715858.9))"

# summary:
echo -e "$passcount tests passed | $failcount tests failed"

exit $failcount
