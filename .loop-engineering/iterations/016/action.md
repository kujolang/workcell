# Action

- Added `tests/load_integration.sh` with a bounded 2–16 run matrix and versioned `workcell-load-evidence/v1` output.
- Verified concurrent runs share one clean source repository and output root while preserving unique run IDs, artifacts, manifests, source immutability, workspaces, and containers.
- Ran the load contract on rootful Docker and rootless Docker/Podman in the Colima Linux VM.
- Added `tests/quality.sh` and wired format, lint, shell syntax, and diff checks into the default suite and CI.
- Updated compatibility, security, build, development, README, and review-backlog records.
