# Offline testing and backend conformance

## Testing architecture

Normal WorkCell development must remain credential-free and network-free. Each official adapter repository provides a deterministic simulator and committed fixtures; WorkCell core provides the conformance runner and a reference fixture backend.

```text
core unit tests
  -> backend protocol fixture process
  -> generic conformance suites
  -> adapter request/response fixture suites
  -> narrow opt-in live smoke
  -> scheduled provider drift smoke
```

## Fixture corpus

Every adapter commits redacted, bounded fixtures for:

- describe and profile-schema output;
- capability resolution by plan/class/region variants;
- provision success, idempotent replay, quota, auth, rate limit, timeout;
- workspace upload/materialization and digest mismatch;
- workload success, non-zero exit, startup failure, provider exception;
- stdout/stderr streaming, buffering, reorder, reconnect, truncation, missing tail;
- command cancel, destroy fallback, terminal-unknown;
- artifact success, missing declared path, traversal, symlink, duplicate, oversize, partial transfer, digest mismatch;
- metrics present/partial/absent;
- cleanup success, absent, partial, provider unavailable, ownership mismatch;
- orphan inventory/recovery;
- credential and signed-URL redaction;
- API deprecation/capability drift.

Fixtures record adapter-normalized protocol frames, not raw credential-bearing HTTP cassettes. HTTP request fixtures replace auth and signed URLs with typed placeholders and assert that secrets never reach snapshots.

## Base conformance suite

A third-party adapter must pass:

1. manifest/describe contract and version negotiation;
2. definition intent resolution with unsupported required capability rejected before provision;
3. idempotent provision/prepare/destroy;
4. exclusive ownership markers and same-name unowned-resource protection;
5. portable workspace package digest confirmation;
6. argv fidelity, working directory, explicit environment, secret canary handling;
7. success/non-zero/startup/timeout/cancel/terminal-unknown normalization;
8. bounded logs and honest stream-quality metadata;
9. declared-only artifact export and path/size/hash defenses;
10. resource inventory and crash recovery;
11. receipt normalization and offline manifest verification;
12. provider/API/adapter/runtime identity capture;
13. no hidden workload retry;
14. protocol/event/output bounds and malformed-adapter handling.

## Capability-specific suites

Run only when execution-time resolution advertises the capability:

- CPU/memory/PID/disk limits: exceed the boundary and collect provider/observation evidence without host harm.
- network none: DNS, public IP, metadata, private address, provider-service, and inbound checks where safe.
- domain/CIDR allowlist: allowed and denied destinations, redirect, DNS change, non-TLS/protocol behavior.
- cancel process: cooperative signal, escalation, terminal state.
- pause/resume: define process-memory behavior and verify it; disk-only suspend runs snapshot tests instead.
- snapshot: identity, immutability, ownership, expiration, restore digest, deletion.
- streaming logs: incremental delivery, backpressure, reconnect, per-stream order.
- metrics/cost: units, intervals, source, completeness, no inferred dollar value.
- custom image/digest: resolved provider identity and mismatch failure.

Advertising a capability and failing its suite fails conformance. Not advertising it is allowed unless the target release tier requires it.

## OCI zero-regression gate

Before any remote adapter merges:

- existing v1 schema and CLI fixtures pass unchanged;
- current fake Docker/Podman lifecycle and cleanup tests pass through the extracted adapter interface;
- Docker and Podman doctor, integration, load, egress, verification, receipt, manifest, and cleanup gates pass on their supported host classes;
- existing v1 receipt fields and exit meanings remain stable;
- policy inspection produces equivalent engine argv for the same definition;
- performance regression stays within the approved measured budget.

`tests/portable_oci_contract.sh` is the opt-in end-to-end vertical-slice gate: with `WORKCELL_LIVE_PORTABLE_OCI=1`, one unchanged v2 workload runs through the built-in Docker profile without a manifest, emits receipt v2, verifies offline, leaves the source clean, and proves no labeled container remains. The normal suite skips this live engine/image gate so offline development never depends on a registry or Docker daemon.

Golden argv comparisons are appropriate for the OCI shared driver. They are not a universal backend contract.

## Live provider tests

Live tests are explicit and narrow:

- environment gate such as `WORKCELL_LIVE_E2B=1` plus named profile;
- a minimal immutable fixture image/workspace;
- low resource/time ceilings and spend budget;
- unique ownership nonce;
- always attempt destroy, then run inventory to prove no orphan;
- retain redacted receipt and provider IDs for the exact adapter commit;
- never run on ordinary pull requests or forks with secrets;
- test only one or two representative capability profiles, not provider fleet load.

Live tests prove behavior for one account/plan/region/time. They do not convert provider claims into universal certification.

## Drift management

- Capture provider API/SDK version in every fixture and receipt.
- Scheduled smoke jobs run per official adapter repository, not WorkCell core runtime.
- Compare live `describe/resolve` output with approved capability snapshots; open an issue on removed/changed consequential fields.
- Fixture refresh is a reviewed change that names provider changelog/docs and reruns conformance.
- Adapters emit deprecation warnings with deadline/source and fail closed after an incompatible version boundary.
- Compatibility status is static release metadata (`verified`, `degraded`, `blocked`, `unknown`) generated from latest smoke evidence; runtime does not call a central status service.
- Provider issue generation may use repository automation, but execution never depends on it.

## Clean-machine verification

The implementation release gate uses a clean checkout with only the pinned Kujo runtime, Git, jq, and the selected built-in engine for core. External adapter gates install their declared runtime/SDK in their own environment. Core tests prove that no Node, Python, Go, cloud CLI, provider account, or network is needed to validate, inspect with fixture profiles, run conformance fixtures, or verify receipts.
