# Iteration 059 action

- Made `inspect` return structured failure output and exit code 3 when policy construction cannot resolve host identity.
- Rejected unexpected positionals for explicit and global help/version paths.
- Added verification startup cleanup attempts with idempotent no-such-container handling and recorded cleanup status.
- Expanded host-control environment denial for Docker/Podman selectors, cloud credential selectors, Kubernetes connection variables, Git configuration overrides, and package/CI credential variables.
- Added fake-`id`, fake-Podman, CLI, and offline regression contracts; refreshed documentation, changelog, hardening audit, and release counts.
- Offline gates passed with 190 + 20 + 5 assertions and 0 failures; release report passed with 215 total and 0 failures.
