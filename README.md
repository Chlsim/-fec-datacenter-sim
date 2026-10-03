# fec-datacenter-sim

Scenario scripts, configs, and results for the FEC-in-datacenters final project (Oren Ram, Ziv Abraham; advisor Prof. Chen Avin).

Upstream packet-level simulation lives in [htsim](https://github.com/Chlsim/csg-htsim) as a git submodule — a fork of [Broadcom/csg-htsim](https://github.com/Broadcom/csg-htsim). Keeping it as a submodule means HTSim bug fixes/upstream changes stay a clean diff, separate from redundancy-coding patches.

See [docs/gameplan.md](docs/gameplan.md) for the full phased plan.

## Setup

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/Chlsim/-fec-datacenter-sim.git
```

Build htsim (Linux/macOS only — on Windows, use WSL2, and keep the whole repo on the WSL native filesystem, not under /mnt/c/... or any cloud-synced folder, or the build breaks):

```bash
cd htsim/sim
make
make parse_output
```

## Layout

- `htsim/` — HTSim fork (submodule)
- `scenarios/` — per-phase run scripts and configs
- `logs/` — simulation output (gitignored; kept out of version control)
- `docs/` — gameplan and other notes

## Workflow

Feature branch per phase (`phase1-multipath`, `phase2-redundancy`, ...), PR + review between Oren and Ziv before merging to `main`.
