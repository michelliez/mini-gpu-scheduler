# Mini GPU Scheduler on Kubernetes
Laptop-only project: kind cluster + KWOK fake GPU nodes (nvidia.com/gpu), Kueue quotas
for two teams, CPU model serving with HPA + Locust load tests, PyTorch DDP (gloo) on CPU.

## Rules
- One folder per component: cluster/, kueue/, serving/, loadtest/, training/, scripts/.
- All K8s manifests are YAML files in the repo, never ad-hoc kubectl edits.
- Every workflow gets a Makefile target (e.g. `make cluster-up`).
- Python via uv; keep scripts small and commented — the author is learning K8s.
- Benchmark outputs go to results/, charts to docs/img/.
- Explain any new Kubernetes concept in 1–2 sentences when you introduce it.
