# Action

- Added bounded duplicate-name validation for verification commands.
- Kept command execution indexed and deterministic while requiring unique public result names.
- Added a duplicate-name regression.
- Evidence after the change: 188 Workcell assertions, 20 workspace assertions, 5 stress assertions, and 213 counted release assertions; Docker integration, OCI smoke, egress, and concurrent load passed.
