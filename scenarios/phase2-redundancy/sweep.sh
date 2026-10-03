#!/bin/bash
# Sweep independent per-packet loss rate (-plr), tail_redundancy off vs on,
# mirroring the committee deck's "packet stall probability" methodology.
set -euo pipefail
cd "$(dirname "$0")"
SIMPATH=../../htsim/sim/datacenter
TR=${1:-8}

for plr in 0.001 0.005 0.01 0.02 0.05; do
    for tr in 0 $TR; do
        echo "=== plr=$plr tail_redundancy=$tr ==="
        "$SIMPATH/htsim_ndp" -tm perm16.cm -nodes 16 -conns 16 -strat ecmp -paths 4 \
            -cwnd 50 -q 200 -mtu 4000 -end 5000 -queue_type random -plr $plr \
            -seed 1 -tail_redundancy $tr -log sink 2>&1 \
            | awk '/^Flow/ && !seen[$2]++ {print} /Bounced:/ {print}'
    done
done
