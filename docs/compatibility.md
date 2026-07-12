# Platform compatibility

Workcell is a local Docker adapter. `workcell doctor --json` is the authoritative host preflight; the matrix documents the expected differences rather than claiming identical behavior across hosts.

| Host/runtime | Workspace ownership | Network/security behavior | Image/build notes | Status |
| --- | --- | --- | --- | --- |
| Linux, rootful Docker | Default `workspace.run_as: host` maps the invoking non-root UID/GID and uses owner-only write permissions. Explicit fixed UID/GID requires host `chown` permission. | Docker seccomp/AppArmor should be reported; rootless is a warning for standard runs and required by `native-guarded`. | Docker buildx preferred; legacy `docker build` is a compatibility fallback. | Supported with trusted daemon. |
| Linux, rootless Docker | Host UID/GID mapping is the preferred path; fixed ownership must match the rootless mapping. | Rootless satisfies the daemon portion of `native-guarded`; host kernel/daemon trust still applies. | Build and bind-mount behavior depends on the rootless setup. | Supported when doctor and integration checks pass. |
| macOS, Docker Desktop/Colima | Host-mapped UID/GID is passed through Docker Desktop/Colima's VM file sharing. Fixed UID/GID may require host-specific file-sharing support. | AppArmor is a Linux-host concept; doctor reports the daemon's actual security options. Use the VM boundary and keep `network: none` by default. | BuildKit/buildx is recommended; local image IDs are used when RepoDigests are absent. | Supported with local daemon validation. |
| Windows or unsupported Unix | Path, permission, and Docker security semantics are not covered by the MVP. | Do not infer Linux isolation or AppArmor behavior. | Image/build behavior is unverified. | Unsupported; run on Linux or macOS with Docker. |

## Required preflight

```bash
./bin/workcell doctor --json | jq .
./bin/workcell validate --schema | jq .
```

Before release, also run the Docker integration suite on the target host. A passing offline suite proves policy and lifecycle contracts, not host-specific daemon behavior.
