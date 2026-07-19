# eBPF Privileged-Syscall Detection: A Pilot Study

This repository contains the scripts and raw experimental data supporting
the paper *"Sub-Second Detection of Privileged-Syscall Anomalies via eBPF:
A Pilot Empirical Study in a Containerized RHEL Environment"* (submitted
to the Journal of Systems and Software).

## What this is

A small, honest, fully-reproducible pilot study measuring two things
about an eBPF-based syscall monitor on a single RHEL 10.2 host:

1. **Detection latency** — how quickly the monitor surfaces a scripted
   privileged-syscall sequence (setuid/ptrace/unshare-style behaviour).
2. **CPU overhead** — how much continuous instrumentation costs at idle.

This is **not** a production security tool and **not** a full framework
evaluation. See the paper's Limitations section (Section 8) for an
explicit list of what this study does and does not claim.

## Repository structure

```
scripts/
  syscall_monitor_ms.bt   - bpftrace monitor, 100ms resolution (used for all reported results)
  sched_latency.bt        - scheduling-latency probe (implemented, NOT evaluated - future work)
  attack_sim.sh           - safe, scripted stand-in for privileged-syscall behaviour
  measure_cpu.sh          - /proc/stat-based CPU utilization sampler

data/
  detection_latency_results.csv  - raw data for all 10 detection trials (Table 1 in the paper)
  cpu_overhead_results.csv       - raw data for all 6 overhead trials (Table 2 in the paper)

docs/
  experiment_protocol.md  - full step-by-step reproduction protocol
```

## Environment used for the reported results

| Parameter | Value |
|---|---|
| Host OS | Red Hat Enterprise Linux 10.2 ("Coughlan") |
| Kernel | 6.12.0-211.34.1.el10_2.x86_64 |
| vCPUs | 2 |
| RAM | ~1.6 GiB (VMware Workstation guest) |
| Instrumentation | bpftrace v0.24.2 |
| Container runtime | Podman, image `registry.access.redhat.com/ubi9/ubi` |

## Quick start (reproduce detection latency)

```bash
# Terminal 1
sudo bpftrace scripts/syscall_monitor_ms.bt > data/my_run_1.csv &

# Terminal 2 (a few seconds later)
bash scripts/attack_sim.sh

# Stop the monitor after the script finishes
sudo pkill bpftrace

# Inspect: find the T= timestamp where a priv_count entry first appears,
# subtract attack_sim.sh's "Start uptime" line to get latency.
grep -B1 "priv_count" data/my_run_1.csv | grep "^T="
```

Repeat 10 times for a real distribution — see `docs/experiment_protocol.md`
for the full step-by-step version, including the CPU overhead measurement
procedure.

## Results summary (from data/ in this repo)

**Detection latency (n=10):** mean 267.4 ms, median 260.5 ms, SD 24.0 ms,
range 245–331 ms.

**CPU overhead (n=3 per condition):** baseline mean 1.23%, instrumented
mean 1.57% — an absolute increase of 0.34 percentage points at idle.

Full analysis and discussion are in the paper.

## Requirements

- Linux with a kernel supporting BPF tracepoints (tested on 6.12.x)
- [bpftrace](https://github.com/bpftrace/bpftrace) (tested with v0.24.2)
- `strace`, `unshare` (from `util-linux`) — present on most distributions
- Podman or Docker (only needed if you want to run the workload inside a
  container; the monitor itself observes host-wide syscalls)

## License

MIT — see LICENSE.

## Citation

If you use this code or data, please cite the accompanying paper (full
citation to be added once published/assigned a DOI).
