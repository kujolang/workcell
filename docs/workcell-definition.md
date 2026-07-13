# Workcell Definition Format

Workcell definitions are JSON documents with `version: 1`. JSON is declarative, deterministic, supported by Kujo's runtime, and does not execute arbitrary configuration code.

```json
{
  "version": 1,
  "name": "hello-workcell",
  "runtime": {"backend": "docker", "image": "alpine:3.20", "build_context": ""},
  "workspace": {"strategy": "git-worktree", "mount_path": "/workspace", "run_as": "host"},
  "command": ["sh", "-lc", "printf 'hello\\n' > hello.txt"],
  "environment": {"allow": [], "set": {}},
  "secrets": [],
  "resources": {"cpus": 2, "memory": "1g", "pids": 256, "timeout_ms": 300000, "max_output_bytes": 4000000},
  "network": {"mode": "none", "egress": {"policy": "deny-by-default", "dns": "blocked", "proxy": "none", "enforcement_profile": "none"}},
  "filesystem": {"read_only_root": true, "tmpfs": ["/tmp"]},
  "artifacts": {"export": ["hello.txt"]},
  "verification": {"version": 1, "commands": []},
  "cleanup": {"keep_failed": false},
  "trust_profile": "contained-standard",
  "receipt": {"path": ".workcell/runs"}
}
```

## Fields and defaults

- `version`: required integer `1`.
- `name`: required non-empty project name.
- `runtime.backend`: `docker` (default) or `podman`; `runtime.image` is the image name; optional `build_context` is a safe repository-relative directory; optional `image_digest` pins the observed image to a `sha256:` digest and fails preparation on mismatch; optional `signature_key` verifies the image with `cosign verify --key` before launch. `require_digest` and `require_signature` make those provenance controls fail closed, and `registry_allowlist` restricts the image registry host (unqualified images resolve to `docker.io`).
- `workspace.strategy`: `git-worktree` (default) or `isolated-clone`; `mount_path` must be a safe absolute container path and defaults to `/workspace`. `run_as` defaults to `host`, resolving the invoking non-root UID/GID and avoiding world-writable temporary workspaces; explicit non-root `uid:gid` pairs are supported when the host can assign ownership. Set `run_as` to `rootless` for a rootless Docker or Podman engine: Workcell runs as container `0:0`, which is mapped to the unprivileged daemon user by the engine, and rejects mismatched rootful/rootless combinations.
- `workspace.scan`: bounded post-run workspace inspection with `max_files`, `max_bytes`, and `max_depth`; limits fail verification with receipt diagnostics rather than silently truncating evidence.
- `command`: required non-empty argv array. Arguments may begin with `-`; host-side Workcell commands never use shell interpolation.
- `environment.allow`: host environment names explicitly passed into the container with Docker's `--env NAME` form. Host-control variables such as `PATH`, `HOME`, `DOCKER_HOST`, and credential selectors are rejected.
- `environment.set`: explicit non-secret container values passed as `--env NAME=value`; a configured name cannot override a declared secret.
- `secrets`: environment-variable names read at execution time and passed into the container by name, without placing their values in Docker argv. Missing names fail the run.
- `resources.cpus`, `memory`, `pids`, `timeout_ms`, `max_output_bytes`: bounded Docker/process values. CPUs range from 1–64, memory accepts integer `k`, `m`, or `g` values up to 64g, PIDs range from 1–65536, output is capped at 16 MB per stream, and timeouts are capped at 24 hours. Timeout strings ending in `s`, `m`, or `h` are normalized to milliseconds.
- `integrations`: optional RunLedger, ChangeBucket, ShipCheck, Fence, PackWrite, and Muzzle adapters. Each adapter is disabled by default and accepts a bounded command argv, timeout, and tool-specific mode. Enabled adapters write redacted reports under the run's `integrations/` directory and remain separate from the primary execution/verification result.
- `network.mode`: `none` (default), explicit `default`, or `custom`; `custom` attaches to a pre-created Docker network named by `network.name`, allowing operators to enforce an internal network or egress proxy boundary outside Workcell.
- `network.name`: required and Docker-safe when `network.mode` is `custom`; forbidden otherwise.
- `network.egress`: a deployment-owned declaration recorded in every receipt. `policy` is `deny-by-default`, `operator-managed`, or the compatibility value `unmanaged`; `dns` is `blocked`, `operator-managed`, or `inherited`; `proxy` is `none` or `operator-managed`; and `enforcement_profile` is a bounded operator-supplied identifier. `network.mode: none` requires the deny-by-default/blocked/none combination. Managed egress requires a non-`none` enforcement profile and never causes Workcell to inject proxy variables or install firewall rules.
- `filesystem.read_only_root`: default `true`; `tmpfs` targets must be `/tmp` or a descendant beneath `/tmp`.
- `filesystem.seccomp_profile` and `filesystem.apparmor_profile`: optional bounded profile names installed on the Docker host; `unconfined` and unsafe names are rejected. Empty values keep Docker's built-in defaults.
- `artifacts.export`: relative paths only; traversal, absolute paths, and escapes are rejected.
- `artifacts.limits`: optional per-export path limits for `max_bytes`, `max_files`, and `max_depth`. Global `max_bytes`, `max_files`, and `max_depth` bound the complete export; `allowed_extensions` provides a simple content-type policy; `secret_action` may `allow`, `reject`, or `redact` declared secret values before export.
- `verification`: versioned post-run checks. Each command has a stable `name` and argv array, runs in a separate labeled container with the same security policy, and is recorded independently from workload execution. Verification failures return exit code `8`.
- `cleanup.keep_failed`: default `false`; failed workspace preservation is explicit.
- `trust_profile`: `contained-standard` (default), `contained-open`, or `native-guarded`; `native-guarded` fails closed unless Docker reports seccomp and a rootless daemon (or a stronger VM/microVM runtime is used). Rootless Docker may not advertise AppArmor; Workcell leaves that limitation visible in `doctor` rather than treating it as AppArmor evidence.
- `receipt.path`: relative project output root, default `.workcell/runs`. Each completed run also writes `manifest.json` with schema `workcell-manifest/v1`, relative paths, byte counts, and SHA-256 hashes for immutable run evidence. `manifest.json` is excluded because it contains the manifest; `receipt.json` is included so receipt tampering is detected. Use `workcell verify --run <run-directory>` to validate it offline.

Unknown fields are rejected so misspellings do not silently weaken policy. The CLI's `inspect` command makes defaults and security arguments visible without starting Docker.
