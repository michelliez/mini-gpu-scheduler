CLUSTER := gpu-sim

cluster-up:
	kind create cluster --config cluster/kind-config.yaml

cluster-down:
	kind delete cluster --name $(CLUSTER)

status:
	kubectl get nodes -o wide
	kubectl get pods -A

KWOK_VERSION := v0.8.0

kwok-install:
	kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/$(KWOK_VERSION)/kwok.yaml
	kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/$(KWOK_VERSION)/stage-fast.yaml

gpu-nodes-up:
	scripts/kwok-nodes.sh apply 20

gpu-nodes-down:
	scripts/kwok-nodes.sh delete 20

gpus:
	kubectl get nodes -l type=kwok -o custom-columns=NODE:.metadata.name,GPU:.status.allocatable.nvidia\\.com/gpu
