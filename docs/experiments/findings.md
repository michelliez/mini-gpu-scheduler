# Kueue experiment findings

Setup: 20 KWOK nodes x 8 GPUs = 160 GPUs. Two ClusterQueues (80 GPU nominal each) in one cohort, borrowingLimit 80, reclaimWithinCohort: Any. Team A submits 60 jobs, team B submits 30 jobs 15s later. Job sizes 1/2/4/8 GPUs, runtimes 30-90s.

- Cluster stayed at ~160/160 GPUs while both teams had work.
- Team A borrowed up to 80 GPUs while team B was idle, was reclaimed back to its 80-GPU quota within ~20s of team B arriving, and borrowed again once team B's queue drained.
- Median queue wait: team A ~39s, team B ~12s. Team B's guarantee let it reclaim GPUs immediately despite arriving later.
- Caveat: wait time is measured to the latest admission, so preempted-and-requeued jobs inflate team A's tail.
