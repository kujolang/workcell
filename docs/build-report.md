# Workcell Build Report

## Built

The initial Workcell MVP is implemented substantively in Kujo with a thin launcher. It includes JSON definition loading/validation, Docker policy construction, clean Git worktree/clone preparation, Docker build/pull/reuse, bounded execution, incremental redacted stream logs, explicit cancellation, output capture, patch/change collection, declared artifact export, receipt writing, doctor diagnostics, and ownership-scoped cleanup.

## Verification run

- Kujo checker: `KUJO=../kujo/target/release/kujo ./tests/run.sh --check-only` — passed for `main.kujo`, all source modules, and the test module.
- Offline tests: `KUJO=../kujo/target/release/kujo ./tests/run.sh` — passed 121 definition/policy/artifact/verification assertions, 11 workspace patch/change-report/cleanup/scan assertions, and 5 deterministic stress assertions, including path-safety, dry-run lifecycle, manifest verification/tamper detection, adversarial request rejection, custom-network, managed egress declarations, custom security profiles, duplicate-input validation, malformed network-type validation, overflow-safe numeric validation for timeouts, workspace identities, memory, partial sections, and fail-closed exported API handling for policy, summaries, daemon security, verification, integrations, image build/ensure, receipts, and container policies, receipt redaction, partial-default, empty-secret, base64-derived-secret, binary-report, digest, signature-key, namespace, workspace ownership/scan, active-workspace cleanup protection, empty-orphan recovery, disappearing-workspace handling, schema/help, backend-aware CLI output, RunLedger finish failure reporting, verification command redaction, optional integration evidence, explicit dry-run integration skips, and null-output regressions.
- Structured report: `KUJO=../kujo/target/release/kujo ./tests/release_report.sh` — passed with `workcell-report/v1`, 137 counted assertions, per-suite elapsed time/exit codes, and explicit skipped Docker/Podman/ecosystem deployment gates.
- Report resilience: `KUJO=../kujo/target/release/kujo ./tests/report_contract.sh` — passed valid report rendering and malformed numeric metric/exit evidence handling without a VM crash.
- Performance harness resilience: the default suite also runs `WORKCELL_PERF_FILES=999999999999999999999` and confirms the bounded 200-file signal completes without a VM crash.
- CLI smoke: `./bin/workcell help`, `init`, `validate`, and `inspect --json` — passed.
- Docker integration: `KUJO=../kujo/target/release/kujo ./tests/docker_integration.sh` — passed against Docker server 29.5.2 through Colima, including success, streamed stdout/stderr log files, offline manifest verification and tamper detection, explicit non-cancelled receipt metadata, edit, failure, timeout, symlink, active-container preservation, and label-scoped cleanup scenarios.
- Podman integration: `REQUIRE_BACKEND=true KUJO=../kujo/target/release/kujo ./tests/docker_integration.sh podman` — passed against rootless Podman 4.9.3 in the Colima Linux VM, including the same policy, identity, network, provenance, verification, failure, timeout, and cleanup contracts.
- Egress evidence: `REQUIRE_BACKEND=true KUJO=../kujo/target/release/kujo ./tests/egress_integration.sh docker` and `... ./tests/egress_integration.sh podman` — both passed; each proved an allowlisted internal destination and blocked external DNS on its selected backend.
- Concurrent load evidence: `REQUIRE_BACKEND=true KUJO=../kujo/target/release/kujo ./tests/load_integration.sh docker` passed on the local Docker daemon; the same four-run contract passed for rootless Docker and rootless Podman in the Colima Linux VM, proving unique run IDs, source immutability, artifact/manifest verification, and runtime cleanup.
- Podman security contract: `KUJO=../kujo/target/release/kujo ./tests/podman_security_contract.sh` — passed; a fake Podman CLI with disabled seccomp was rejected before workload execution.
- Pinned Kujo example image: `./docker/kujo/build-local.sh ../kujo` passed using Kujo commit `475fb1a6ee88b53b799cd1a62e5e771516106da8` and digest-pinned Rust/Alpine base images.
- Clean-repository runtime failure path: `workcell run --json` produced a receipt and complete workspace cleanup, returning stable code `4` for Docker/image preparation failure.
- Dry-run lifecycle: validated, prepared, verified, exported, cleaned, and recorded a receipt with elapsed time and execution/artifact verification explicitly false.
- Change reporting: successful runs write both `changes.patch` and structured `changes.json` with source commit, patch bytes, per-file status/binary metadata, and summary counts.
- Image preparation: runtime build contexts use BuildKit/buildx when available, digest pins are verified before launch, and a legacy Docker builder remains a compatibility fallback.
- Patch generation includes untracked files and has a dedicated workspace contract test.
- Symlink safety: source worktrees, output roots, and declared artifact sources containing symlinks are rejected; disposable workspaces use an ownership marker for cleanup.
- Failure categorization: Docker workload exit code 125 is retained in the receipt but classified as workload failure (CLI code 7), while Docker startup failures remain code 5.
- Output boundary: absolute `--output` paths are limited to `TMPDIR` or the repository `.workcell` directory; traversal and arbitrary host destinations are rejected.
- Process lifecycle: Kujo commit `0f77781` provides bounded channel/file stream sinks, chunk-boundary-safe exact/base64 redaction, SIGINT/SIGTERM and cancellation-marker handling, and `cancelled` completion metadata; Workcell records it and uses the existing labeled cleanup path.
- Image ownership: Workcell-built images carry Workcell, run ID, project, and version labels; integration inspects all four labels after a forced rebuild.
- Loop gates: Kujo checks, Kujo tests, CLI smoke, and `git diff --check` passed.

## Toolchain notes

Kujo commits `ff31153` and `7ef6eb8` made formatting syntax-preserving and reachability analysis token-aware. Every Workcell `.kujo` file now passes `kujo format --check`; every source module passes `kujo lint --json` with zero findings; formatted temporary copies pass `kujo check`. The formatter intentionally defers line wrapping until Kujo has an AST-aware pass.

## Artifacts

Run artifacts are written under `.workcell/runs/<run-id>/`. The source tree, test fixtures, docs, ADRs, and Docker image definition are included in the repository.
