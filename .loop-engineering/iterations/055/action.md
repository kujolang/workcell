# Action

- Added normalized declaration tracking in `export_declared_with_policy`.
- Duplicate and ancestor/descendant artifact declarations now fail closed before copying.
- Added duplicate and redaction-overlap regressions.
- Evidence after the change: 188 Workcell assertions, 20 workspace assertions, 5 stress assertions, and 213 counted release assertions; Docker integration, OCI smoke, egress, and concurrent load passed.
