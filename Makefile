CLUSTER := gpu-sim

cluster-up:
	kind create cluster --config cluster/kind-config.yaml

cluster-down:
	kind delete cluster --name $(CLUSTER)

status:
	kubectl get nodes -o wide
	kubectl get pods -A
