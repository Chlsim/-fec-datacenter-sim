#!/bin/bash
# Phase 1, steps 2-3: induce congestion/loss, record no-redundancy baseline.
# Flow of interest: 0->13 (same as Phase 0). Background: 1->13, 2->13, 3->13, 4->13
# all converging on node 13 at the same time, with a small queue, to force
# ECMP path contention and NDP trimming/retransmits.
set -euo pipefail
cd "$(dirname "$0")"
SIMPATH=../../htsim/sim/datacenter
PARSE=../../htsim/sim/parse_output

NODES=16
PATHS=4
CWND=50
QUEUESIZE=${1:-15}   # packets; shrink further to push more loss
MTU=4000
END=2000
TM=congested.cm

mkdir -p ../../logs
TAG="q${QUEUESIZE}_paths${PATHS}"
BINLOG=../../logs/phase1_baseline_${TAG}.dat
TXTLOG=../../logs/phase1_baseline_${TAG}.txt

"$SIMPATH/htsim_ndp" \
    -tm "$TM" \
    -nodes $NODES \
    -conns 5 \
    -strat ecmp -paths $PATHS \
    -cwnd $CWND \
    -q $QUEUESIZE \
    -mtu $MTU \
    -end $END \
    -log sink \
    -o "$BINLOG" \
    > "$TXTLOG" 2>&1

echo "=== stdout log: $TXTLOG ==="
echo '--- per-flow completion (FCT) ---'
grep 'finished' "$TXTLOG" || echo '(no flow finished within -end window)'
echo '--- loss/retransmit summary (aggregate) ---'
grep 'Bounced:' "$TXTLOG"
echo '--- per-path stats (New/Rtx/Rto per path, per flow) ---'
grep -A2 '^ndpsrc' "$TXTLOG"
echo
echo "=== binary log: $BINLOG ==="
"$PARSE" "$BINLOG" -ndp -show
