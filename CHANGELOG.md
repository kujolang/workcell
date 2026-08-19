# Changelog

## Unreleased

- Fixed a secret leak in persisted run evidence: `changes.patch` recorded declared secret values verbatim and sealed them into `manifest.json`. Declared secret values and their common base64 encodings are now redacted from the patch before it is written, on the same unconditional terms as `stdout.log` and `stderr.log`.
- Escalated `artifacts.secret_action: reject` to the Git patch: a run whose patch held a declared secret now fails and the patch is not persisted. Receipts warn when patch redaction changed the persisted evidence.

## 1.0.0 - 2026-08-08

- Declared the local and CI Docker/Podman CLI, definition, receipt, verification, declared-artifact, cleanup, and recovery contracts stable.
- Pinned the released Kujo 1.0.0 runtime commit and aligned product, package, CLI, receipt, image-label, report, documentation, and release-artifact version metadata.
- Added version-drift and local Markdown-link gates, release artifact provenance and checksum generation, and a tag-triggered workflow that runs the real release gates before uploading workflow artifacts.
- Documented supported Linux and macOS host classes, installation, upgrade compatibility, pre-tag verification, rollback, and the post-approval tag and GitHub Release procedure.
- Retained explicit limits: Workcell does not protect a compromised daemon or host kernel, provide microVM or hosted multi-tenant isolation, provision egress infrastructure, govern images or signing keys, set retention policy, or certify compliance.

### Pre-1.0 hardening

- Hardened CLI inspection failures, global help/version positional validation, verification-container startup cleanup, and host-control environment denial for cloud credentials and runtime selectors.
- Added fake-runtime regression contracts for cleanup behavior and refreshed the release evidence to 220 passing assertions.
- Hardened workspace ownership markers against symlink spoofing, made missing-container removal idempotent, rejected null output requests, and restored the stable container-startup exit-code contract with dedicated regressions.
- Made stop cleanup case-insensitive and tolerant of Docker/Podman missing-container error variants, with a fake-runtime contract covering no-such, no-container, and not-found messages.
- Hardened workspace scan depth accounting: scans now report observed depth and fail closed when file entries exceed the configured depth limit.
- Hardened workspace and CLI API boundaries: unsupported workspace strategies, malformed run identifiers, and non-string CLI tokens now fail closed with regression coverage; release evidence is now 225 passing assertions.
- Closed a remaining CLI parser crash when a value option was followed by a non-string token; structured argument validation now covers both standalone and option-value tokens.
- Hardened definition validation against null secret sections and rejected non-boolean image ensure options before daemon/image operations; current release evidence is 228 passing assertions.

## 0.1.0

- Initial Docker-first Workcell MVP.
- Added JSON definition validation, restrictive policy construction, disposable Git workspaces, artifact boundaries, receipts, doctor diagnostics, examples, and offline contract tests.
