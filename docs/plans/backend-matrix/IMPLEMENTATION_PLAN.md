# Dependency-ordered implementation plan

## Phase 0 — Freeze the v1 baseline

**Goal:** make behavioral equivalence measurable before extraction.

**Files/modules affected:** tests and fixtures only; current `src/policy`, `src/runtime`, `src/execution`, `src/receipts`; benchmark documentation.

**Reuse:** every existing WorkCell test and fake Docker/Podman executable.

**New work:** record golden resolved definitions, policy argv, receipt shape, lifecycle/exit cases, inventory/cleanup output, and phase timer hooks that do not change public output.

**Tests/fixtures:** success, workload failure, timeout, cancel, startup failure, verification/export/cleanup failure, Docker/Podman rootless/security variants.

**Docs:** baseline compatibility and benchmark environment.

**Security:** redact fixture material; verify no generated evidence is committed accidentally.

**Benchmark:** collect 10+ validate/inspect/dry-run samples and full Docker/Podman lifecycle phase timings on approved hosts.

**Exit:** all current gates pass; golden evidence is reviewed; no product behavior change.

## Phase 1 — Introduce semantic backend types and fixture backend

**Goal:** define core-owned intent/result types without moving OCI behavior.

**Files/modules affected:** new `src/backend/types.kujo`, `resolution.kujo`, `fixture.kujo`; additive imports in coordinator/definition tests.

**Reuse:** definition bounds, receipt helpers, util process/redaction.

**New work:** capability state, control ledger, provider/substrate identity, handle/result/error/event types, deterministic fixture backend.

**Tests/fixtures:** type validation, unsupported/unknown/degraded resolution, capability implications, malformed fixture frames.

**Docs:** machine schemas and error mapping.

**Security:** fail closed on unknown required capability; no backend-name capability assumptions.

**Benchmark:** type/resolution overhead.

**Exit:** fixture can model a complete no-network run entirely offline; no production path uses it implicitly.

## Phase 2 — Extract Docker behind the internal adapter

**Goal:** route existing Docker behavior through semantic operations with zero public regression.

**Files/modules affected:** split `src/runtime/docker.kujo` into backend/OCI shared and Docker implementation; adapt policy, verification, coordinator, doctor, CLI clean/inspect.

**Reuse:** all current engine argv/image/security/cleanup code.

**New work:** translate semantic intent to Docker policy, handle wrapper, normalized collect/export hooks while preserving bind-mounted host export in v1.

**Tests/fixtures:** golden argv/receipts/exits, fake Docker lifecycle, integration/load/egress/self-proof.

**Docs:** architecture and compatibility updates only after proof.

**Security:** container labels/ownership and daemon security inspection unchanged.

**Benchmark:** compare phase 0 Docker results; justify any regression.

**Exit:** all v1 gates pass unchanged and Docker direct calls no longer leak into coordinator/verification.

## Phase 3 — Extract Podman and shared OCI driver

**Goal:** prove the contract supports a second engine without scattered branches.

**Files/modules affected:** `src/backend/oci/{shared,podman}.kujo`, doctor/security probes, fixtures.

**Reuse:** shared argv/image/lifecycle code and current Podman security logic.

**New work:** Podman capability resolution for rootless/cgroups/security, error normalization, runtime/substrate reporting.

**Tests/fixtures:** current Podman fake tests plus rootless cgroup variations; live supported-Linux gates.

**Docs:** Podman limitations and actual observed capabilities.

**Security:** rootless is visible, not universal VM isolation; unsupported cgroup limits reject.

**Benchmark:** compare phase 0 Podman where a host is available.

**Exit:** Docker and Podman are separate adapters sharing only real OCI mechanics; no core backend-name conditions.

## Phase 4 — Executable adapter protocol and registry

**Goal:** allow external adapters without adding provider runtimes to core.

**Files/modules affected:** `src/backend/client.kujo`, `registry.kujo`, manifest/profile schemas, CLI `backends`/inspect surfaces.

**Reuse:** structured process API, timeout/output/redaction utilities.

**New work:** JSONL transport, deadlines/backpressure, manifest discovery, duplicate/version/digest validation, profile loading, external fixture executable.

**Tests/fixtures:** noisy stdout, malformed JSON, wrong request IDs, duplicate result, oversized events, hung adapter, secret canary, executable substitution, incompatible contract.

**Docs:** third-party author guide and profile locations.

**Security:** no auto-download; explicit/digest-pinned adapters; bounded process environment.

**Benchmark:** adapter process startup and stream throughput.

**Exit:** external fixture passes the same base run as internal fixture and cannot exceed bounds.

## Phase 5 — Portable workspace and declared artifact archives

**Goal:** make transfer/evidence independent of bind mounts.

**Files/modules affected:** new workspace package and artifact archive modules; workspace/exporter/manifest tests; v2 definition schema.

**Reuse:** clean-source inspection, path/symlink checks, artifact limits, patch/change report, SHA-256 manifest.

**New work:** one-commit isolated portable clone package, deterministic input manifest, remote materialization verification, in-workspace declared exporter, safe archive extraction.

**Tests/fixtures:** ignored/dirty/hook/config exclusion, submodule/LFS rejection, symlink/hardlink/device/FIFO/archive bomb/traversal/Unicode, interrupted transfers, digest mismatch.

**Docs:** portable Git semantics and limitations.

**Security:** never archive arbitrary dirty directory; compressed and expanded bounds; no-follow extraction.

**Benchmark:** 1 MiB/100 files and 100 MiB/10k files package/export cases; peak memory.

**Exit:** fixture backend round-trips a workspace and one declared artifact with equivalent Git delta and offline verification.

## Phase 6 — Receipt v2, checkpoints, recovery

**Goal:** preserve honest remote evidence across disconnects and cleanup failures.

**Files/modules affected:** receipt/manifest, new controls/recovery modules, coordinator, CLI `recover`, clean inventory.

**Reuse:** atomic writes, current lifecycle/errors, label/marker cleanup semantics.

**New work:** provider/substrate identity, controls ledger, log quality, resource/cost/cleanup inventory, recovery journal checkpoints, reconciliation command.

**Tests/fixtures:** crash after every phase, terminal unknown, provider unavailable, ownership conflict, absent resource, partial object/snapshot cleanup, receipt write failure.

**Docs:** receipt v2 schema, recovery operator guide, v1 compatibility.

**Security:** persist handle before upload; handle redaction/size; no signed URLs.

**Benchmark:** checkpoint and inventory latency.

**Exit:** simulated client death after provision is recoverable without deleting unowned resources; verify remains offline.

## Phase 7 — Official conformance suite

**Goal:** make provider and third-party claims testable offline.

**Files/modules affected:** `tests/conformance/`, protocol schema validators, fixture tooling, CI.

**Reuse:** current adversarial/path/cleanup/receipt tests.

**New work:** base and capability-selected suites, fixture format, adapter conformance report schema, credential canary scanner.

**Tests/fixtures:** all cases in `10-testing-conformance.md`.

**Docs:** author workflow and meaning/limits of conformance.

**Security:** conformance is not certification; advertised capabilities select tests dynamically.

**Benchmark:** protocol/log/artifact throughput and resource bounds.

**Exit:** Docker, Podman, internal fixture, and external fixture pass applicable conformance without live credentials.

## Phase 8 — E2B remote vertical slice

**Goal:** prove the entire remote architecture once.

**Files/modules affected:** separate official adapter package/repository; WorkCell only gains pinned example/profile fixtures and release metadata.

**Reuse:** executable protocol, portable package, exporter, receipt v2, recovery, conformance.

**New work:** E2B API/SDK bridge, API key reference, create/connect/kill/inventory, file transfer, command streaming, timeout, deny-all resolution, metrics mapping.

**Tests/fixtures:** E2B versioned responses for auth/quota/timeout/disconnect/non-zero/log/artifact/cleanup/snapshot inventory; gated live smoke.

**Docs:** E2B limits, plan-sensitive lifetime/network, cost source, distribution tutorial.

**Security:** deny-all proof, no allowlist advertisement until schema/tests prove it, provider-claimed Firecracker only, zero orphan inventory.

**Benchmark:** cold/warm provision, package transfer, first log byte, workload, artifact, destroy; provider and WorkCell phases separated.

**Exit:** same v2 definition succeeds on Docker and E2B by profile switch; live smoke receipt verifies offline; no owned resource remains.

## Phase 9 — Vercel Sandbox vertical slice

**Goal:** prove a second remote provider through public REST.

**New work:** OIDC/access-token references, REST version capture, non-persistent sandbox creation, command/log/file endpoints, network policy resolution, stop/destroy/snapshot inventory.

**Tests:** persistent-default rejection, deny-all/domain/IP policies, command kill, REST pagination/version drift, snapshot cleanup.

**Security:** record Firecracker as provider claim; disable persistence/preview exposure unless requested.

**Benchmark:** same suite as E2B.

**Exit:** conformance plus gated live smoke; no Marketplace work included.

## Phase 10 — Daytona class/tier vertical slice

**Goal:** prove conditional capabilities and self-hosted profiles.

**New work:** OpenAPI adapter, class/tier resolution, explicit ephemeral mode, strict Tier 3/4 network rules, self-hosted endpoint/TLS policy, snapshot/volume inventory.

**Tests:** container vs VM claims, Tier 1/2 rejection for network none, recover/archive/delete states, signed transfer redaction.

**Security:** never label default container snapshot a VM; endpoint trust and runner hardening operator-owned.

**Benchmark:** class/region profiles with separate results.

**Exit:** conditional capability drift is fail-closed and receipt-visible.

## Phase 11 — Integration and release

**Goal:** expose provider-neutral WorkCell through Kujo Agent/Bridge, Dispatch, Relay, and release processes.

**Files/modules affected:** Kujo Agent in its own repository only in a separately scoped change; WorkCell docs/examples/contracts; adapter release repos.

**New work:** exact receipt-path return, input override contract, environment profile mapping, cancel propagation/correlation, release metadata and scheduled drift jobs.

**Tests:** same Agent Project across local/fixture profiles; Dispatch/Relay correlation and new-attempt retry; plugin never sees provider credentials.

**Security:** operator profile wins; agent cannot write provider escape hatches.

**Benchmark:** orchestration overhead separate from WorkCell.

**Exit:** clean-machine core verification, adapter-specific clean installs, all gates, migration/release notes, exact commit live evidence, working tree clean.

## Stop rules

Do not start Vercel/Daytona before the E2B vertical slice proves recovery and declared export. Do not start cloud jobs before attempt/object-store semantics are stable. Do not add pause/resume to canonical lifecycle. Do not implement automatic routing, hosted registries, or raw Firecracker support in this plan.

