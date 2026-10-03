#!/bin/bash
# Phase 2 — basic tail-FEC showcase (per Chen's draft: "Tail-Targeted
# Gentle Aggression"). Compares FCT with -tail_redundancy off vs on,
# same loss/congestion conditions.
#
# Mechanism: a degenerate r=1-of-k repetition code, NOT real XOR/MDS
# coding. The last K packets of each flow are each sent twice, on two
# different ECMP paths. NDP's existing cumulative-ack logic already
# no-ops a duplicate sequence number, so whichever copy (original or
# duplicate) arrives first silently advances the flow -- no receiver
# change was needed. See ndp.cpp's NdpSrc send-loop for the patch.
#
# Traffic: a 16-node permutation (1 flow per node, distinct src/dst
# pairs) rather than Phase 1's incast-into-one-node pattern. Incast
# congestion happens at the final hop, AFTER ECMP paths reconverge --
# duplicating across paths can't help there. A permutation spreads
# congestion across the CORE links where paths actually diverge.
set -euo pipefail
cd "$(dirname "$0")"
SIMPATH=../../htsim/sim/datacenter
PARSE=../../htsim/sim/parse_output

NODES=16
PATHS=4
CWND=50
QUEUESIZE=${1:-15}
MTU=4000
END=2000
TAIL_PKTS=${2:-8}
TM=perm16.cm

mkdir -p ../../logs

run_one() {
    local tr=$1
    local tag=$2
    local txtlog=../../logs/phase2_${tag}.txt
    "$SIMPATH/htsim_ndp" \
        -tm "$TM" -nodes $NODES -conns 16 -strat ecmp -paths $PATHS \
        -cwnd $CWND -q $QUEUESIZE -mtu $MTU -end $END -seed 1 \
        -tail_redundancy $tr -log sink \
        -o ../../logs/phase2_${tag}.dat \
        > "$txtlog" 2>&1
    echo "--- $tag (tail_redundancy=$tr) ---"
    # a flow can print "finished" more than once (a duplicate/redundant
    # packet arriving after completion still triggers an ACK carrying
    # cum_ackno >= flow_size) -- first occurrence per flow is the real FCT.
    awk '/^Flow/ && !seen[$2]++' "$txtlog" | sort -k7 -n
    echo
    grep 'Bounced:' "$txtlog"
    echo
}

run_one 0 baseline
run_one $TAIL_PKTS redundant
