# Changelog

## Unreleased

- Hardened CLI inspection failures, global help/version positional validation, verification-container startup cleanup, and host-control environment denial for cloud credentials and runtime selectors.
- Added fake-runtime regression contracts for cleanup behavior and refreshed the release evidence to 220 passing assertions.
- Hardened workspace ownership markers against symlink spoofing, made missing-container removal idempotent, rejected null output requests, and restored the stable container-startup exit-code contract with dedicated regressions.
- Made stop cleanup case-insensitive and tolerant of Docker/Podman missing-container error variants, with a fake-runtime contract covering no-such, no-container, and not-found messages.
- Hardened workspace scan depth accounting: scans now report observed depth and fail closed when file entries exceed the configured depth limit.
- Hardened workspace and CLI API boundaries: unsupported workspace strategies, malformed run identifiers, and non-string CLI tokens now fail closed with regression coverage; release evidence is now 225 passing assertions.

## 0.1.0

- Initial Docker-first Workcell MVP.
- Added JSON definition validation, restrictive policy construction, disposable Git workspaces, artifact boundaries, receipts, doctor diagnostics, examples, and offline contract tests.
