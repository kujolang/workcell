# Workcell Tooling Report

## Inspected

Kujo, PackWrite, RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, Muzzle, Agents SDK, and Dispatch were reviewed for layout, CLI, policy, receipt, artifact, lifecycle, and evidence conventions. The detailed audit is in [repository-conventions.md](repository-conventions.md).

## Used

- Kujo runtime checker and VM for every Workcell source/test module.
- RunLedger to start the engineering runs `2026-07-11-codex-build-kujo-workcell-mvp-001` and `2026-07-11-gpt-5-workcell-completion-audit-001`; the later Docker-backed audit completed after Colima was installed and the repository was pushed.
- Kujo loop-engineering harness to configure deterministic gates, evidence, commits, push behavior, and Strata consolidation.
- ChangeBucket measured a clean worktree at 0 changed files after the final commits.
- ShipCheck gate completed with 16/16 checks passed, 0 warnings, and 0 errors.
- Fence validated `fence.toml` and checked 10 files / 24 imports with 0 violations and 0 warnings.
- CaseFile captured the Docker-unavailable failure as `.casefile/2026-07-10-214039-dockerunavailable/` (ignored generated evidence).
- The Docker integration script passed against the local Colima daemon, with the run logs retained outside Git under `.workcell/review/2026-07-11-full-run`.
- The final offline suite passed 53 definition/policy assertions and 8 workspace patch/change-report assertions; example definitions and CLI smoke fixtures also passed.
- Kujo lint exited successfully but emitted widespread unreachable-code warnings on valid module/import patterns. Kujo format --check reported four modules needing formatting; kujo format --write was tested and found semantically unsafe because it altered operators, path separators inside string literals, and CLI flag strings, so the generated rewrites were discarded and not committed.

## Integration gaps

The sibling tools are standalone Kujo CLIs rather than stable importable packages. Workcell therefore uses local adapters and documents future direct integration instead of duplicating or tightly coupling to their repositories. Docker-backed success and failure receipts are now available from the local integration run.
