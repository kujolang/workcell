# Next Workcell Hardening Backlog

This is the next-session work list produced by the codebase review on 2026-07-11. Items are intentionally separated by ownership so repository work is not confused with Docker-host or Kujo-toolchain work.

## Review result

The repository is a credible, tested Kujo-native Docker MVP. It is not a universally isolated enterprise sandbox: it trusts the Docker daemon and host kernel, has no streaming redaction layer, and relies on operators for rootless/VM boundaries, egress enforcement, and image-signing governance. The current local daemon reports seccomp/AppArmor but is not rootless.

The review added duplicate-input validation, faster changed-path indexing, stricter ownership-marker validation, and image ownership labels. The final offline suite is 53 policy assertions plus 8 workspace assertions; Docker integration and ecosystem gates remain required release evidence.

## P0 — Kujo toolchain safety

### Fix formatter semantic corruption

- Owner: Kujo language repository.
- Evidence: `kujo format --write` rewrote valid Workcell code by changing operator spacing, path separators inside string literals, and CLI flag strings. `kujo format --check` is therefore not a trustworthy gate.
- Workcell action: keep manually reviewed formatting and use `kujo check`, lint review, tests, and `git diff --check` until the formatter is fixed.
- Acceptance: formatter round-trip tests prove parse/AST equivalence for operators, strings, paths, imports, arrays, dictionaries, and CLI flags; Workcell `format --check` passes without semantic changes.

### Reduce false-positive linter warnings

- Owner: Kujo language repository.
- Evidence: `kujo lint` exits 0 but emits widespread `unreachable-code` warnings for valid imported/exported modules.
- Acceptance: module-aware reachability analysis or a reviewed warning baseline distinguishes actionable findings from analyzer noise.

## P0 — Host isolation and secret handling

### Replace broad temporary-workspace permissions

- Owner: Workcell plus Kujo/Docker host design.
- Risk: the current container UID contract uses recursive `a+rwX` permissions so UID 65532 can write the bind-mounted worktree. On a shared Linux host, that broadens local-user access to the temporary workspace.
- Acceptance: support a documented UID/GID mapping or rootless-compatible ownership strategy that keeps the container writable without world-writable temporary trees; add a Linux integration test and preserve non-root execution.

### Add bounded streaming output and streaming redaction

- Owner: Kujo process API plus Workcell runtime.
- Risk: current capture is completion-oriented and redacts after process return. A workload can emit large output or transformed secrets before the final redaction pass.
- Acceptance: bounded stdout/stderr streaming with backpressure, truncation metadata, incremental exact/base64 redaction, timeout cancellation, and tests proving no secret crosses the persisted log boundary.

### Add artifact content policy hooks

- Owner: Workcell.
- Risk: declared artifacts are path-safe but may contain secrets or oversized data.
- Acceptance: optional per-artifact max bytes, file-count limits, content-type policy, and a reject/redact hook before export; receipts explain why an artifact was rejected.

## P1 — Runtime and lifecycle functionality

### Add declarative verification commands

- Owner: Workcell.
- Goal: distinguish “the workload exited successfully” from “the produced change passed project verification.”
- Acceptance: a versioned `verification` block can run declared checks inside the disposable workspace, records command/exit/output status separately, and never weakens container policy. Existing definitions remain valid through safe defaults.

### Add a runtime resource inventory

- Owner: Workcell.
- Goal: make `clean` and incident response explain all Workcell-owned containers, images, networks, and preserved workspaces without touching unrelated resources.
- Acceptance: `clean --json` supports dry-run inventory, ownership labels are verified, image retention is explicit, and cleanup failure reports identify exact resources.

### Improve image provenance

- Owner: Workcell.
- Goal: make receipts useful for local images with no `RepoDigests` and for multi-platform images.
- Acceptance: record a stable observed image ID/config digest fallback, platform, builder, labels, and the verified digest source; digest pin comparisons remain fail-closed and documented.

### Add explicit cancellation handling

- Owner: Kujo process API plus Workcell.
- Goal: handle user interruption and parent-process termination without orphaning Docker containers or losing receipts.
- Acceptance: signal/cancellation hooks attempt stop, collect logs, write a partial receipt, remove only the labeled container, and return a documented cancellation code.

## P1 — Performance and scale

### Batch Git change collection

- Owner: Workcell.
- Goal: reduce subprocess count for repositories with many untracked files.
- Acceptance: use NUL-delimited Git output and one batched binary/status strategy where available; add a fixture with thousands of files and record process-count/runtime evidence without weakening path safety.

### Bound workspace scans

- Owner: Workcell.
- Goal: prevent symlink and artifact scans from consuming unbounded memory or time on large trees.
- Acceptance: configurable file-count/byte/depth limits, deterministic scan errors, receipt diagnostics, and integration coverage for limit failures.

### Reuse daemon/image security probes per run

- Owner: Workcell.
- Goal: avoid repeated Docker info/image inspect calls while keeping fail-closed behavior.
- Acceptance: the coordinator passes one immutable preparation context through image verification and launch; tests prove no security check is skipped or cached across separate runs.

## P1 — Universal usability and presentation

### Add a first-class verification example

- Owner: Workcell.
- Goal: provide a runnable example that edits or builds a repository and then runs checks, with receipt fields showing execution versus verification.
- Acceptance: example works offline after image preparation, exports logs/receipt/patch, leaves the source repository unchanged, and is exercised in CI where Docker is available.

### Add machine-readable schema/help output

- Owner: Workcell.
- Goal: make Workcell easier to integrate into agents, editors, and CI generators.
- Acceptance: `validate --schema` or equivalent emits the supported JSON schema/field contract, `help --json` exposes commands/options/exit codes, and outputs are versioned.

### Improve release metadata DRYness

- Owner: Workcell.
- Evidence: version `0.1.0` currently appears in `VERSION`, `kujo.toml`, `kennel.toml`, `CHANGELOG.md`, and the CLI source.
- Acceptance: define an authoritative version source and generate or validate the other projections without making the launcher depend on the caller's working directory.

### Add universal platform documentation

- Owner: Workcell.
- Goal: clearly describe Linux, macOS/Colima, rootless Docker, Docker Desktop, and unsupported host behavior.
- Acceptance: a compatibility matrix covers permissions, networking, seccomp/AppArmor, rootless, image builds, and known differences; each claim has a runnable doctor or integration check.

## P2 — Optional ecosystem integrations

- RunLedger adapter for importing completed Workcell receipts without duplicating the local receipt schema.
- ChangeBucket adapter for optional bounded change-risk reports inside a run.
- ShipCheck/Fence verification hooks with explicit opt-in and separate verification status.
- PackWrite/Muzzle context packaging adapters once stable contracts justify the dependency.
- Podman, gVisor/Kata, remote, and microVM runtime adapters behind the existing runtime boundary.

## Out of repository scope for the next Workcell-only session

- Provisioning a production rootless/microVM fleet.
- Operating a transparent egress proxy or domain policy service.
- Organization-wide cosign key rotation, Rekor policy, registry authorization, and vulnerability scanning.
- Modifying the Kujo compiler/runtime or formatter without a coordinated Kujo-repository change.

## Suggested next-session order

1. Resolve the Kujo formatter contract or record an approved exception.
2. Design the UID/GID and streaming-output contracts before changing runtime behavior.
3. Implement artifact limits and declarative verification with backward-compatible defaults.
4. Add batch Git/scan performance benchmarks and resource inventory tests.
5. Finish README/compatibility/schema presentation and rerun every release gate.
