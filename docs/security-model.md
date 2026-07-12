# Workcell Security Model

## Threat model

Workcell assumes an agent workload may be buggy, over-broad, or actively attempting to access host data. The MVP protects the source repository and host filesystem by exposing only a disposable Git workspace and by constraining Docker execution arguments. It does not protect against a malicious or compromised Docker daemon, a compromised host kernel, Docker implementation vulnerabilities, or a user who intentionally grants a broader policy.

## Enforced defaults

- Dirty source repositories are rejected; user changes are not silently copied or discarded.
- The source repository is never the writable container directory.
- Only a temporary Git worktree or isolated clone is mounted.
- Network defaults to `none`; `default` and pre-created `custom` networks require explicit configuration.
- `--privileged`, Docker socket mounts, host root/home/SSH/cloud credential mounts, host namespaces, devices, and unbounded resources are not represented by the policy builder.
- Containers run as the invoking non-root host UID/GID by default, or an explicit non-root fixed UID/GID when host ownership assignment succeeds, with `--init`, private IPC, `no-new-privileges`, all capabilities dropped, bounded CPU/memory/PIDs/output, and a timeout. Timeout cleanup first attempts graceful stop and then force-removes only the labeled container.
- Root filesystem is read-only by default; declared tmpfs paths are the writable scratch surface.
- Host-side Docker/Git calls use structured argv, not shell interpolation.
- Container environment is explicit: allowlisted host variables and runtime secrets use `--env NAME`, while configured non-secret values use `--env NAME=value`; host-control variables are rejected.
- Artifact paths must be relative, normalized, traversal-free, and contained in the run output directory.
- Workspace trees and output roots containing symlinks are rejected or preserved only behind an explicit Workcell ownership marker.
- Workcell-owned containers carry `dev.kujo.workcell=true` and run/project/version labels. Cleanup filters on this ownership label.
- Definitions may pin `runtime.image_digest`; Workcell verifies the observed Docker image digest before launch and fails closed on mismatch.
- Definitions may set `runtime.signature_key` to a repository-relative cosign public key; missing keys, unavailable cosign, and failed verification all fail image preparation closed.
- `workcell doctor` checks that the daemon reports seccomp and AppArmor; rootless status is surfaced as a deployment warning rather than silently assumed.
- `trust_profile: native-guarded` turns that rootless requirement into a run-time gate and fails image preparation when the daemon does not meet it.
- Optional seccomp/AppArmor profile names are validated and attached to the container; `unconfined` is rejected.
- Declarative verification commands run in separate labeled containers with the same environment, identity, mounts, resources, and network policy as the workload; verification output is redacted before it reaches the receipt.
- Artifact exports can enforce byte/file/depth limits, extension policies, and secret allow/reject/redact behavior before or during export.

## Secrets

Secrets are named environment variables. Values are read immediately before execution and passed through the process environment; their names appear in inspection and receipts, but values do not. Captured stdout/stderr are redacted incrementally before stream log files, channel events, receipts, and artifacts are persisted; known current values and common base64 encodings are replaced with `[REDACTED]`. Redaction cannot guarantee protection when a workload hashes or otherwise transforms a secret, or writes it to a declared artifact, so secret-aware workloads remain the caller's responsibility.

## Network and daemon trust

Only `none`, `default`, and explicitly pre-created `custom` networks are supported. Domain allowlists are rejected rather than silently downgraded. Docker itself is a privileged host service; access to its socket would be equivalent to broad host control and is prohibited. Workcell is therefore a bounded Docker workflow, not a perfect security boundary.

## Residual risks

The MVP does not provide a hardened microVM, a controlled network proxy, or a scheduler. Kujo process streams are bounded and redacted incrementally, and parent cancellation produces explicit receipt metadata, but transformed-secret detection remains impossible at this layer. Named seccomp/AppArmor profiles may be selected when already installed on the Docker host, but Workcell does not install or audit them. Image digest pinning, local image-ID provenance fallback, and optional cosign public-key verification are implemented; key lifecycle and transparency policy remain deployment responsibilities. Future runtime adapters must preserve the policy interface and document stronger/weaker guarantees explicitly.
