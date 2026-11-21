#!/usr/bin/env bash
# Live view of each team's queue and GPU usage. Ctrl-C to stop.
# Each loop also appends one row to results/raw/usage.csv for scripts/plot_usage.py.
CSV=results/raw/usage.csv
HEADER="timestamp,team_a_gpus,team_a_borrowed,team_b_gpus,team_b_borrowed"

# (Re)create the CSV header if the file is missing or doesn't start with it.
# Called every loop so deleting the file mid-run doesn't lose the header.
ensure_header() {
  mkdir -p "$(dirname "$CSV")"
  if [ ! -s "$CSV" ]; then
    echo "$HEADER" > "$CSV"
  elif [ "$(head -n 1 "$CSV")" != "$HEADER" ]; then
    { echo "$HEADER"; cat "$CSV"; } > "$CSV.tmp" && mv "$CSV.tmp" "$CSV"
  fi
}

# Print "<total> <borrowed>" GPUs for one ClusterQueue (0 if Kueue hasn't reported yet).
gpu_usage() {
  local gpu='.status.flavorsUsage[0].resources[?(@.name=="nvidia.com/gpu")]'
  local out
  out=$(kubectl get cq "$1" -o jsonpath="{$gpu.total} {$gpu.borrowed}")
  read -r total borrowed <<< "$out"
  echo "${total:-0} ${borrowed:-0}"
}

while true; do
  clear
  date +%T
  kubectl get clusterqueues -o custom-columns=QUEUE:.metadata.name,PENDING:.status.pendingWorkloads,ADMITTED:.status.admittedWorkloads
  echo
  read -r a_total a_borrowed <<< "$(gpu_usage team-a-cq)"
  read -r b_total b_borrowed <<< "$(gpu_usage team-b-cq)"
  echo "team-a-cq  GPUs in use: $a_total  (borrowed: $a_borrowed)"
  echo "team-b-cq  GPUs in use: $b_total  (borrowed: $b_borrowed)"
  ensure_header
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),$a_total,$a_borrowed,$b_total,$b_borrowed" >> "$CSV"
  sleep 2
done
