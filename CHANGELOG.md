# Changelog

## Unreleased

## 1.1.0 - 2026-09-04

### Provider-neutral execution (alpha)

- Added the provider-neutral `workcell-definition/v2alpha1`, executable `workcell-backend/v1alpha1` protocol, `workcell-receipt/v2alpha1`, strict semantic capability negotiation, host profiles, and a core-owned `resolve → provision → prepare → execute → collect → export → destroy → record` lifecycle.
- Routed portable workloads through built-in Docker and Podman without changing the stable v1 OCI behavior. gVisor and Kata are selectable OCI substrates through `engine_runtime`, not misleading top-level providers.
- Added digest-pinned official external adapters for E2B, Vercel Sandbox, and Daytona. Provider SDK dependencies remain outside Workcell core, and each adapter validates its supported routing, credentials, operation payloads, and result shapes.
- Added explicit backend discovery, portable inspection, deterministic cancellation, ownership-bound recovery, caller correlation context, resource/transfer ceilings, phase timings, and honest provider cost classes with unknown amounts by default.
- Updated development and CI to the exact Kujo 1.2.1 runtime commit in `RUNTIME_VERSION`; the earlier `v1.0.0` tag retains its original Kujo 1.0.0 pin.

### Security and evidence

- Fixed a secret leak in persisted run evidence: declared secret values and common base64 encodings are now redacted from `changes.patch` before it is written and sealed into `manifest.json`. `artifacts.secret_action: reject` now also fails a run whose patch held a declared secret.
- Redact adapter diagnostics and JSONL output at the core trust boundary, including secrets split across events; reject non-UTF-8 output, framing noise, duplicate results, request/result mismatches, malformed operation data, and unbounded output.
- Bound remote workspace and artifact transfer by file count, expanded bytes, depth, archive bytes, and normalized path. Core independently hashes downloads, rejects traversal and non-regular entries, re-applies declared artifact and secret policy, and never exports an entire remote workspace implicitly.
- Persist provision intent before remote allocation, bind handles to run ID plus ownership nonce, require complete ownership-filtered inventory, record partial cleanup, and preserve a recovery-required state when provisioning or destruction is ambiguous.
- Added receipt controls that distinguish requested, accepted, resolved, enforced, provider-claimed, operator-claimed, observed, unsupported, not enforceable, and unknown state. Provider identity or marketing never upgrades evidence authority.
- Restricted credentials to explicitly advertised references, passed only the selected environment value to bundled adapters, rejected ambient SDK fallback, and kept values out of definitions, profiles, protocol requests, receipts, logs, and artifacts.

### Conformance, operations, and agent efficiency

- Added a provider-independent, double-gated live-certification entrypoint, a protected manual CI workflow, bounded external evidence reports, and an end-to-end credential-free fixture contract for every official adapter.
- Added offline adapter conformance, lifecycle/failure/archive fixtures, malformed-protocol corpus tests, credential-redaction tests, integrity-tamper tests, concurrent ownership-isolation tests, portable Docker/Podman contract coverage, and macOS offline CI.
- Hardened loaded-runner timing fixtures and macOS offline runtime expectations, aligned Docker integration expectations with secret-reject patch semantics, and cancel superseded branch/PR CI runs without cancelling release workflow calls.
- Preserved only `PATH` alongside explicitly allowlisted adapter credentials so script and runtime entrypoints work consistently on Linux and macOS without inheriting the rest of the host environment.
- Added profile policy ceilings, compact phase/performance and cost evidence, adapter integrity refresh/check tooling, enterprise deployment gates, and a bounded third-party adapter authoring contract.
- Added single-line `workcell-run-summary/v1` and `workcell-inspect-summary/v1` outputs so agents can consume verdicts, backend identity, policy/capability counts, and evidence paths without embedding full receipts or resolved policies in context.
- Added the complete backend landscape, taxonomy, capability and security matrices, target architecture, contract proposal, risk register, acceptance criteria, and dependency-ordered implementation package under `docs/plans/backend-matrix/`.
- Added a root `MEGA_PROMPT.md` that turns the remaining live certification, contract stabilization, packaging, onboarding, ecosystem integration, provider expansion, enterprise operations, and release work into a dependency-ordered implementation assignment for another engineering agent.

The provider-neutral surface and remote adapters remain alpha. Production promotion requires credential-gated evidence for the exact provider account, plan, region, adapter/API/SDK version, requested controls, latency/cost envelope, recovery path, and zero owned orphans. This source release does not promote any remote adapter.

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
