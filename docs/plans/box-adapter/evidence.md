# Evidence ledger and verification record

Research date: 2026-09-05. Primary decision document: [architecture report](README.md). WorkCell baseline `074d7262ef6c565e3dabd22ee046228c7329e5c1`, branch `main`, initially clean. The report is a new documentation-only change; it does not inherit previous prototype/research conclusions.

## Evidence classes

- **Source-verified:** current local WorkCell source or published SDK declarations inspected directly; this establishes what code expresses, not live execution behavior.
- **Provider-documented:** ASCII primary documentation/OpenAPI; no provider enforcement independently tested.
- **Proposed:** architecture, configuration, worker, CLI/schema changes and fixtures to be built.
- **Unknown:** absent/contradictory provider evidence; not converted to an affirmative capability.

The public homepage was read through web browsing. The docs host failed in that browser fetcher, so indexed Markdown and OpenAPI were retrieved through unauthenticated HTTPS using standard local retrieval. Published npm tarball was downloaded and its declarations inspected without installing or executing package code. Python package metadata was read from PyPI; Python SDK was not installed or executed. No Box authenticated endpoints, accounts, resources or credentials were used.

[Source index](source-index.json) records URL, byte count, SHA-256 and retrieval method for downloaded inputs. Metadata JSON is explicitly identified as locally reserialized/subselected; its digest is not represented as the original HTTP-body digest. Raw docs/packages remained temporary research inputs outside Git. Public docs generally expose no reliable publication/update date; the access date is recorded rather than invented. Package versions are retrieval-time observations.

## WorkCell claim-to-source ledger

All source links refer to this repository; the report pins the inspected baseline commit. Immutable remote baseline: [WorkCell source tree](https://github.com/kujolang/workcell/tree/074d7262ef6c565e3dabd22ee046228c7329e5c1).

| Claim family | Inspected source / symbols | Finding and confidence |
| --- | --- | --- |
| Product and runtime | [VERSION](../../../VERSION), [RUNTIME_VERSION](../../../RUNTIME_VERSION), [README](../../../README.md), [AGENTS](../../../AGENTS.md) | 1.1.0; exact Kujo 1.2.1 commit; stable OCI/additive alpha remote distinction. High. |
| Workload and host profile | [portable_definition](../../../src/domain/portable_definition.kujo): `validate_portable_definition`, `load_host_profile`, `validate_profile_budgets`; [definition docs](../../workcell-definition.md) | Closed v2 fields; image/compute required, /workspace fixed, provider-specific options in profile. High. |
| Capability negotiation | [controls](../../../src/evidence/controls.kujo): `requirements_from_definition`, `controls_ledger`; [resolution](../../../src/backend/resolution.kujo) | Mandatory image/CPU/memory/PID/ownership/etc.; accepted semantic equality required. High. |
| Manifest and protocol | [registry](../../../src/backend/registry.kujo), [types](../../../src/backend/types.kujo), [client](../../../src/backend/client.kujo) | Explicit digest-pinned manifest, bounded subprocess/JSONL, strict envelopes, provider-state/handle limits. High. |
| Credential boundary | [client](../../../src/backend/client.kujo): `adapter_env_allow`, `redact_value`; [portable coordinator](../../../src/execution/portable_coordinator.kujo): `invoke`, `adapter_options_for` | PATH + explicit credential, execute-only task secret env channel. Task secret values unavailable to other adapter operations. High. |
| Workspace source/transfer | [package](../../../src/workspace/package.kujo), [workspace](../../../src/workspace/workspace.kujo) | Clean shallow Git input, file/archive hashes, unsupported submodules/LFS/symlinks; not arbitrary checkout upload. High. |
| Artifact security | [archive](../../../src/artifacts/archive.kujo), [exporter](../../../src/artifacts/exporter.kujo) | Revalidate untrusted archive and declarations on host; bound/rehash outputs. High. |
| Remote lifecycle | [portable coordinator](../../../src/execution/portable_coordinator.kujo): `run_portable_workcell`, `finalize_failure`, `destroy_and_inventory` | Both failure and normal path destroy; no read of remote keep_failed; non-execute timeout 120s; cleanup handle rebuilt from inventory with synthetic provider state. High. |
| Optional lifecycle | [types](../../../src/backend/types.kujo): `valid_operation`, optional request validation; [CLI](../../../src/cli/cli.kujo) | Pause/resume/snapshot/metrics operation vocabulary exists; integrated remote retention/replay CLI absent. `record` is core-local, not adapter operation. High. |
| Recovery | [recovery](../../../src/recovery/recovery.kujo): `write_recovery_intent`, `attach_recovery_handle`, `plan_recovery` | Intent before create, exact run+nonce, complete inventory; unknown intent requires provider-identifiable ownership. High. |
| Receipts | [v2](../../../src/receipts/v2.kujo), [manifest](../../../src/receipts/manifest.kujo), [coordinator](../../../src/execution/portable_coordinator.kujo) | Buffered events, changed-file evidence, null unknown cost, core timings and cleanup; portable output layout differs from v1. High. |
| OCI implementation | [portable_oci](../../../src/execution/portable_oci.kujo), [docker runtime](../../../src/runtime/docker.kujo), [policy](../../../src/policy/policy.kujo) | Existing built-in route reused; no external SDK required. High. |
| Existing providers | [providers.mjs](../../../adapters/official/runtime/providers.mjs), [protocol.mjs](../../../adapters/official/runtime/protocol.mjs), [adapter.mjs](../../../adapters/official/runtime/adapter.mjs), provider operational docs | E2B metadata/Vercel tags/Daytona labels; explicit SDK pins and fixture-only certification status. High; no live enforcement inferred. |
| Packaging | [package.json](../../../adapters/official/package.json), [lockfile](../../../adapters/official/package-lock.json), [distribution](../../official-adapter-distribution.md), [integrity script](../../../adapters/official/scripts/update-integrity.mjs) | Shared package/runtime and dependency integrity; Node ≥20; scripts disabled/read-only installation. High. |
| Security/limits | [security model](../../security-model.md), [security review](../../security-review.md), [enterprise](../../enterprise-deployment.md), [known limitations](../../known-limitations.md) | Authority distinctions, transformed-secret limits, provider/host trust, remote buffered output. High for documented boundary. |
| API/release/live tests | [API compatibility](../../api-compatibility.md), [authoring](../../adapter-authoring.md), [runtime lifecycle](../../runtime-lifecycle.md), [launch checklist](../../launch-checklist.md), [live certification](../../live-provider-certification.md), [live harness](../../../tests/live_certification.sh), [Node tests](../../../adapters/official/test/protocol.test.mjs) | Alpha strict wire versioning; credentials plus explicit live authorization, bounded fixture and retained exact-version evidence. High. |

## Box claim-to-source ledger

Publisher is ASCII for documentation/specification and the ASCII-published SDK packages for package metadata. Accessed 2026-09-05 throughout. Confidence means confidence in the documentary finding, not provider enforcement.

| Claim family | Direct primary source | Finding / consequence |
| --- | --- | --- |
| Product | [Box homepage](https://box.ascii.dev/) | VM/SSH/Docker/snapshot/price overview; homepage is less specific and conflicts with machine page on sizes/shared CPUs. |
| API/auth/errors/idempotency | [Public API v1](https://docs.ascii.dev/box/api/v1), [OpenAPI](https://docs.ascii.dev/openapi/box-v1.yaml) | API base, bearer auth, state/errors, create/fork keys retained 24h; no atomic run/nonce metadata fields in create or Box response. High. |
| Creation/readiness/TTL | [Create Box](https://docs.ascii.dev/box/api/reference/boxes/create-box), [setup](https://docs.ascii.dev/box/setup) | Create fields type/ttl/env/environment/noEnv/setupScript/org/from; readiness independent of background setup. |
| Credentials/scopes | [API Keys](https://docs.ascii.dev/box/api-keys) | Service-key use, session-only key management; no demonstrated arbitrary service-key per-resource RBAC. |
| SDK TS | [TypeScript SDK](https://docs.ascii.dev/box/sdks/typescript), [npm metadata](https://registry.npmjs.org/@asciidev%2fbox-sdk/latest), [0.0.34 tarball](https://registry.npmjs.org/@asciidev/box-sdk/-/box-sdk-0.0.34.tgz) | BoxApi declaration methods, fetch override, raw streaming methods; no declared dependencies; enum missing xlarge despite current spec. High. |
| SDK Python | [Python SDK](https://docs.ascii.dev/box/sdks/python), [PyPI](https://pypi.org/pypi/ascii-box-sdk/json) | 0.0.35 metadata, Python ≥3.9 and listed runtime dependencies; no code execution. |
| Compute/tooling | [Machine capabilities](https://docs.ascii.dev/box/machines) | Four machine classes, x86_64, shared vCPU, disk/data floors, tools, resizing/substitution caveats. |
| Commands | [Execute command](https://docs.ascii.dev/box/api/reference/agent/execute-box-command), [Command status](https://docs.ascii.dev/box/api/reference/agent/get-command-status) | Shell command + cwd; timeout 1–600s; detached and tails; lost/ambiguous command is not safe to retry blindly. |
| Files/SSH | [SSH Access](https://docs.ascii.dev/box/ssh-access), [Write file](https://docs.ascii.dev/box/api/reference/agent/write-box-file), [Artifact](https://docs.ascii.dev/box/api/reference/agent/download-box-artifact) | Public key registration, user/IP, SCP, allowed API path roots, binary artifacts; payload size unspecified. |
| Environments | [Environments](https://docs.ascii.dev/box/environments) | noEnv/safe-for-third-parties, immutable config versions selected through mutable name/latest, explicit env inheritance, selective managed credential scrubbing. |
| Network | [Hosting](https://docs.ascii.dev/box/hosting), [FAQ](https://docs.ascii.dev/box/faq), [OpenAPI](https://docs.ascii.dev/openapi/box-v1.yaml) | IP and hosted ports; no documented create-time workload egress/metadata controls or explicit region selector. Absence is scoped to reviewed sources. |
| Snapshots | [Snapshots and copies](https://docs.ascii.dev/box/snapshots), [Named snapshot API](https://docs.ascii.dev/box/api/reference/snapshots/save-named-snapshot) | Filesystem-only, captured paths/cache exceptions, automatic + named, mutable name/immutable underlying artifact, async save, quota ten. |
| Resume/fork | [Long-running tasks](https://docs.ascii.dev/box/long-running-tasks), [Fork API](https://docs.ascii.dev/box/api/reference/boxes/fork-box) | Restart semantics, fresh identity for fork, inherited env/version vs fresh TTL; no process-memory checkpoint. |
| Archive/delete/ZDR | [Data retention](https://docs.ascii.dev/box/data-retention), [Permanent deletion](https://docs.ascii.dev/box/api/reference/boxes/permanently-delete-box-data), [Deletion operation](https://docs.ascii.dev/box/api/reference/account/get-deletion-operation) | 202 operation, immediate read hiding, pending/processing/blocked/completed, shared artifacts, fences and session-only ZDR mutation. |
| Webhooks/events | [Webhooks](https://docs.ascii.dev/box/webhooks), [Events](https://docs.ascii.dev/box/api/reference/agent/list-box-events) | Four lifecycle hooks, signatures/delivery semantics and limits; not direct-command terminal authority. |
| Price/limits/wallet/trial | [Billing](https://docs.ascii.dev/box/billing), [Limits API](https://docs.ascii.dev/box/api/reference/account/get-box-limits) | Rates/concurrency/start quotas; wallet vs resource ownership; trial/payment ambiguity; unpriced storage/bandwidth excess. |

## Contradictions and bounded unknowns

| Observation | Reconciliation / next evidence needed |
| --- | --- |
| Homepage: three sizes/dedicated VM-time; machines/OpenAPI: four sizes/shared vCPU | Use current machine/spec facts for research; pinned SDK supports only three enum values. Do not claim dedicated physical CPU. |
| npm CreateBoxRequest comment says size kept for life; fork/resume types and current docs allow resizing | Treat comment as stale. Test pinned serializer/live response; no automatic resize in initial disposable path. |
| SDK docs command table returns CommandResponse; package method returns Command200Response union | Handle sync/detached discriminator and validate required fields. |
| Billing organization table says API/SDK features unavailable; OpenAPI/package include related fields | Org is wallet only. Verify exact API scope and visibility, reject ignored routing. |
| Environment prose suggests version stability but create selects name/latest, no version argument | Never promise atomic version pinning. Record returned attachment, with noEnv null case explicit. |
| FAQ snapshots included; templates described as storage-costing | Ordinary latest snapshot allowance does not establish named-template storage price. |
| Trial text says first payment and separately adding payment method lifts limits | Live limits/account is authoritative for actual admission; do not infer subscription transition. |
| API deletion hides resources before operation completes | Include deletion operations in durable owned inventory. An absent normal list row alone is insufficient. |
| Box supports stop/fork, WorkCell recognizes optional op names | Does not imply current keep-failed or replay UX works; coordinator source disproves this assumption. |

## Search/retrieval scope and stopping rule

Inspected all requested WorkCell doc families plus current provider-neutral definition/control/client/coordinator/receipt/recovery/package/export and official adapter code. Retrieved the Box documentation index, 17 directly relevant feature pages, public OpenAPI and both package registries; inspected actual npm declarations and operation schemas to test ownership, idempotency, files, commands, deletion and snapshot assumptions. No unrelated integration architecture was consulted.

Stopped when each requested report family had a direct primary source or an explicit unknown, and remaining high-impact questions required provider answers or credentialed live evidence unavailable by design. Extra marketing pages would not settle atomic ownership, hidden deletion operations, hard spend guarantees or enforcement. Research did not turn into integration implementation.

## Verification

This section records documentation verification for this change, not the future adapter’s conformance or Box live status. The architecture remains proposed. See the final verified checks below as updated before commit.

- Required report structure: all 20 headings present in the requested order; balanced code fences and all three JSON examples parse successfully.
- Primary sources: 21/21 indexed byte counts and hashes match retained research inputs; all 32 distinct public documentary hyperlinks in report/ledger returned HTTP 200.
- Repository Markdown audit: passed across 59 Markdown files; `git diff --check` passed.
- Existing official-adapter Node suite: 23 passed, zero failed/skipped. `npm run integrity:check --prefix adapters/official` completed successfully (exit 0). This is baseline offline adapter evidence, not a Box adapter test.
- No executable WorkCell/adapter code, manifests, lockfiles or infrastructure were changed. Full Kujo core/OCI/provider suites were not rerun for this documentation-only change. The host default runtime was 1.2.3, not the required 1.2.1; an optional exact-source runtime build was stopped as unnecessary for document validation. A version-consistency invocation could not resolve its `kujo` executable; no passing pinned-runtime validation is claimed.
- Box live certification: not run, intentionally. Ownership, deletion, security enforcement, billing and actual snapshot/environment behavior retain the limitations stated in the report.
