# Action

- Changed `scan_artifact` to return an inspection error when a declared secret policy cannot read an artifact as text.
- Changed `redact_tree` to fail closed on unreadable files and avoided unnecessary redaction traversal when no secret values exist.
- Added binary-artifact regression assertions for both `reject` and `redact` policies.
- Updated security, hardening, backlog, development, tooling, and build evidence docs to reflect the 101/11/5 offline suite and 117 release count.
- Committed and pushed as `876de0e` (`fix: fail closed on binary secret artifacts`).
