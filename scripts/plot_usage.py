# /// script
# requires-python = ">=3.10"
# dependencies = ["pandas", "matplotlib"]
# ///
"""Plot GPUs in use per team over time from results/raw/usage.csv.

The CSV is written by scripts/watch-queues.sh (one row every ~2 s).
"Borrowed" GPUs are ones a team uses beyond its own nominalQuota (80),
lent from the other team's unused quota via the shared Kueue cohort.
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # render to file, no GUI window
import matplotlib.pyplot as plt
import pandas as pd

CSV_IN = Path("results/raw/usage.csv")
PNG_OUT = Path("docs/img/gpu_usage.png")
CAPACITY = 160  # 20 KWOK nodes x 8 GPUs
QUOTA = 80  # nominalQuota per team in kueue/cluster-queues.yaml

df = pd.read_csv(CSV_IN, parse_dates=["timestamp"])
# Seconds since the first sample read better than wall-clock times.
elapsed = (df.timestamp - df.timestamp.iloc[0]).dt.total_seconds()

fig, ax = plt.subplots(figsize=(8, 4.5))
ax.stackplot(elapsed, df.team_a_gpus, df.team_b_gpus,
             labels=["team-a", "team-b"], colors=["#2a78d6", "#e8862a"], alpha=0.8)
ax.axhline(CAPACITY, color="black", linestyle="--", linewidth=1)
ax.axhline(QUOTA, color="gray", linestyle="--", linewidth=1)
# Label the lines directly at the left edge instead of in the legend.
box = {"facecolor": "white", "edgecolor": "none", "pad": 1}  # keeps text readable over the fill
ax.text(0, CAPACITY + 2, "cluster capacity", va="bottom", fontsize=9, bbox=box)
ax.text(0, QUOTA + 2, "per-team quota", va="bottom", fontsize=9, bbox=box)

ax.set_ylim(0, CAPACITY * 1.12)
ax.set_xlabel("Time since start (seconds)")
ax.set_ylabel("GPUs in use")
ax.set_title("GPU usage by team", loc="left")
ax.legend(loc="lower right", bbox_to_anchor=(1, 1), ncol=2, frameon=False)  # above the plot
ax.grid(axis="y", alpha=0.3)

PNG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.tight_layout()
fig.savefig(PNG_OUT, dpi=150)
print(f"wrote {PNG_OUT} from {len(df)} samples")
