# Workcell Security Model

## Threat model

Workcell assumes an agent workload may be buggy, over-broad, or actively attempting to access host data. The stable v1 contract protects the source repository and limits host filesystem exposure by using a disposable Git workspace and constrained Docker/Podman execution arguments. It does not protect against a malicious or compromised container daemon, a compromised host kernel, engine vulnerabilities, or an operator who intentionally grants a broader policy.

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
- Release definitions may require both controls with `runtime.require_digest` and `runtime.require_signature`, and restrict image origins with `runtime.registry_allowlist`; these checks fail closed during definition validation.
- `workcell doctor --backend docker|podman` checks engine-specific security signals; rootful Docker must report seccomp/AppArmor, while rootless Docker must report seccomp and is allowed to omit AppArmor because the rootless daemon cannot advertise that profile. Podman must report an enabled seccomp profile and surfaces rootless/AppArmor state, warning when AppArmor is unavailable rather than treating its absence as evidence. Rootless engines require `workspace.run_as: rootless`, which makes the container's `0:0` identity resolve through the engine's user namespace instead of relying on an unmapped host UID/GID. Rootless status is surfaced rather than silently assumed.
- `trust_profile: native-guarded` turns that rootless requirement into a run-time gate and fails image preparation when the daemon does not meet it.
- Optional seccomp/AppArmor profile names are validated and attached to the container; `unconfined` is rejected.
- Declarative verification commands run in separate labeled containers with the same environment, identity, mounts, resources, and network policy as the workload; verification output is redacted before it reaches the receipt.
- Artifact exports can enforce byte/file/depth limits, extension policies, and secret allow/reject/redact behavior before or during export.
- `artifacts.secret_action: reject` also rejects a run whose Git patch held a declared secret, and the patch is not persisted in that case.
- Network definitions carry an explicit egress declaration. `network.mode: none` is normalized to deny-by-default with blocked DNS and no proxy; default/custom networks may declare a host-managed deny-by-default or operator-managed profile. The declaration is recorded and unmanaged network access emits a receipt warning; Workcell does not install firewalls, control DNS, or force arbitrary child processes to honor a proxy.

## Secrets

Secrets are named environment variables. Values are read immediately before execution and passed through the process environment; their names appear in inspection and receipts, but values do not. Captured stdout/stderr are redacted incrementally before stream log files, channel events, receipts, and artifacts are persisted; known current values and common base64 encodings are replaced with `[REDACTED]`. The generated `changes.patch` is persisted run evidence and is redacted on the same unconditional terms as the run logs, so a workload that writes a secret into the workspace cannot seal that value into the integrity manifest. Redaction cannot guarantee protection when a workload hashes or otherwise transforms a secret, or writes it to a declared artifact, so secret-aware workloads remain the caller's responsibility.

## Network and daemon trust

Only `none`, `default`, and explicitly pre-created `custom` networks are supported. Domain allowlists are rejected rather than silently downgraded. Egress policy is a host-enforcement contract, not a Workcell firewall: supported deployment profiles must prove allowed/denied destinations externally. Docker itself is a privileged host service; access to its socket would be equivalent to broad host control and is prohibited. Workcell is therefore a bounded Docker workflow, not a perfect security boundary.

## Outside the v1 guarantee

Workcell v1 does not protect a compromised daemon or host kernel, provide a hardened microVM, controlled network proxy, hosted scheduler, or multi-tenant service, or certify a deployment. Kujo process streams are bounded and redacted incrementally, and parent cancellation produces explicit receipt metadata, but transformed-secret detection remains impossible at this layer. Named seccomp/AppArmor profiles may be selected when already installed on the host, but Workcell does not install or audit them. Image digest pinning, local image-ID provenance fallback, and optional cosign public-key verification are implemented; image governance, key custody, transparency policy, evidence retention, and compliance remain operator responsibilities. Future runtime adapters must preserve the policy interface and document stronger or weaker guarantees explicitly.

Portable receipts do not inherit Docker-era claims. Each control records its request, acceptance, resolved value, enforcement authority, observation, and limitations. `provider-claimed` and `operator-claimed` are not equivalent to `workcell-enforced`. Unknown or unproved required controls reject before provisioning. Remote downloads are untrusted until Workcell has checked archive paths/types/bounds, re-applied declared-artifact policy, and written its own hashes. Recovery requires both the run ID and unpredictable ownership nonce and inventories before deletion.
Optional ecosystem integrations run after the primary receipt boundary with explicit argv, bounded timeout/output, and environment-secret redaction. Their failures are recorded as integration warnings and never turn a successful sandbox execution into a failed primary run.

## Reporting security issues

Do not open a public issue for a suspected vulnerability. Use the repository's private [GitHub Security Advisory reporting flow](https://github.com/kujolang/workcell/security/advisories/new) and include the affected Workcell version, backend and host class, definition, reproduction steps, and redacted receipt evidence.
