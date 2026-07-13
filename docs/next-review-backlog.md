# Workcell next review backlog

Updated: 2026-07-12

## Review conclusion

Workcell is a strong, production-oriented local Docker MVP and a credible Kujo showcase. It is not universally enterprise-grade in isolation: the Docker daemon, host kernel, image supply chain, network egress, credentials, and deployment boundary remain operator-owned. The current repository has 80 offline policy/artifact/verification assertions, 8 workspace assertions, adversarial request rejection, Docker integration coverage, structured receipts, versioned integrity manifests, and explicit ecosystem integration boundaries.

The next work should preserve the current contract: Docker remains the default, Podman remains an explicit OCI backend, all external tools remain opt-in and bounded, and failures must stay visible without weakening the primary sandbox verdict.

## Priority 1 — release and security controls

### [ ] Rootless deployment evidence

Run the full Docker and Podman matrix on rootless Linux and one VM-backed host. Capture `doctor --backend ... --json`, success/failure/timeout/cleanup receipts, and resource-inventory evidence.

Acceptance: the same offline, adversarial, and Docker integration contracts pass on each supported deployment class; compatibility claims are updated with observed results.

### [ ] Image supply-chain policy

Add an explicit release policy for base-image digest pinning, registry allowlists, signature-key rotation, cosign verification receipts, and vulnerability-scan evidence. Keep local tags available for examples, but make release definitions fail closed when policy requires provenance.

Acceptance: CI demonstrates a pinned, signed image path and a deliberate, tested mismatch failure; documentation identifies who owns key and registry rotation.

### [ ] Egress and proxy enforcement

Add a deployment-owned egress contract for `network.mode: default` and custom networks, including DNS, proxy, and deny-by-default firewall behavior. Do not claim that setting a proxy variable controls arbitrary child processes.

Acceptance: a supported deployment test proves allowed and denied destinations, and the receipt records the selected network policy and host enforcement profile.

### [ ] Resource and output stress limits

Exercise maximum files, bytes, depth, output truncation, artifact trees, concurrent runs, and cancellation under load. Record wall time, peak disk usage, and cleanup latency.

Acceptance: bounded behavior is deterministic, receipts remain valid under truncation/failure, and the performance budget is documented for representative repository sizes.

## Priority 2 — functionality and interoperability

### [x] Versioned receipt and artifact manifest

Add a versioned manifest containing SHA-256 hashes, byte counts, and relative paths for exported artifacts, patches, logs, and integration reports. Keep secret values and host-sensitive absolute paths out of the manifest.

Acceptance: consumers can verify a run directory offline; tampering is detected; old `receipt.json` consumers remain compatible through an additive schema change. Implemented through `manifest.json`, `workcell verify`, additive receipt fields, and fixture/Docker tamper tests.

### [x] Stable backend-neutral result schema

Promote `runtime_backend` and `runtime` fields to the documented clean/inventory contract, while retaining the current `docker` JSON alias through one compatibility period. Add schema/version tests for Docker and Podman outputs.

Acceptance: automation never needs to infer the backend from a Docker-specific field or human-readable text. Implemented with `runtime_backend`/`runtime`, a compatibility `docker` alias, backend-aware CLI text, and Docker integration assertions.

### [ ] Concurrent-run and cleanup coordination

Define behavior when `run`, `clean`, or two runs target the same repository simultaneously. Add an ownership-aware lock or lease only if it can be implemented without broad host mutation.

Acceptance: concurrent runs cannot remove each other’s containers, workspaces, images, or receipts; stale locks have a documented recovery path.

### [ ] Integration adapter contracts

Add fixture-backed contracts for each optional adapter’s command line, report schema, timeout, redaction, and failure status. Enable them in a dedicated CI job only when the owning tool version and credentials are present.

Acceptance: every adapter has a deterministic fake/fixture test and a separate live evidence job; adapter failures never change a successful primary Workcell verdict.

## Priority 3 — Kujo showcase and developer experience

### [ ] Kujo-native test and benchmark reporting

Expose a concise machine-readable test/benchmark summary for the Workcell suite, including assertion counts, elapsed time, and skipped deployment gates. Keep the shell scripts as orchestration only.

Acceptance: a new contributor can run one command and obtain a structured local release report without parsing terminal prose.

### [ ] Example matrix expansion

Add examples for secrets, custom networks, Podman, digest verification, signature verification, artifact rejection/redaction, and an intentionally failed verification. Each example must state whether it needs Docker, Podman, cosign, or sibling tools.

Acceptance: every example validates offline; runtime-dependent examples have a smoke command and expected receipt assertions.

### [ ] Documentation and API compatibility policy

Publish the definition, receipt, clean/inventory, and integration schemas as compatibility contracts with additive-change rules, deprecation windows, and exit-code stability guarantees.

Acceptance: README links to the contracts, `help --json` and `validate --schema` agree with the docs, and CI catches stale examples or field names.

## Explicit non-goals for the next session

- Do not replace Docker with a custom runtime.
- Do not silently enable external integrations or inherit host credentials.
- Do not claim rootless, microVM, remote attestation, egress enforcement, registry authorization, or vulnerability scanning from local macOS Docker evidence.
- Do not move `main.kujo`, `workcell.json`, or repository metadata into `src/`; those root files are part of the Kujo project contract.
