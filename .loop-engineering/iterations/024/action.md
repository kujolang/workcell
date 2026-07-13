# Action

- Guarded `WORKCELL_PERF_FILES` integer parsing and preserved the bounded 200-file default when parsing fails.
- Added the oversized environment value to `tests/run.sh` so the malformed-input path is continuously exercised.
- Updated build, development, hardening, and backlog evidence docs.
- Targeted probe reproduced a VM crash before the fix and completed with the bounded default after it.
