# Workcell Tooling Report

## Inspected

Kujo, PackWrite, RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, Muzzle, Agents SDK, and Dispatch were reviewed for layout, CLI, policy, receipt, artifact, lifecycle, and evidence conventions. The detailed audit is in [repository-conventions.md](repository-conventions.md).

## Used

- Kujo runtime checker and VM for every Workcell source/test module.
- RunLedger to start the engineering runs `2026-07-11-codex-build-kujo-workcell-mvp-001` and `2026-07-11-gpt-5-workcell-completion-audit-001`; the later Docker-backed audit completed after Colima was installed and the repository was pushed.
- Kujo loop-engineering harness to configure deterministic gates, evidence, commits, push behavior, and Strata consolidation.
- ChangeBucket measured a clean worktree at 0 changed files after the final commits.
- ShipCheck gate completed with 16/16 checks passed, 0 warnings, and 0 errors.
- Fence validates `fence.toml` and checks the runtime/integration boundary with 12 files / 30 imports and 0 violations and 0 warnings.
- CaseFile captured the Docker-unavailable failure as `.casefile/2026-07-10-214039-dockerunavailable/` (ignored generated evidence).
- The Docker integration script passed against the local Colima daemon, with the run logs retained outside Git under `.workcell/review/2026-07-11-full-run`.
- Kujo commit `0f77781` added bounded process stream channels/file sinks, incremental redaction, cancellation hooks, and regression coverage; Workcell integration now persists redacted stdout/stderr stream logs and cancellation metadata.
- The current offline suite passed 78 definition/policy/artifact/verification assertions and 8 workspace patch/change-report assertions; the adversarial suite, 200-file performance signal, example definitions, schema/help, CLI smoke, and version-consistency fixtures also passed.
- Kujo commits `ff31153` and `7ef6eb8` made formatter output syntax-preserving and reachability analysis token-aware. Every Workcell `.kujo` file passes `kujo format --check`, every source module passes `kujo lint --json` with zero findings, and formatted temporary copies pass `kujo check`; line wrapping remains conservative until an AST-aware pass exists.

## Integration gaps

The sibling tools are standalone Kujo CLIs rather than stable importable packages. Workcell therefore uses local adapters and documents future direct integration instead of duplicating or tightly coupling to their repositories. Docker-backed success and failure receipts are now available from the local integration run.
