# Workcell Definition Format

Workcell definitions are JSON documents with `version: 1`. JSON is declarative, deterministic, supported by Kujo's runtime, and does not execute arbitrary configuration code.

```json
{
  "version": 1,
  "name": "hello-workcell",
  "runtime": {"backend": "docker", "image": "alpine:3.20", "build_context": ""},
  "workspace": {"strategy": "git-worktree", "mount_path": "/workspace"},
  "command": ["sh", "-lc", "printf 'hello\\n' > hello.txt"],
  "environment": {"allow": [], "set": {}},
  "secrets": [],
  "resources": {"cpus": 2, "memory": "1g", "pids": 256, "timeout_ms": 300000},
  "network": {"mode": "none"},
  "filesystem": {"read_only_root": true, "tmpfs": ["/tmp"]},
  "artifacts": {"export": ["hello.txt"]},
  "cleanup": {"keep_failed": false},
  "trust_profile": "contained-standard",
  "receipt": {"path": ".workcell/runs"}
}
```

## Fields and defaults

- `version`: required integer `1`.
- `name`: required non-empty project name.
- `runtime.backend`: required `docker`; `runtime.image` is the image name; optional `build_context` is a safe repository-relative directory; optional `image_digest` pins the observed image to a `sha256:` digest and fails preparation on mismatch.
- `workspace.strategy`: `git-worktree` (default) or `isolated-clone`; `mount_path` must be a safe absolute container path and defaults to `/workspace`.
- `command`: required non-empty argv array. Arguments may begin with `-`; host-side Workcell commands never use shell interpolation.
- `environment.allow`: host environment names explicitly passed into the container with Docker's `--env NAME` form. Host-control variables such as `PATH`, `HOME`, `DOCKER_HOST`, and credential selectors are rejected.
- `environment.set`: explicit non-secret container values passed as `--env NAME=value`; a configured name cannot override a declared secret.
- `secrets`: environment-variable names read at execution time and passed into the container by name, without placing their values in Docker argv. Missing names fail the run.
- `resources.cpus`, `memory`, `pids`, `timeout_ms`: bounded Docker resource values. CPUs range from 1–64, memory accepts integer `k`, `m`, or `g` values up to 64g, PIDs range from 1–65536, and timeouts are capped at 24 hours. Timeout strings ending in `s`, `m`, or `h` are normalized to milliseconds.
- `network.mode`: `none` (default) or explicit `default`; other modes are rejected.
- `filesystem.read_only_root`: default `true`; `tmpfs` targets must be `/tmp` or a descendant beneath `/tmp`.
- `artifacts.export`: relative paths only; traversal, absolute paths, and escapes are rejected.
- `cleanup.keep_failed`: default `false`; failed workspace preservation is explicit.
- `trust_profile`: `contained-standard` (default), `contained-open`, or documented `native-guarded`.
- `receipt.path`: relative project output root, default `.workcell/runs`.

Unknown fields are rejected so misspellings do not silently weaken policy. The CLI's `inspect` command makes defaults and security arguments visible without starting Docker.
