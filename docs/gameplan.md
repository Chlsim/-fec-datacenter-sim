# HTSim — Gameplan & Setup

Oct 3, 2026 · @oren ram

## Gameplan — basic multipath + redundancy scenario

Validate packet-level multipath delivery and redundancy coding in standalone HTSim before wiring in ASTRA-sim collectives.

**Phase 0 — topology**

- Small fat-tree (k=4) or leaf-spine, 2–4 ECMP paths between a sender/receiver pair
- One flow, fixed size, no loss injected yet — confirms the setup runs

**Phase 1 — multipath baseline (no redundancy)**

1. Run `htsim_ndp` with `-strat ecmp -paths 4`
2. Induce congestion/loss (small queue, background flows)
3. Record baseline: FCT, per-path throughput, loss/retransmit rate

**Phase 2 — add redundancy**

1. Add XOR/systematic coding at the packet layer, striped across the same multipath routes
2. Re-run identical loss/congestion conditions from Phase 1
3. Compare against Phase 1 baseline (same metrics)

**Phase 3 — stress + tail focus**

1. Sweep loss rate / induce a path failure
2. Measure FCT99 before vs. after redundancy
3. Check the two open design questions from Chen's draft: does the extra redundancy traffic push congestion collapse at high loss rates; what redundancy level fits a SmartNIC memory budget

**Phase 4 — out of scope for now** Hook into ASTRA-sim via the InfraGraph translator once Phases 1–3 hold up.

## Install — HTSim setup

Use the actively maintained fork, **[Broadcom/csg-htsim](https://github.com/Broadcom/csg-htsim)** — the original academic repo (nets-cs-pub-ro/NDP) is the historical NDP-paper version, not the one to build on.

**Prerequisites:** g++ or clang, `make`, python3, bash, gnuplot (for result plots). No external library dependencies — pure C++.

**Windows:** no native build — htsim only compiles with g++/clang on Linux/macOS. Use WSL2 (done — see repo setup below for where things actually live).

Build:

```bash
cd htsim/sim
make
make parse_output
```

Produces `libhtsim.a`, the datacenter transport executables (`htsim_ndp`, `htsim_tcp`, `htsim_roce`, `htsim_swift`, `htsim_eqds`), and `sim/parse_output` (note: parser binary lands in `sim/`, not its parent — the original doc's path was off by one level).

Smoke test (validated 2026-10-03 — 16-node fat-tree, 1 flow, ECMP across 4 paths, 0 retransmits):

```bash
cd htsim/sim/datacenter
./htsim_ndp -tm connection_matrices/one.cm -nodes 16 -conns 1 -strat ecmp -paths 4 -cwnd 50 -q 200 -mtu 4000 -end 100 -log sink
../../parse_output logout.dat -ndp -show
```

Real flag names differ from the original draft: it's `-strat ecmp -paths N` (or `-strat ecmp_host N`, `-strat ecmp_ar`, `-strat perm`), not `-ecmp -paths 4`. Run `./htsim_ndp` with no args to print full usage.

## Repo setup — GitHub (Oren + Ziv)

Upstream HTSim kept separate from redundancy-coding work, so future HTSim fixes can still be pulled cleanly.

- Fork: [Chlsim/csg-htsim](https://github.com/Chlsim/csg-htsim) — redundancy/FEC patches land here, as a diff against upstream `Broadcom/csg-htsim`.
- Outer repo: [Chlsim/-fec-datacenter-sim](https://github.com/Chlsim/-fec-datacenter-sim) — scenario scripts, configs, result logs, this gameplan. The fork above is wired in as a git submodule at `htsim/`.
- Both live under `~/dev/fec-datacenter-sim` inside WSL2 Ubuntu's native filesystem (NOT under `/mnt/c/...` or any iCloud-synced path) — cross-filesystem builds broke before this move.
- TODO: add Ziv as a collaborator on both the fork and the outer repo.
- Workflow: a feature branch per phase (`phase1-multipath`, `phase2-redundancy`, ...), PR + review between the two of you before merging to `main`.
