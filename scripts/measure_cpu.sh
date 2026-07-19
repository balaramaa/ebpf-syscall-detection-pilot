#!/usr/bin/env bash
#
# measure_cpu.sh
#
# Measures overall system CPU utilization over a given duration by
# sampling /proc/stat before and after. Run this once with the eBPF
# monitor OFF, and once with it ON, to get a real overhead delta.
#
# Usage: ./measure_cpu.sh [duration_seconds]
# Default duration: 300 (5 minutes)

DURATION=${1:-300}

read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ _ < /proc/stat
total1=$((user1+nice1+system1+idle1+iowait1+irq1+softirq1+steal1))

echo "Sampling CPU for ${DURATION}s..."
sleep "$DURATION"

read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ _ < /proc/stat
total2=$((user2+nice2+system2+idle2+iowait2+irq2+softirq2+steal2))

idle_delta=$((idle2 - idle1))
total_delta=$((total2 - total1))

usage=$(awk -v idle="$idle_delta" -v total="$total_delta" 'BEGIN { printf "%.2f", (1 - idle/total) * 100 }')

echo "CPU usage over ${DURATION}s: ${usage}%"
