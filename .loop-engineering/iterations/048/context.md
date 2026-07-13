# Context

- Objective: continue the review backlog with the next concrete doctor backend-boundary gap.
- Finding: `doctor.report` executed an arbitrary backend executable for `--backend` values outside Docker/Podman, then performed Docker security inspection; invalid backend selection was not rejected before external process invocation.
- Scope: reject invalid doctor backends before any command execution, add a regression, update evidence, and rerun the full local/Docker/OCI/load/egress gates.
- External boundary: hosted CI remains unavailable because GitHub Actions run `29242575820` was blocked by account billing/spending-limit eligibility.
