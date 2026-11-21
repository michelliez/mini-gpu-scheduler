# /// script
# requires-python = ">=3.10"
# dependencies = ["pandas", "matplotlib"]
# ///
"""Collect Kueue queue wait times per team and plot them.

A Kueue *Workload* is the object Kueue creates for each submitted Job; it tracks
whether the job has been given quota ("QuotaReserved") or kicked out ("Evicted").
Wait time = when quota was reserved minus when the Workload was created.
Read-only: this only runs `kubectl get`.
"""
import json
import subprocess
from datetime import datetime
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # render to file, no GUI window
import matplotlib.pyplot as plt
import pandas as pd

TEAMS = ["team-a", "team-b"]
CSV_OUT = Path("results/wait_times.csv")
PNG_OUT = Path("docs/img/queue_wait_times.png")
COLORS = {"team-a": "#2a78d6", "team-b": "#e8862a"}


def ts(s: str) -> datetime:
    # Kubernetes timestamps look like 2026-11-21T10:00:00Z
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def gpu_request(workload: dict) -> int:
    # Sum nvidia.com/gpu requests over the containers of the first pod set.
    containers = workload["spec"]["podSets"][0]["template"]["spec"]["containers"]
    return sum(int(c.get("resources", {}).get("requests", {}).get("nvidia.com/gpu", 0))
               for c in containers)


rows = []
for ns in TEAMS:
    out = subprocess.run(
        ["kubectl", "get", "workloads.v1beta2.kueue.x-k8s.io", "-n", ns, "-o", "json"],
        check=True, capture_output=True, text=True,
    ).stdout
    for wl in json.loads(out)["items"]:
        conds = wl.get("status", {}).get("conditions", [])
        admitted = next((c for c in conds
                         if c["type"] == "QuotaReserved" and c["status"] == "True"), None)
        if admitted is None:
            continue  # still waiting in the queue; no wait time yet
        wait = ts(admitted["lastTransitionTime"]) - ts(wl["metadata"]["creationTimestamp"])
        rows.append({
            "team": ns,
            "workload": wl["metadata"]["name"],
            "gpus": gpu_request(wl),
            "wait_seconds": wait.total_seconds(),
            "evicted": any(c["type"] == "Evicted" for c in conds),
        })

df = pd.DataFrame(rows, columns=["team", "workload", "gpus", "wait_seconds", "evicted"])
CSV_OUT.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(CSV_OUT, index=False)
print(f"wrote {CSV_OUT} ({len(df)} admitted workloads)")

# Box plot per team, with each workload drawn as a jittered dot on top.
fig, ax = plt.subplots(figsize=(6, 4.5))
for i, team in enumerate(TEAMS, start=1):
    waits = df.loc[df.team == team, "wait_seconds"]
    if waits.empty:
        continue
    ax.boxplot(waits, positions=[i], widths=0.5, showfliers=False,
               medianprops={"color": COLORS[team]})
    jitter = pd.Series(range(len(waits))).mod(7).sub(3).mul(0.04).values
    ax.scatter(i + jitter, waits, s=14, alpha=0.7, color=COLORS[team], label=team)
ax.set_xticks(range(1, len(TEAMS) + 1), TEAMS)
ax.set_xlabel("Team (namespace)")
ax.set_ylabel("Queue wait time (seconds)")
ax.set_title("Queue wait time by team")
ax.grid(axis="y", alpha=0.3)
PNG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.tight_layout()
fig.savefig(PNG_OUT, dpi=150)
print(f"wrote {PNG_OUT}")
