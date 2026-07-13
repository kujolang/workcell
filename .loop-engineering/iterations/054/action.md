# Action

- Wrapped stale-workspace root and orphan-directory listings in structured error handling.
- Permission-denied orphan directories are now preserved and reported in `skipped` rather than crashing or being removed.
- Added a permission-denied orphan cleanup regression.
- Evidence baseline after the change: 183 Workcell assertions, 20 workspace assertions, 5 stress assertions, and 208 counted release assertions.
