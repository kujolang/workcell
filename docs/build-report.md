# Workcell Build Report

## Built

The initial Workcell MVP is implemented substantively in Kujo with a thin launcher. It includes JSON definition loading/validation, Docker policy construction, clean Git worktree/clone preparation, Docker build/pull/reuse, bounded execution, output capture, patch/change collection, declared artifact export, receipt writing, doctor diagnostics, and ownership-scoped cleanup.

## Verification run

- Kujo checker: `KUJO=../kujo/target/release/kujo ./tests/run.sh --check-only` — passed for `main.kujo`, all source modules, and the test module.
- Offline tests: `KUJO=../kujo/target/release/kujo ./tests/run.sh` — passed 32 definition/policy assertions plus 7 workspace patch/change-report assertions, including path-safety and dry-run lifecycle checks.
- CLI smoke: `./bin/workcell help`, `init`, `validate`, and `inspect --json` — passed.
- Docker integration: `./tests/docker_integration.sh` — skipped because the Docker CLI/daemon is unavailable in this environment.
- Clean-repository runtime failure path: `workcell run --json` produced a receipt and complete workspace cleanup, returning stable code `4` for Docker/image preparation failure.
- Dry-run lifecycle: validated, prepared, verified, exported, cleaned, and recorded a receipt with elapsed time and execution/artifact verification explicitly false.
- Change reporting: successful runs write both `changes.patch` and structured `changes.json` with source commit, patch bytes, per-file status/binary metadata, and summary counts.
- Patch generation includes untracked files and has a dedicated workspace contract test.
- Symlink safety: source worktrees, output roots, and declared artifact sources containing symlinks are rejected; disposable workspaces use an ownership marker for cleanup.
- Loop gates: Kujo checks, Kujo tests, CLI smoke, and `git diff --check` passed.

## Artifacts

Run artifacts are written under `.workcell/runs/<run-id>/`. The source tree, test fixtures, docs, ADRs, and Docker image definition are included in the repository.
