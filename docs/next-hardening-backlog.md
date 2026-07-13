# Next Workcell Hardening Backlog

This is the next-session work list produced by the codebase review on 2026-07-11. Items are intentionally separated by ownership so repository work is not confused with Docker-host or Kujo-toolchain work.

## Review result

The repository is now a substantially hardened, schema-described, tested Kujo-native Docker MVP. It is not a universally isolated enterprise sandbox: it trusts the Docker daemon and host kernel, and relies on operators for rootless/VM boundaries, egress enforcement, and image-signing governance. The Kujo process API now provides bounded stream sinks, incremental exact/base64 redaction, and cancellation hooks. Docker and rootless Podman integration have passed against Colima-backed daemons, including verification, streamed log files, cancellation metadata, seccomp preflight, and ownership-scoped cleanup; hosted CI and production-host evidence remain deployment-dependent.

The review added duplicate-input validation, faster changed-path indexing, strict owner markers, host UID/GID workspace mapping, bounded workspace scans, artifact limits/policies, fail-closed binary artifact secret inspection, malformed network-type fail-closed validation, declarative verification, image provenance fallbacks, resource inventory, machine-readable contracts, compatibility docs, image ownership labels, opt-in ecosystem evidence adapters, an OCI runtime backend contract, truthful dry-run integration skips, atomic-write result checks, runtime-class validation, backend-aware doctor diagnostics, backend-neutral CLI presentation, RunLedger finish-state reporting, changed-file analysis reuse, versioned run manifests, offline manifest verification, active-resource cleanup coordination, empty-orphan recovery, disappearing-workspace handling, release reporting, example-matrix coverage, versioned API compatibility contracts, a rootless engine-aware workspace identity, and a deployment-owned egress declaration with receipt evidence. The current offline suite is 102 policy assertions plus 11 workspace assertions and 5 stress assertions; Docker integration and ecosystem gates remain required release evidence.

## P0 — Kujo toolchain safety

### [x] Fix formatter semantic corruption

- Owner: Kujo language repository.
- Evidence before fix: `kujo format --write` rewrote valid Workcell code by changing operator spacing, path separators inside string literals, and CLI flag strings; it also split nested comma expressions.
- Implemented in Kujo commits `ff31153` and `7ef6eb8`: non-code/operator protection, syntax-safe formatting, cached regexes, and regression tests for strings, comments, paths, flags, operators, and nested comma expressions. Wrapping is deferred until an AST-aware pass exists.
- Acceptance status: every Workcell `.kujo` file passes `kujo format --check`; formatted temporary copies of all source files pass `kujo check`; the Kujo formatter tests pass.

### [x] Reduce false-positive linter warnings

- Owner: Kujo language repository.
- Evidence before fix: `kujo lint` exited 0 but emitted widespread `unreachable-code` warnings for valid returned dictionaries and imported/exported modules.
- Implemented in Kujo commit `7ef6eb8`: token-based reachability tracks block braces, multiline delimited return expressions, and only direct-line terminators. Workcell's remaining actionable warnings were fixed with explicit error handling.
- Acceptance status: all Workcell source modules pass `kujo lint --json` with zero findings, and the linter regression suite passes.

## P0 — Host isolation and secret handling

### [x] Replace broad temporary-workspace permissions

- Owner: Workcell plus Kujo/Docker host design.
- Implemented: default `workspace.run_as: host` resolves the invoking non-root UID/GID, uses owner-only write permissions, and supports explicit fixed non-root UID/GID values with fail-closed host `chown`.
- Acceptance status: offline coverage and compatibility documentation pass; rootless Docker and rootless Podman evidence are recorded for a Colima Linux VM; hosted CI and production-host evidence remain deployment-dependent.

### [x] Add bounded streaming output and streaming redaction

- Owner: Kujo process API plus Workcell runtime.
- Implemented in Kujo and Workcell: bounded `spawn_process` stream channels and file sinks, per-stream output caps, EOF/sequence events, incremental exact-value redaction across chunk boundaries, common base64-derived secret redaction, and completion metadata that remains bounded and redacted.
- Acceptance status: Kujo unit coverage exercises backpressure, split-secret redaction, UTF-8 preservation, and Workcell Docker integration asserts persisted stdout/stderr stream logs and redacted receipt output.

### [x] Add artifact content policy hooks

- Owner: Workcell.
- Risk: declared artifacts are path-safe but may contain secrets or oversized data.
- Implemented: global and per-path byte/file/depth limits, extension-based content policy, allow/reject/redact secret actions, receipt artifact counts, and rejection diagnostics.

## P1 — Runtime and lifecycle functionality

### [x] Add declarative verification commands

- Owner: Workcell.
- Goal: distinguish “the workload exited successfully” from “the produced change passed project verification.”
- Acceptance: a versioned `verification` block can run declared checks inside the disposable workspace, records command/exit/output status separately, and never weakens container policy. Existing definitions remain valid through safe defaults.

### [x] Add a runtime resource inventory

- Owner: Workcell.
- Goal: make `clean` and incident response explain all Workcell-owned containers, images, networks, and preserved workspaces without touching unrelated resources.
- Acceptance: `clean --json` supports dry-run inventory, ownership labels are verified, image retention is explicit, and cleanup failure reports identify exact resources.

### [x] Improve image provenance

- Owner: Workcell.
- Goal: make receipts useful for local images with no `RepoDigests` and for multi-platform images.
- Acceptance: record a stable observed image ID/config digest fallback, platform, builder, labels, and the verified digest source; digest pin comparisons remain fail-closed and documented.

### [x] Add explicit cancellation handling

- Owner: Kujo process API plus Workcell.
- Goal: handle user interruption and parent-process termination without orphaning Docker containers or losing receipts.
- Implemented in Kujo and Workcell: SIGINT/SIGTERM cancellation capture, cross-platform cancellation-marker support, cancellation-aware bounded stream backpressure, explicit `cancelled` ProcessResult/receipt fields, exit code 130, and the existing labeled stop/remove cleanup path.
- Acceptance status: Kujo coverage terminates a running child through a cancellation marker; Workcell Docker integration and offline suites pass with the new receipt/log contract.

## P1 — Performance and scale

### [x] Batch Git change collection

- Owner: Workcell.
- Goal: reduce subprocess count for repositories with many untracked files.
- Implemented: one batched `file --mime-type` probe per 256-path chunk replaces per-untracked-file binary probes, with the existing path-safe Git output and fallback behavior retained. The opt-in 2,000-file fixture recorded 32,259 ms on the current macOS/Kujo runtime; the default suite runs a 200-file signal.
- Toolchain note: NUL-delimited Git parsing is not expressible in the current Kujo string-literal surface, so newline-safe NUL parsing remains a Kujo-language follow-up.

### [x] Bound workspace scans

- Owner: Workcell.
- Goal: prevent symlink and artifact scans from consuming unbounded memory or time on large trees.
- Acceptance: configurable file-count/byte/depth limits, deterministic scan errors, receipt diagnostics, and integration coverage for limit failures.

### [x] Reuse daemon/image security probes per run

- Owner: Workcell.
- Goal: avoid repeated Docker info/image inspect calls while keeping fail-closed behavior.
- Implemented: daemon security is checked once during image preparation per run, image metadata is carried into the receipt, and verification containers reuse the prepared image/policy without silently skipping the run's security gate. Separate runs re-enter preparation.

## P1 — Universal usability and presentation

### [x] Add a first-class verification example

- Owner: Workcell.
- Goal: provide a runnable example that edits or builds a repository and then runs checks, with receipt fields showing execution versus verification.
- Acceptance: example works offline after image preparation, exports logs/receipt/patch, leaves the source repository unchanged, and is exercised in CI where Docker is available.

### [x] Add machine-readable schema/help output

- Owner: Workcell.
- Goal: make Workcell easier to integrate into agents, editors, and CI generators.
- Acceptance: `validate --schema` or equivalent emits the supported JSON schema/field contract, `help --json` exposes commands/options/exit codes, and outputs are versioned.

### [x] Improve release metadata DRYness

- Owner: Workcell.
- Evidence: version `0.1.0` currently appears in `VERSION`, `kujo.toml`, `kennel.toml`, `CHANGELOG.md`, and the CLI source.
- Acceptance: define an authoritative version source and generate or validate the other projections without making the launcher depend on the caller's working directory.

### [x] Add universal platform documentation

- Owner: Workcell.
- Goal: clearly describe Linux, macOS/Colima, rootless Docker, Docker Desktop, and unsupported host behavior.
- Acceptance: a compatibility matrix covers permissions, networking, seccomp/AppArmor, rootless, image builds, and known differences; each claim has a runnable doctor or integration check.

## P2 — Optional ecosystem integrations

### [x] Add opt-in ecosystem evidence adapters

- Implemented a versioned \`integrations\` definition section for RunLedger, ChangeBucket, ShipCheck, Fence, PackWrite, and Muzzle.
- Every adapter is disabled by default, uses structured argv with a bounded working directory and timeout, redacts output, writes a separate JSON report, and cannot change the primary Workcell success status.
- RunLedger imports a completed Workcell result as a linked start/finish record; ChangeBucket, ShipCheck, Fence, PackWrite, and Muzzle preserve their native machine-readable output in separate run evidence.
- Acceptance: offline tests cover validation, bounded argv, disabled defaults, and a deterministic opt-in adapter; all external tool failures remain visible as integration warnings rather than being hidden.

### [x] Add an OCI runtime adapter contract

- Implemented Podman as an OCI-compatible backend with the same policy, identity, resource, network, security-option, image-provenance, stream, cancellation, and ownership-label contract as Docker.
- Added \`runtime.engine_runtime\` for reviewed gVisor/Kata/crun-style runtime classes and \`clean --backend docker|podman\` resource selection. Remote and microVM services remain provider deployments behind this same backend boundary.
- Acceptance: definitions and policy tests cover Podman and runtime-class arguments; Docker remains the default and existing Docker integration remains required.

## Deployment-owned P2 boundaries

- Provisioning a production rootless/microVM fleet.
- Operating a transparent egress proxy or domain policy service.
- Organization-wide cosign key rotation, Rekor policy, registry authorization, and vulnerability scanning.
- Remote or microVM service provisioning and provider-specific attestation remain deployment-owned; Workcell now exposes the explicit backend/runtime-class contract and fails closed when the selected engine is unavailable.

## Suggested next-session order

1. Exercise Docker and Podman integration on supported deployment classes, including rootless Linux and VM-backed hosts.
2. Enable approved ecosystem integrations in CI/release definitions and review their separate evidence reports.
3. Add provider-specific remote/microVM adapters only when an owner supplies a stable service contract and attestation policy.
