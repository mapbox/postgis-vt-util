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
tf clean_int "'9999999999'"     "\\N"  # out of range, returns null

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

# summary:
echo -e "$passcount tests passed | $failcount tests failed"

exit $failcount
