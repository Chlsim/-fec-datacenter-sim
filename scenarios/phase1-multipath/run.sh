#!/bin/bash
# Phase 1 — multipath baseline (no redundancy).
# Single flow over a 16-node k=4 fat-tree, spread across N ECMP paths.
# Validated 2026-10-03: 0 retransmits at PATHS=4, QUEUESIZE=200 (no congestion).
set -euo pipefail

cd "$(dirname "$0")"
SIMPATH=../../htsim/sim/datacenter
PARSE=../../htsim/sim/parse_output

NODES=16
PATHS=4
CWND=50
QUEUESIZE=200          # packets — shrink this to induce congestion/loss (step 2 of Phase 1)
MTU=4000
END=100                # usec
TM=$SIMPATH/connection_matrices/one.cm

mkdir -p ../../logs
LOGFILE=../../logs/phase1_paths${PATHS}_q${QUEUESIZE}.dat

"$SIMPATH/htsim_ndp" \
    -tm "$TM" \
    -nodes $NODES \
    -conns 1 \
    -strat ecmp -paths $PATHS \
    -cwnd $CWND \
    -q $QUEUESIZE \
    -mtu $MTU \
    -end $END \
    -log sink \
    -o "$LOGFILE"

echo "Log: $LOGFILE"
"$PARSE" "$LOGFILE" -ndp -show
