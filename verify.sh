#!/usr/bin/env bash

set -eu


NGINX=http://localhost:8080
BLUE=http://localhost:8081
GREEN=http://localhost:8082


# number of quick checks
N=20


echo "== Baseline: expect active pool ${ACTIVE_POOL:-blue} on $NGINX"


# function: hit /version N times and record status + pool header
function probe() {
  local url=$1
  local tries=${2:-$N}
  local out=/tmp/probe-$$.csv
  echo "i,status,pool,release" > "$out"
  for i in $(seq 1 $tries); do
    # use a short curl timeout so we fail fast
    resp=$(curl -sS -m 3 -D - "$url/version" || true)
    # separate headers and body
    status=$(echo "$resp" | awk 'NR==1{print $2}');
    pool=$(echo "$resp" | tr -d '\r' | awk -F': ' '/^X-App-Pool:/{print $2}' | head -n1 || echo "-")
    release=$(echo "$resp" | tr -d '\r' | awk -F': ' '/^X-Release-Id:/{print $2}' | head -n1 || echo "-")
    echo "$i,$status,$pool,$release" >> "$out"
    sleep 0.2
  done
  cat "$out"
}


# Baseline check: ensure all responses are from ACTIVE_POOL and 200
echo "-- Baseline probe"
probe "$NGINX" 10 > /tmp/baseline.csv
awk -F',' 'NR>1{if($2!=200) fail=1; if($3!="'${ACTIVE_POOL:-blue}'") wrong++} END{ if(fail==1){print "NON-200 in baseline"; exit 2} if(wrong>0){print "Unexpected pool in baseline"; exit 3} print "Baseline OK" }' /tmp/baseline.csv


# Start chaos on the active app (grader will target these endpoints)
if [ "${ACTIVE_POOL:-blue}" = "blue" ]; then
CHAOS_BASE=$BLUE
else
CHAOS_BASE=$GREEN
fi


echo "-- Triggering chaos on active ($CHAOS_BASE)"
curl -sS -X POST "$CHAOS_BASE/chaos/start?mode=error" || true


# Immediately probe N times within ~10s
echo "-- Probing after chaos (collecting responses)"
probe "$NGINX" 40 > /tmp/after.csv


# analyze results
total=$(awk 'END{print NR-1}' /tmp/after.csv)
non200=$(awk -F',' 'NR>1{if($2!=200) c++} END{print c+0}' /tmp/after.csv)
green_count=$(awk -F',' 'NR>1{if($3=="green") c++} END{print c+0}' /tmp/after.csv)


echo "total=$total non200=$non200 green=$green_count"


# checks according to task
if [ "$non200" -ne 0 ]; then
echo "FAIL: Non-200 responses observed after chaos"
exit 4
fi


pct_green=$((100 * green_count / total))
if [ $pct_green -lt 95 ]; then
echo "FAIL: only ${pct_green}% responses from green (<95%)"
exit 5
fi


echo "PASS: failover successful — ${pct_green}% responses from green, 0 non-200s"


# stop chaos
echo "-- Stopping chaos"
curl -sS -X POST "$CHAOS_BASE/chaos/stop" || true


exit 0