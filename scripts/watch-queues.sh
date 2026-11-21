#!/usr/bin/env bash
# Live view of each team's queue and GPU usage. Ctrl-C to stop.
while true; do
  clear
  date +%T
  kubectl get clusterqueues -o custom-columns=QUEUE:.metadata.name,PENDING:.status.pendingWorkloads,ADMITTED:.status.admittedWorkloads
  echo
  for cq in team-a-cq team-b-cq; do
    kubectl get cq "$cq" -o jsonpath='{.metadata.name}{"  GPUs in use: "}{.status.flavorsUsage[0].resources[?(@.name=="nvidia.com/gpu")].total}{"  (borrowed: "}{.status.flavorsUsage[0].resources[?(@.name=="nvidia.com/gpu")].borrowed}{")"}{"\n"}'
  done
  sleep 2
done
