# Context

- Objective: continue the review backlog with the next concrete coordinator output-boundary gap.
- Finding: `ensure_dir` propagated an uncaught `create_dir` error when an output path already existed as a regular file; coordinator output preparation also ignored directory-creation results, causing a VM crash instead of an early structured failure.
- Scope: make directory creation fail closed, enforce coordinator output-directory checks, add regressions, document the hosted CI billing blocker, and rerun local/Docker/OCI/load/egress gates.
- External boundary: GitHub Actions run `29241222514` was not started because account payments failed or the spending limit must be increased; production deployment controls remain unchanged.
