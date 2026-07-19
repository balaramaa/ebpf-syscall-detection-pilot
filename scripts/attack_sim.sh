#!/usr/bin/env bash
#
# attack_sim.sh
#
# Purpose: A SAFE, self-contained, scripted "attack" scenario you can run
# repeatedly in a test container to generate a real, reproducible signal
# for the threat-detection latency experiment (RQ1). This does not
# perform any actual exploitation - it only triggers the KIND of kernel
# behaviour a privilege-escalation / abnormal-syscall attempt produces
# (rapid setuid/capability syscalls, ptrace attempts, unusual mounts),
# so your eBPF probes have something legitimate to detect.
#
# Usage:
#   1. Run this INSIDE a disposable test container, never on a
#      production or shared host.
#   2. Start syscall_monitor.bt in one terminal first.
#   3. Note the wall-clock time you run this script (T_attack_start).
#   4. Note the wall-clock time your monitor first flags the anomaly
#      (T_alert). Detection latency = T_alert - T_attack_start.
#
# Run this 5-10 times to get a real distribution of detection latency,
# not a single number.

set -e

echo "[attack_sim] Start uptime: $(awk '{print $1}' /proc/uptime)"

# 1. Rapid privilege-transition syscalls (setuid/setgid churn)
for i in $(seq 1 50); do
    id -u >/dev/null 2>&1 || true
done

# 2. ptrace attempt (common in credential/process injection attacks)
# Requires a target PID; here we attach briefly to our own shell's
# child as a harmless stand-in signal.
( sleep 0.2 && echo "dummy" ) &
CHILD_PID=$!
strace -p "$CHILD_PID" -e trace=none -c -o /dev/null &
STRACE_PID=$!
sleep 0.3
kill "$STRACE_PID" 2>/dev/null || true
wait "$CHILD_PID" 2>/dev/null || true

# 3. Unusual mount/namespace syscalls (container-escape-style signal)
unshare --map-root-user --user echo "namespace probe" >/dev/null 2>&1 || true

# 4. Burst of syscalls in a short window (anomalous frequency signal)
for i in $(seq 1 500); do
    /bin/true
done

echo "[attack_sim] End uptime: $(awk '{print $1}' /proc/uptime)"
