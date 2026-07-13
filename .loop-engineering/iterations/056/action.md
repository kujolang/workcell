# Action

- Added duplicate-path detection to manifest verification.
- Manifest verification now enumerates the run directory and requires matching file count, byte total, and path coverage.
- Added duplicate-entry and omitted-entry regressions.
- Evidence after the change: 188 Workcell assertions, 20 workspace assertions, 5 stress assertions, and 213 counted release assertions; Docker integration, OCI smoke, egress, and concurrent load passed.
