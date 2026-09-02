# Workcell Security Review

## v1 review scope

This review covers the stable local and CI Docker/Podman contract at Workcell 1.0.0. It reviews definition validation, disposable workspaces, backend policy construction, execution and timeout handling, declared artifact export, receipts and manifests, integrity verification, and ownership-scoped cleanup. It is not a review of a particular host kernel, daemon, network, image supply chain, signing-key system, retention program, hosted service, or compliance regime.

## Implemented protections

- Clean-source enforcement prevents silent omission of dirty repository changes.
- Disposable Git worktrees or isolated clones prevent a writable mount of the source checkout.
- Structured argv prevents host-side command injection through image, path, and runtime arguments.
- Policy rejects host networking, privileged mode, daemon sockets, sensitive host mounts, host namespaces, devices, unbounded resource values, and unsafe security profiles.
- Containers receive a non-root or rootless-mapped identity, read-only root by default, `no-new-privileges`, dropped capabilities, private IPC, explicit network mode, and bounded CPU, memory, PIDs, time, and output.
- Host-control environment denial covers Docker/Podman selectors, cloud and package credential selectors, Kubernetes connection variables, Git overrides, and inherited proxy controls.
- Artifact and output paths are normalized and contained; symlink escapes are rejected and only declared outputs are exported.
- Secret names are explicit. Known exact and base64-encoded values are incrementally redacted from captured text; secret-aware artifact policy can reject or redact exports.
- Receipts separate product version, definition version, execution, verification, export, cleanup, and integrations. Integrity manifests hash immutable evidence and `workcell verify` detects tampering.
- Workcell resources use ownership, run ID, project, and product-version labels. Cleanup targets labels and ownership markers, preserves active resources, and treats missing containers idempotently.
- Image digest, registry allowlist, and optional cosign public-key checks can fail image preparation closed.
- Docker and Podman `doctor` paths inspect backend availability, rootless state, and required security signals without claiming stronger host evidence than the engine reports.

## Verification coverage

The offline suite exercises definition and API type boundaries, unknown fields, traversal and absolute paths, symlink and ownership-marker attacks, unsafe mounts and environment selectors, resource overflow, malformed network and artifact policy, digest/signature configuration, runtime-class injection, CLI option boundaries, receipt mutation, manifest omission and tampering, redaction, cancellation and timeout classification, startup and verification cleanup, idempotent recovery, backend-neutral output, and incomplete exported-function inputs.

The adversarial CLI suite rejects privileged, socket, host-mount, traversal, image/runtime injection, secret, resource, and build-context requests before runtime. Effective-policy inspection confirms network `none`, read-only root, init, private IPC, all capabilities dropped, `no-new-privileges`, bounded resources, Workcell labels, explicit identity, and only the disposable workspace mount.

Docker and Podman integration gates cover successful and failed execution, timeout, exit-code classification, provenance failures, custom/internal networks, secrets, artifact policy, verification containers, receipts, manifests, tamper detection, image builds, inventory, and cleanup. Concurrent-load evidence checks run separation, source immutability, artifact and manifest integrity, and cleanup. Egress evidence checks an allowed internal destination and blocked external DNS on a temporary internal network.

## Alpha provider-neutral surface

The provider-neutral path is reviewed as an additive alpha contract, not as part of the stable v1 isolation claim. Core validates closed protocol envelopes and operation shapes, redacts bounded adapter output, packages only a clean Git commit, independently verifies transferred digests and archive paths, re-applies declared artifact policy, persists ownership intent before provisioning, and destroys only handles or inventory entries matching both run ID and nonce. Receipt v2 separates requested, accepted, enforcement authority, and observation, so a provider or operator assertion is never represented as Workcell enforcement.

Offline conformance covers protocol framing, semantic drift, cancellation classification, unknown provision outcomes, recovery, transfer limits, malformed responses, credentials, concurrent ownership isolation, and adapter integrity. It does not verify a remote provider's tenant isolation, network enforcement, retention, billing, regional placement, cancellation latency, or deletion behavior. Those claims require exact-version credentialed promotion evidence and remain blocked when unknown.

## Residual risk and required interpretation

Workcell cannot protect against a compromised daemon or host kernel. It does not provide a hardened microVM, hosted multi-tenant scheduler, controlled organization-wide proxy, image-governance program, key-custody system, evidence-retention policy, or compliance certification. Exact-value redaction cannot detect arbitrarily transformed secrets. An operator-selected seccomp/AppArmor profile is passed through but not installed or audited by Workcell. Local and CI test evidence must not be generalized beyond the host and backend actually tested.

The stable v1 statement therefore means the documented local Docker/Podman execution and evidence contracts are maintained compatibly. It does not mean every deployment is safe or enterprise-approved.
