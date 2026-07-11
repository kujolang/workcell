# Workcell Build Report

## Built

The initial Workcell MVP is implemented substantively in Kujo with a thin launcher. It includes JSON definition loading/validation, Docker policy construction, clean Git worktree/clone preparation, Docker build/pull/reuse, bounded execution, output capture, patch/change collection, declared artifact export, receipt writing, doctor diagnostics, and ownership-scoped cleanup.

## Verification run

- Kujo checker: `KUJO=../kujo/target/release/kujo ./tests/run.sh --check-only` — passed for `main.kujo`, all source modules, and the test module.
- Offline tests: `KUJO=../kujo/target/release/kujo ./tests/run.sh` — passed 51 definition/policy assertions plus 7 workspace patch/change-report assertions, including path-safety, dry-run lifecycle, custom-network, custom security profiles, receipt redaction, partial-default, empty-secret, base64-derived-secret, binary-report, digest, signature-key, namespace, and null-output regressions.
- CLI smoke: `./bin/workcell help`, `init`, `validate`, and `inspect --json` — passed.
- Docker integration: `TMPDIR=/var/folders/... KUJO=../kujo/target/release/kujo ./tests/docker_integration.sh` — passed against Docker server 29.5.2 through Colima, including success, edit, failure, timeout, symlink, and label-scoped cleanup scenarios.
- Clean-repository runtime failure path: `workcell run --json` produced a receipt and complete workspace cleanup, returning stable code `4` for Docker/image preparation failure.
- Dry-run lifecycle: validated, prepared, verified, exported, cleaned, and recorded a receipt with elapsed time and execution/artifact verification explicitly false.
- Change reporting: successful runs write both `changes.patch` and structured `changes.json` with source commit, patch bytes, per-file status/binary metadata, and summary counts.
- Image preparation: runtime build contexts use BuildKit/buildx when available, digest pins are verified before launch, and a legacy Docker builder remains a compatibility fallback.
- Patch generation includes untracked files and has a dedicated workspace contract test.
- Symlink safety: source worktrees, output roots, and declared artifact sources containing symlinks are rejected; disposable workspaces use an ownership marker for cleanup.
- Failure categorization: Docker workload exit code 125 is retained in the receipt but classified as workload failure (CLI code 7), while Docker startup failures remain code 5.
- Output boundary: absolute `--output` paths are limited to `TMPDIR` or the repository `.workcell` directory; traversal and arbitrary host destinations are rejected.
- Loop gates: Kujo checks, Kujo tests, CLI smoke, and `git diff --check` passed.

## Artifacts

Run artifacts are written under `.workcell/runs/<run-id>/`. The source tree, test fixtures, docs, ADRs, and Docker image definition are included in the repository.
