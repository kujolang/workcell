# Next Workcell Hardening Backlog

This is the next-session work list produced by the codebase review on 2026-07-11. Items are intentionally separated by ownership so repository work is not confused with Docker-host or Kujo-toolchain work.

## Review result

The repository is now a substantially hardened, schema-described, tested Kujo-native Docker MVP. It is not a universally isolated enterprise sandbox: it trusts the Docker daemon and host kernel, cannot provide true streaming redaction until the Kujo process API exposes stream callbacks, and relies on operators for rootless/VM boundaries, egress enforcement, and image-signing governance. A prior Colima integration run passed; the current local daemon is unavailable and must be rerun before claiming host-level integration evidence for this milestone.

The review added duplicate-input validation, faster changed-path indexing, strict owner markers, host UID/GID workspace mapping, bounded workspace scans, artifact limits/policies, declarative verification, image provenance fallbacks, resource inventory, machine-readable contracts, compatibility docs, and image ownership labels. The current offline suite is 68 policy assertions plus 8 workspace assertions; Docker integration and ecosystem gates remain required release evidence.

## P0 — Kujo toolchain safety

### [blocked] Fix formatter semantic corruption

- Owner: Kujo language repository.
- Evidence: `kujo format --write` rewrote valid Workcell code by changing operator spacing, path separators inside string literals, and CLI flag strings. `kujo format --check` is therefore not a trustworthy gate.
- Workcell action: keep manually reviewed formatting and use `kujo check`, lint review, tests, and `git diff --check` until the formatter is fixed.
- Acceptance: formatter round-trip tests prove parse/AST equivalence for operators, strings, paths, imports, arrays, dictionaries, and CLI flags; Workcell `format --check` passes without semantic changes.

### [blocked] Reduce false-positive linter warnings

- Owner: Kujo language repository.
- Evidence: `kujo lint` exits 0 but emits widespread `unreachable-code` warnings for valid imported/exported modules.
- Acceptance: module-aware reachability analysis or a reviewed warning baseline distinguishes actionable findings from analyzer noise.

## P0 — Host isolation and secret handling

### [x] Replace broad temporary-workspace permissions

- Owner: Workcell plus Kujo/Docker host design.
- Implemented: default `workspace.run_as: host` resolves the invoking non-root UID/GID, uses owner-only write permissions, and supports explicit fixed non-root UID/GID values with fail-closed host `chown`.
- Acceptance status: offline coverage and compatibility documentation pass; Linux/rootless Docker evidence remains host-dependent.

### [blocked: Kujo process API] Add bounded streaming output and streaming redaction

- Owner: Kujo process API plus Workcell runtime.
- Implemented locally: per-stream output caps, truncation metadata, timeout log collection, and redaction before persisted logs/receipts.
- External blocker: Kujo `spawn_process` exposes bounded completion results but no streaming callback/redaction hook; incremental redaction and signal cancellation require a coordinated Kujo process API change.

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

### [blocked: Kujo process API] Add explicit cancellation handling

- Owner: Kujo process API plus Workcell.
- Goal: handle user interruption and parent-process termination without orphaning Docker containers or losing receipts.
- External blocker: the current Kujo runtime has timeout results but no user-signal/cancellation hook exposed to Workcell. Workcell already performs labeled stop/remove cleanup for timeouts and startup failures; true parent-signal receipts require the coordinated process API change.

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

- [deferred optional] RunLedger adapter for importing completed Workcell receipts without duplicating the local receipt schema.
- [deferred optional] ChangeBucket adapter for optional bounded change-risk reports inside a run.
- [deferred optional] ShipCheck/Fence verification hooks with explicit opt-in and separate verification status.
- [deferred optional] PackWrite/Muzzle context packaging adapters once stable contracts justify the dependency.
- Podman, gVisor/Kata, remote, and microVM runtime adapters behind the existing runtime boundary.

## Out of repository scope for the next Workcell-only session

- Provisioning a production rootless/microVM fleet.
- Operating a transparent egress proxy or domain policy service.
- Organization-wide cosign key rotation, Rekor policy, registry authorization, and vulnerability scanning.
- Modifying the Kujo compiler/runtime or formatter without a coordinated Kujo-repository change.

## Suggested next-session order

1. Coordinate Kujo formatter/linter/process-API changes; these are the remaining toolchain blockers.
2. Rerun Docker integration, doctor, and ecosystem gates on an available daemon, including the verification example and resource inventory.
3. Add optional ecosystem adapters only when their stable CLI contracts and ownership are approved.
