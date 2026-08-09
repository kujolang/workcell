# Platform compatibility

Workcell defaults to Docker and also exposes a Podman-compatible OCI backend. `workcell doctor --backend docker|podman --json` is the authoritative host preflight; the matrix documents expected differences rather than claiming identical behavior across hosts.

| Host/runtime | Workspace ownership | Network/security behavior | Image/build notes | Status |
| --- | --- | --- | --- | --- |
| Linux, rootful Docker | Default `workspace.run_as: host` maps the invoking non-root UID/GID and uses owner-only write permissions. Explicit fixed UID/GID requires host `chown` permission. | Docker seccomp/AppArmor should be reported; rootless is a warning for standard runs and required by `native-guarded`. | Docker buildx preferred; legacy `docker build` is a compatibility fallback. | Supported with trusted daemon. |
| Linux, rootless Docker | Set `workspace.run_as: rootless`; the container `0:0` identity is mapped by the rootless daemon, avoiding an unmapped host UID/GID bind-mount failure. | Rootless plus seccomp satisfies the daemon portion of `native-guarded`; rootless Docker may not advertise AppArmor, which remains an explicit doctor warning. Host kernel/daemon trust still applies. | Build and bind-mount behavior depends on the rootless setup. | Supported when subordinate-ID mappings are available and doctor/integration checks pass. |
| Linux, rootless Podman | Set `runtime.backend: podman` and `workspace.run_as: rootless`; Podman's user namespace maps container `0:0` to the unprivileged engine user. | `doctor` requires Podman's seccomp profile and reports rootless/AppArmor state; policy, network, resource, provenance, and ownership contracts are shared with Docker. Host kernel/engine trust still applies. | Podman uses its native build path; image IDs are normalized into Workcell's `sha256:` receipt contract. | Supported when rootless mappings, seccomp, and the selected Podman features are available and doctor/integration checks pass. |
| macOS, Docker Desktop/Colima | Host-mapped UID/GID is passed through Docker Desktop/Colima's VM file sharing. Fixed UID/GID may require host-specific file-sharing support. | AppArmor is a Linux-host concept; doctor reports the daemon's actual security options. Use the VM boundary and keep `network: none` by default. | BuildKit/buildx is recommended; local image IDs are used when RepoDigests are absent. | Supported with local daemon validation. |
| Windows or unsupported Unix | Path, permission, and Docker security semantics are outside the v1 contract. | Do not infer Linux isolation or AppArmor behavior. | Image/build behavior is unverified. | Unsupported; run on Linux or macOS with Docker, or supported Linux with Podman. |

## Required preflight

```bash
./bin/workcell doctor --backend docker --json | jq .
./bin/workcell doctor --backend podman --json | jq .
./bin/workcell validate --schema | jq .
```

Run the applicable integration, load, and egress suites on every release host class and run `doctor` on each deployment host. A passing offline suite proves policy and lifecycle contracts, not host-specific daemon behavior.

## Observed deployment evidence

The rootless Docker and Podman paths have been exercised on a Linux Colima VM, including rootless workspace identity, fail-closed identity mismatch, OCI smoke, full integration, egress enforcement, and resource cleanup contracts. See [the dated evidence record](compatibility/rootless-docker-colima-2026-07-13.md). The final hosted CI receipt remains a separate release prerequisite and is not replaced by that local evidence.
