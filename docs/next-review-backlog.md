# Workcell next review backlog

Updated: 2036-07-13

## Review conclusion

Workcell is a strong, production-oriented local Docker MVP and a credible Kujo showcase. It is not universally enterprise-grade in isolation: the Docker daemon, host kernel, image supply chain, network egress, credentials, and deployment boundary remain operator-owned. The current repository has 190 offline policy/artifact/verification assertions, 23 workspace assertions, 5 deterministic stress assertions, a machine-readable `workcell-report/v1` release summary, an explicit example matrix, adversarial request rejection, Docker integration coverage, structured receipts, versioned integrity manifests, and explicit ecosystem integration boundaries.

The next work should preserve the current contract: Docker remains the default, Podman remains an explicit OCI backend, all external tools remain opt-in and bounded, and failures must stay visible without weakening the primary sandbox verdict.

Iteration 060 closed four additional local lifecycle/security defects: symlinked ownership markers could authorize empty-orphan recovery or be followed during direct cleanup, missing-container removal was not idempotent across Docker/Podman error messages, null output requests silently selected the default output root, and startup failures were returned with a non-contract stage that caused the launcher to emit internal-error code 10 instead of startup code 5. The repository now rejects symlinked markers and null output requests, treats missing resources as already cleaned, and preserves the documented startup-failure exit contract with fake-runtime regressions.

Iteration 061 closed a fifth local cleanup defect: stop cleanup recognized only one case-sensitive missing-container phrase, so valid cleanup could fail on Docker/Podman wording variants. Stop and remove now share normalized missing-container matching, and the runtime contract covers `No such container`, `no container with`, and `container not found` responses.

## Priority 1 — release and security controls

### [ ] Rootless deployment evidence

Run the full Docker and Podman matrix on rootless Linux and one VM-backed host. Capture `doctor --backend ... --json`, success/failure/timeout/cleanup receipts, and resource-inventory evidence.

The repository now provides `tests/oci_smoke.sh` and required CI Docker/Podman deployment gates. Rootless Docker and rootless Podman were observed through a Colima Linux VM: doctor passed with the expected security signals, Podman seccomp was required, both OCI smokes emitted `workcell-oci-evidence/v1`, both full integration matrices passed with `workspace.run_as: rootless`, and both egress suites proved allowlisted internal access plus blocked external DNS. See `docs/compatibility/rootless-docker-colima-2036-07-13.md`.

Acceptance remains open only for the hosted CI run and deployment-owned production host controls; the rootless Docker/Podman VM-backed evidence is now recorded.

### [x] Image supply-chain policy

Add an explicit release policy for base-image digest pinning, registry allowlists, signature-key rotation, cosign verification receipts, and vulnerability-scan evidence. Keep local tags available for examples, but make release definitions fail closed when policy requires provenance.

Acceptance: CI demonstrates a pinned, signed image path and a deliberate, tested mismatch failure; documentation identifies who owns key and registry rotation. The definition now supports fail-closed `require_digest`, `require_signature`, and `registry_allowlist` controls; live signing and vulnerability-scan evidence remain deployment-owned.

### [ ] Egress and proxy enforcement

Add a deployment-owned egress contract for `network.mode: default` and custom networks, including DNS, proxy, and deny-by-default firewall behavior. Do not claim that setting a proxy variable controls arbitrary child processes.

The repository-side contract is now implemented: `network.egress` validates policy/DNS/proxy ownership, records `network_policy` in receipts and inspection output, warns on compatibility-mode unmanaged access, and includes the `egress-policy` example. `tests/egress_integration.sh` proves an allowed internal destination and blocked external DNS on a temporary internal network, while `tests/egress_deployment_contract.sh` validates an operator-supplied default or pre-created custom network without mutating it and emits `workcell-egress-deployment-evidence/v1`. Default-network, host-firewall, and transparent-proxy acceptance remains deployment-owned and must be run with real operator endpoints.

Acceptance: a supported deployment test proves allowed and denied destinations, and the receipt records the selected network policy and host enforcement profile.

### [x] Resource and output stress limits

Exercise maximum files, bytes, depth, output truncation, artifact trees, concurrent runs, and cancellation under load. Record wall time, peak disk usage, and cleanup latency.

Acceptance: bounded behavior is deterministic, receipts remain valid under truncation/failure, and the performance budget is documented for representative repository sizes. Added deterministic file/byte/depth, output-truncation, and timeout stress contracts plus `tests/load_integration.sh` for bounded concurrent deployment runs; hosted CI and larger production deployment load evidence remain open.

## Priority 2 — functionality and interoperability

### [x] Versioned receipt and artifact manifest

Add a versioned manifest containing SHA-256 hashes, byte counts, and relative paths for exported artifacts, patches, logs, and integration reports. Keep secret values and host-sensitive absolute paths out of the manifest.

Acceptance: consumers can verify a run directory offline; tampering is detected; old `receipt.json` consumers remain compatible through an additive schema change. Implemented through `manifest.json`, `workcell verify`, additive receipt fields, and fixture/Docker tamper tests.

### [x] Stable backend-neutral result schema

Promote `runtime_backend` and `runtime` fields to the documented clean/inventory contract, while retaining the current `docker` JSON alias through one compatibility period. Add schema/version tests for Docker and Podman outputs.

Acceptance: automation never needs to infer the backend from a Docker-specific field or human-readable text. Implemented with `runtime_backend`/`runtime`, a compatibility `docker` alias, backend-aware CLI text, strict command-option/positional validation, global help/version flags, and Docker integration assertions.

### [x] Concurrent-run and cleanup coordination

Define behavior when `run`, `clean`, or two runs target the same repository simultaneously. Add an ownership-aware lock or lease only if it can be implemented without broad host mutation.

Acceptance: unique run IDs isolate containers, workspaces, receipts, and manifests; cleanup preserves active labeled containers and matching active workspaces, while removing only exited/dead resources. A scheduler-level queue/lease is intentionally deployment-owned.

### [x] Integration adapter contracts

Add fixture-backed contracts for each optional adapter’s command line, report schema, timeout, redaction, and failure status. Enable them in a dedicated CI job only when the owning tool version and credentials are present.

Acceptance: every adapter has a deterministic fixture contract covering argv, bounded execution, redaction, report persistence, and failure visibility; adapter failures never change a successful primary Workcell verdict. Live evidence jobs remain deployment-owned and require each tool’s approved version and credentials.

## Priority 3 — Kujo showcase and developer experience

### [x] Kujo-native test and benchmark reporting

Expose a concise machine-readable test/benchmark summary for the Workcell suite, including assertion counts, elapsed time, and skipped deployment gates. Keep the shell scripts as orchestration only.

Acceptance: a new contributor can run `tests/release_report.sh` and obtain a structured `workcell-report/v1` JSON summary without parsing terminal prose. The Kujo renderer reports suite counts, elapsed time, exit codes, and skipped deployment gates.

### [x] Example matrix expansion

Add examples for secrets, custom networks, Podman, digest verification, signature verification, artifact rejection/redaction, and an intentionally failed verification. Each example must state whether it needs Docker, Podman, cosign, or sibling tools.

Acceptance: every example validates offline; the matrix now covers secrets, custom networks, digest/signature policy, artifact rejection/redaction, and intentionally failed verification, with explicit Docker/Podman/cosign/sibling-tool dependencies.

### [x] Documentation and API compatibility policy

Publish the definition, receipt, clean/inventory, and integration schemas as compatibility contracts with additive-change rules, deprecation windows, and exit-code stability guarantees.

Acceptance: README links to `docs/api-compatibility.md`; `help --json`, `validate --schema`, receipt, manifest, inventory, cleanup, and integration identifiers are documented and tested; example validation and schema contract checks run in the default suite.

## Explicit non-goals for the next session

- Do not replace Docker with a custom runtime.
- Do not silently enable external integrations or inherit host credentials.
- Do not claim rootless, microVM, remote attestation, egress enforcement, registry authorization, or vulnerability scanning from local macOS Docker evidence.
- Do not move `main.kujo`, `workcell.json`, or repository metadata into `src/`; those root files are part of the Kujo project contract.
