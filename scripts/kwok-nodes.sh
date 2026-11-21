#!/usr/bin/env bash
# Usage: scripts/kwok-nodes.sh apply|delete [count]
set -euo pipefail
ACTION=${1:-apply}; COUNT=${2:-20}
for i in $(seq 0 $((COUNT-1))); do
  sed "s/NODE_NAME/kwok-gpu-$i/g" cluster/kwok-node.tmpl.yaml
  echo "---"
done | kubectl "$ACTION" -f -
