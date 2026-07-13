# Rootless OCI evidence: Colima VM

Observed on 2026-07-13 using the pinned Kujo runtime revision from `workcell.json`.

| Check | Result |
| --- | --- |
| Host class | macOS Intel host with a Linux Colima VM |
| Engine | Docker 29.5.2, rootless daemon over a user socket |
| Security signals | seccomp and rootless reported; AppArmor kernel support loaded but not advertised by rootless Docker |
| `workcell doctor --backend docker --json` | `ok: true`, `blocked: 0`; AppArmor omission is an explicit warning |
| `tests/oci_smoke.sh docker` | passed with `rootless: true` and `workspace_run_as: rootless` |
| Rootful identity on rootless daemon | rejected before workload execution with exit code 4 and an actionable error |
| `tests/docker_integration.sh` | passed; success, digest/signature failures, custom/internal networks, secrets, artifacts, verification, cleanup, symlink rejection, failure, timeout, and inventory contracts exercised |
| Podman | 4.9.3, rootless user-mode engine in the same Linux VM |
| `tests/oci_smoke.sh podman` | passed with `rootless: true` and `workspace_run_as: rootless` |
| `workcell doctor --backend podman --json` | `ok: true`, `blocked: 0`; Podman seccomp is enabled and AppArmor absence is an explicit warning |
| `tests/docker_integration.sh podman` | passed; backend-neutral policy, identity, network, provenance, verification, failure, timeout, and cleanup contracts exercised |
| `tests/egress_integration.sh docker` and `podman` | both passed; allowlisted internal destination reached and external DNS blocked |
| Offline Kujo fixture suite | 4/4 fixtures passed under the interpreter runtime |

Rootless definitions must set `workspace.run_as` to `rootless`. Workcell maps that explicit mode to container `0:0`; the rootless engine maps it to the unprivileged daemon identity, so bind-mounted workspaces remain writable without treating a host UID/GID as portable across user namespaces. Definitions using `host` or a fixed UID/GID fail closed on a rootless engine.

This evidence covers rootless Docker and rootless Podman on one VM-backed Linux deployment class. It does not close the complete deployment matrix: a hosted CI run remains blocked by the repository account's billing/spending-limit state, and production host firewall/proxy/image-governance acceptance remains deployment-owned. Those are external prerequisites, not claims inferred from this VM run.
