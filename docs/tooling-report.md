# Workcell Tooling Report

## Inspected

Kujo, PackWrite, RunLedger, ChangeBucket, ShipCheck, Fence, CaseFile, Muzzle, Agents SDK, and Dispatch were reviewed for layout, CLI, policy, receipt, artifact, lifecycle, and evidence conventions. The detailed audit is in [repository-conventions.md](repository-conventions.md).

## Used

- Kujo runtime checker and VM for every Workcell source/test module.
- RunLedger to start the engineering runs `2026-07-11-codex-build-kujo-workcell-mvp-001` and `2026-07-11-gpt-5-workcell-completion-audit-001`; the later Docker-backed audit completed after Colima was installed and the repository was pushed.
- Kujo loop-engineering harness to configure deterministic gates, evidence, commits, push behavior, and Strata consolidation.
- ChangeBucket measured a clean worktree at 0 changed files after the final commits.
- ShipCheck scan/gate completed with 13 passed, 3 warnings, 0 error failures; the gate exited 0.
- Fence validated `fence.toml` and checked 10 files / 24 imports with 0 violations and 0 warnings.
- CaseFile captured the Docker-unavailable failure as `.casefile/2026-07-10-214039-dockerunavailable/` (ignored generated evidence).
- The Docker integration script passed against the local Colima daemon, with the run logs retained outside Git under `.workcell/review/2026-07-11-full-run`.
- The final offline suite passed 39 definition/policy assertions and 7 workspace patch/change-report assertions; example definitions and CLI smoke fixtures also passed.

## Integration gaps

The sibling tools are standalone Kujo CLIs rather than stable importable packages. Workcell therefore uses local adapters and documents future direct integration instead of duplicating or tightly coupling to their repositories. Docker-backed success and failure receipts are now available from the local integration run.
