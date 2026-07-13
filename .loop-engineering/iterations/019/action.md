# Action

- Guarded network default expansion so it only indexes object-valued network sections; malformed section types now reach the validator and return a structured error.
- Added a regression assertion for `resolve_definition({"network": null})` followed by validation.
- Threaded the relative artifact path through recursive redaction so write-failure diagnostics cannot reference an undefined local.
- Updated security, hardening, backlog, development, tooling, and build evidence docs to 102/11/5 offline assertions and 118 release assertions.
- Committed and pushed as `27d22d3`, `53e4286`, and `32f4bf4`.
