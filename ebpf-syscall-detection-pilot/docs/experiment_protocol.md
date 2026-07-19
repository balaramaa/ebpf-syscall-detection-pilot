# Experiment Protocol (Scoped Pilot Study)

This protocol replaces the original 4-RQ, full-framework evaluation with
a **narrower, fully real, reproducible pilot study**. It is scoped to
what one person can genuinely execute in a short timeframe, while still
producing legitimate empirical evidence for a JSS submission.

## Scope

We evaluate two things, both measurable with the scripts in this repo:

- **RQ1 (narrowed):** Does kernel-level (eBPF) monitoring detect a
  scripted privilege-escalation-style syscall pattern faster than a
  user-space polling baseline?
- **RQ3 (narrowed):** What is the measurable CPU/latency overhead of
  running the eBPF probes continuously, compared to no monitoring?

RQ2 (bottleneck attribution) and RQ4 (scalability across many services)
are honestly reported as **future work** unless you have time/hardware
to run a multi-container scale test — happy to extend the scripts if so.

## Environment setup (do this once)

1. A Linux host or VM with a kernel ≥ 5.x, `bpftrace` installed
   (`apt install bpftrace` on Debian/Ubuntu).
2. Docker or Podman installed for the test containers.
3. Record and save exactly: kernel version (`uname -r`), distro,
   CPU/core count, RAM. This goes in your paper's "Experimental
   Environment" section — real values, not placeholders.

## Step 1 — Baseline (benign) syscall behaviour

1. Start a disposable test container: `docker run -it --rm ubuntu:22.04 bash`
2. On the host, run: `sudo bpftrace scripts/syscall_monitor.bt > data/baseline_syscalls.csv`
3. Inside the container, run a normal light workload for 2 minutes
   (e.g., a simple script making HTTP requests, or just idle).
4. Stop the monitor (Ctrl-C). This is your baseline distribution.

## Step 2 — Attack scenario + detection latency

1. Start the monitor again: `sudo bpftrace scripts/syscall_monitor.bt > data/attack_syscalls.csv`
2. In a second terminal, note the exact time, then run:
   `./scripts/attack_sim.sh` inside the same test container.
3. Manually inspect `attack_syscalls.csv` for the timestamp where
   privileged_count spikes above the baseline's normal range
   (compute this threshold from Step 1's data — e.g., mean + 3×stdev).
4. Detection latency = (spike timestamp) − (attack_sim.sh start timestamp).
5. **Repeat 10 times.** Record all 10 latencies in
   `data/results_template.csv`. Report mean, median, and range — not
   a single cherry-picked number.

## Step 3 — User-space baseline comparison

1. Find the PID of your test process: `docker inspect -f '{{.State.Pid}}' <container>`
2. Run: `./scripts/baseline_userspace.sh <pid> > data/baseline_userspace.csv`
3. Repeat the same attack scenario and estimate how long it takes
   the CPU-only signal to visibly deviate (if at all). Often the
   honest finding is that the user-space proxy signal is noisy or
   doesn't clearly flag the event — that's a legitimate, reportable
   result, not a failure.

## Step 4 — Overhead measurement

1. Run your test workload for 5 minutes with `syscall_monitor.bt`
   OFF. Record average CPU utilization (`top -b -n 300 -d 1`) and
   any relevant latency of your workload.
2. Repeat with `syscall_monitor.bt` ON.
3. Compute the real delta. Report it honestly — even if it's higher
   than the original draft claimed (<5%). A slightly higher but real
   number is far better for the paper than a fabricated low one.

## Step 5 — Writing it up

Once `data/results_template.csv` is filled in with real numbers:
- Send it back and I'll rewrite Section 7 (Results) around your
  actual data, with correct statistics (mean/median/CI, not just a
  single point estimate).
- We'll also revise the abstract, contributions, and limitations to
  match the narrower, honest scope — this is normal for a pilot
  study and reviewers respect it far more than overclaiming.

## What to keep notes on as you go

- Anything that *didn't* work as expected (e.g., false alarms,
  probes that didn't fire) — this becomes real content for your
  Threats to Validity / Limitations section, and reviewers trust
  papers more when limitations are specific rather than boilerplate.
