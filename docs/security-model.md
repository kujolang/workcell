# Workcell Security Model

## Threat model

Workcell assumes an agent workload may be buggy, over-broad, or actively attempting to access host data. The MVP protects the source repository and host filesystem by exposing only a disposable Git workspace and by constraining Docker execution arguments. It does not protect against a malicious or compromised Docker daemon, a compromised host kernel, Docker implementation vulnerabilities, or a user who intentionally grants a broader policy.

## Enforced defaults

- Dirty source repositories are rejected; user changes are not silently copied or discarded.
- The source repository is never the writable container directory.
- Only a temporary Git worktree or isolated clone is mounted.
- Network defaults to `none`; `default` requires explicit configuration.
- `--privileged`, Docker socket mounts, host root/home/SSH/cloud credential mounts, host namespaces, devices, and unbounded resources are not represented by the policy builder.
- Containers run as UID/GID `65532:65532`, with `no-new-privileges`, all capabilities dropped, bounded CPU/memory/PIDs, and a timeout.
- Root filesystem is read-only by default; declared tmpfs paths are the writable scratch surface.
- Host-side Docker/Git calls use structured argv, not shell interpolation.
- Artifact paths must be relative, normalized, traversal-free, and contained in the run output directory.
- Workcell-owned containers carry `dev.kujo.workcell=true` and run/project/version labels. Cleanup filters on this ownership label.

## Secrets

Secrets are named environment variables. Values are read immediately before execution and passed through the process environment; their names appear in inspection and receipts, but values do not. Captured stdout/stderr replace known current values with `[REDACTED]`. Redaction cannot guarantee protection when a workload transforms, encodes, hashes, or writes a secret to a declared artifact, so secret-aware workloads remain the caller's responsibility.

## Network and daemon trust

Only `none` and `default` are supported. Domain allowlists are rejected rather than silently downgraded. Docker itself is a privileged host service; access to its socket would be equivalent to broad host control and is prohibited. Workcell is therefore a bounded Docker workflow, not a perfect security boundary.

## Residual risks

The MVP does not implement image signature verification, a hardened microVM, a controlled network proxy, syscall filtering beyond Docker's configured defaults, streaming log redaction, or a scheduler. Future runtime adapters must preserve the policy interface and document stronger/weaker guarantees explicitly.
