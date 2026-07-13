# Iteration 062 action

- Track the maximum observed node/candidate depth during workspace scans.
- Reject every candidate whose depth exceeds `max_depth`, including files that are not queued for traversal.
- Add deterministic stress regressions for truthful observed depth and file-depth fail-closed behavior.
- Refresh release-count and hardening documentation, then run the full local and Docker-backed gates.
