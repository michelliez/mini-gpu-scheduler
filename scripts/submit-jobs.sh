#!/usr/bin/env bash
# Usage: scripts/submit-jobs.sh <team-a|team-b> [count]
set -euo pipefail
TEAM=$1; COUNT=${2:-20}
SIZES=(1 2 4 4 8)
for i in $(seq 1 "$COUNT"); do
  GPUS=${SIZES[$((RANDOM % ${#SIZES[@]}))]}
  RUNTIME="$((30 + RANDOM % 61))s"
  sed -e "s/TEAM/$TEAM/g" -e "s/GPUS/$GPUS/" -e "s/RUNTIME/$RUNTIME/" kueue/job.tmpl.yaml
  echo "---"
done | kubectl create -f -
