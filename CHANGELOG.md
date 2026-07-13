# Changelog

## Unreleased

- Hardened CLI inspection failures, global help/version positional validation, verification-container startup cleanup, and host-control environment denial for cloud credentials and runtime selectors.
- Added fake-runtime regression contracts for cleanup behavior and refreshed the release evidence to 218 passing assertions.
- Hardened workspace ownership markers against symlink spoofing, made missing-container removal idempotent, rejected null output requests, and restored the stable container-startup exit-code contract with dedicated regressions.

## 0.1.0

- Initial Docker-first Workcell MVP.
- Added JSON definition validation, restrictive policy construction, disposable Git workspaces, artifact boundaries, receipts, doctor diagnostics, examples, and offline contract tests.
