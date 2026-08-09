# Known Limitations

- Docker is the default backend; Podman is supported through the same OCI policy boundary, while remote and microVM service provisioning remain deployment-owned.
- The Kujo example image builds Kujo from a pinned upstream commit and therefore needs network access during its one-time Docker image build.
- The current Kujo process API has no working-directory option; Workcell uses `git -C` and Docker `--workdir` instead.
- Dirty repositories are rejected rather than snapshotting uncommitted changes.
- Patch generation is Git diff based and now includes untracked files through Git's binary no-index diff; rename detection remains Git's responsibility.
- Workcell v1 supports `network: none|default|custom` plus a versioned egress declaration; custom networks must be pre-created by the operator, and domain allowlists, firewalls, DNS controls, or transparent proxies remain external controls. Unmanaged default/custom networks are accepted only for compatibility and produce receipt warnings.
- Secrets are redacted incrementally from known exact values and common base64 encodings in stream logs, completion output, verification output, and receipts; arbitrary hashed output still requires workload-level controls. Artifact export can explicitly allow, reject, or redact declared secret values.
- Versioned verification commands run inside separate Workcell-labeled containers, but ShipCheck, Fence, and other ecosystem tools remain opt-in integrations rather than implicit project checks.
- Stream sinks and user-signal/cancellation-marker handling are available through the Kujo process API; cancellation and timeout cleanup remain bounded and label-scoped. A cancellation signal is process-wide, so operators should treat SIGINT/SIGTERM as terminating the current Workcell invocation.
- Docker and Podman integration, timeout, failure, load, egress, receipt, and cleanup behavior are release gates, but the final hosted CI receipt and each target-host preflight remain separate from local evidence.
- RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, PackWrite, and Muzzle are documented integration points; the current runtime keeps them optional and standalone.
- Opt-in ecosystem adapters require the corresponding CLI and its own configuration/credentials. Their reports are persisted separately and failures become integration warnings; they never silently change the core Workcell verdict.
- Digest pinning and optional cosign public-key verification are supported through `runtime.image_digest` and `runtime.signature_key`; key lifecycle and transparency policy remain deployment responsibilities.
- Workcell does not provide protection from a compromised daemon or host kernel, microVM isolation, hosted multi-tenant execution, organization-specific egress infrastructure, image governance, signing-key custody, evidence-retention policy, or compliance certification.
