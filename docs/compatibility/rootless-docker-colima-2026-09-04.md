# Rootless Docker evidence: Colima VM refresh

Observed on 2026-09-04 on an Intel macOS host using a Colima Ubuntu 24.04.4
Linux VM, Docker 29.5.2 in rootless mode, and Kujo 1.2.1 at the exact
`RUNTIME_VERSION` revision. WorkCell source behavior matched commit
`746b532a027b6ecf6b832e0acd8b927b49059ade`; the remaining working-tree changes
were this evidence record and status documentation. The test temporary directory was placed under the
mounted home directory so the rootless daemon could resolve bind mounts.

| Check | Result |
| --- | --- |
| `workcell doctor --backend docker --json` | passed with zero blocked checks; rootless and seccomp observed, AppArmor omission warned |
| `tests/oci_smoke.sh docker` | passed; rootful identity rejected and `workspace.run_as: rootless` succeeded |
| `tests/docker_integration.sh docker` | passed the complete Docker integration contract |
| `tests/load_integration.sh docker` | passed four concurrent runs with unique IDs, verified artifacts/manifests, unchanged source, and zero retained test containers |
| `tests/egress_integration.sh docker` | passed the internal allow target and blocked the external target under the declared deny-by-default policy |

This is local Docker evidence only. It does not certify Podman, a remote
provider, hosted CI, production host policy, or Cloudflare Sandbox. The current
Homebrew Podman formula rejected this Intel host because it requires Apple
silicon, so Podman must still be refreshed on a supported host.
