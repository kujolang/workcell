# Action

- Wrapped `create_dir` failures in `ensure_dir` and return `false` instead of allowing a Kujo VM crash.
- Made `run_workcell` require successful creation and directory status for both the output root and run directory before creating a workspace.
- Added regressions for occupied directory creation and occupied coordinator output paths.
- Added `docs/ci-status.md` and linked it from the README with the authoritative GitHub billing failure.
- Updated release evidence to 176 offline Workcell assertions plus 18 workspace and 5 stress assertions, with 199 counted release assertions.
