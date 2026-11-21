CLUSTER := gpu-sim
KWOK_VERSION := v0.8.0
KUEUE_VERSION := v0.20.7

# --- cluster ---------------------------------------------------------------
cluster-up:
	kind create cluster --config cluster/kind-config.yaml

cluster-down:
	kind delete cluster --name $(CLUSTER)

status:
	kubectl get nodes -o wide
	kubectl get pods -A

# --- fake GPU nodes (KWOK) -------------------------------------------------
kwok-install:
	kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/$(KWOK_VERSION)/kwok.yaml
	kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/$(KWOK_VERSION)/stage-fast.yaml

gpu-nodes-up:
	scripts/kwok-nodes.sh apply 20

gpu-nodes-down:
	scripts/kwok-nodes.sh delete 20

gpus:
	kubectl get nodes -l type=kwok -o custom-columns=NODE:.metadata.name,GPU:.status.allocatable.nvidia\\.com/gpu

kwok-runtime:
	kubectl patch stage pod-complete --type=merge --patch-file cluster/kwok-pod-complete-delay.json

# --- Kueue -----------------------------------------------------------------
kueue-install:
	kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/$(KUEUE_VERSION)/manifests.yaml
	kubectl wait deploy/kueue-controller-manager -n kueue-system --for=condition=available --timeout=300s

queues-up:
	kubectl apply -f kueue/flavor.yaml -f kueue/cluster-queues.yaml -f kueue/teams.yaml

watch:
	scripts/watch-queues.sh

clean-jobs:
	kubectl delete jobs --all -n team-a
	kubectl delete jobs --all -n team-b

# --- results & charts ------------------------------------------------------
waits:
	uv run scripts/collect_waits.py

usage-chart:
	uv run scripts/plot_usage.py

# None of these targets produce a file with the target's name.
.PHONY: cluster-up cluster-down status kwok-install gpu-nodes-up gpu-nodes-down gpus \
	kwok-runtime kueue-install queues-up watch clean-jobs waits usage-chart
