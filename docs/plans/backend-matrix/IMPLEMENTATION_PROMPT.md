# Implementation agent mega prompt: WorkCell provider-neutral backend matrix

You are the senior engineering agent implementing the WorkCell backend matrix. The architecture research is complete. Do not redesign the product boundary or repeat broad provider research. Read this package in numeric order, then execute `IMPLEMENTATION_PLAN.md` dependency order with small, reviewable commits.

## Objective

Evolve WorkCell from a stable Docker/Podman harness into a provider-neutral execution lifecycle that can run the same bounded WorkCell v2 workload across local containers and approved remote sandboxes without weakening WorkCell's definition, policy, evidence, portability, security, or cleanup guarantees.

The strategic rule is binding:

> WorkCell owns the execution contract and lifecycle. Providers own compute and isolation.

## Non-negotiable architecture

Use a layered provider/runtime model exposed through one narrow adapter protocol:

```text
caller/orchestrator
  -> WorkCell core (definition, policy, lifecycle, evidence, verification, cleanup)
  -> backend adapter (provider control, transfer, command, observations)
  -> provider/runtime substrate (Docker, Podman, sandbox service, OCI runtime, VM)
```

There is one public adapter protocol, not a universal cloud SDK and not provider-specific scripts in the coordinator. Provider, adapter, and runtime/substrate are separate identities.

- Docker and Podman are built-in backend implementations sharing internal OCI helpers.
- gVisor and Kata are lower runtime selections recorded under Docker/containerd/Kubernetes, not backend IDs.
- Firecracker and Apple Virtualization.framework are raw VMM/framework substrates and are not direct WorkCell targets.
- Kubernetes Jobs, Agent Sandbox, Nomad, Fargate, Cloud Run Jobs, and Azure Container Apps Jobs are later external/operator adapters. Do not add scheduler behavior to core.
- Codespaces, Gitpod, and Coder are host/template integrations, not disposable backends by default.
- Wasmtime/WASI is a different workload ABI and is out of scope.

## Current baseline to preserve

WorkCell 1.0.0 currently owns:

- strict v1 JSON definitions and unknown-field rejection;
- clean source Git enforcement and disposable worktree/isolated clone;
- Docker/Podman image, security, resource, network, environment, timeout/output policy;
- separate workload and lifecycle exit categories;
- incremental secret redaction;
- Git changes/patch, declared-only artifact export, versioned verification;
- receipt v1, SHA-256 manifest, offline verify;
- label/marker-scoped cleanup, failed workspace preservation, stale recovery.

All existing v1 Docker/Podman CLI, definition, receipt, verification, artifact, cleanup, and failure behavior is compatibility-locked. Do not silently route a v1 definition to a remote provider.

## Canonical lifecycle

Implement these core semantic phases:

```text
resolve -> provision -> prepare -> execute -> collect -> verify -> export -> cleanup -> record
```

`record` checkpoints throughout and finalizes after cleanup. Provider mechanics such as upload, start, stream, wait, and delete fit inside phases. Pause, resume, snapshot, and recover are not normal lifecycle phases. Pause/resume/snapshot are optional capabilities. Recovery is a separate reconciliation command.

Mandatory adapter operations:

- `describe`
- `resolve`
- `provision`
- `prepare`
- `execute`
- `collect`
- `export`
- `destroy`
- `inventory`

Optional: `cancel`, `pause`, `resume`, `snapshot`, and asynchronous `metrics`.

Every accepted backend must have an effective termination path. If graceful command cancel is unsupported or uncertain, WorkCell destroys the exclusively run-owned resource. Client cancellation alone is never evidence that remote execution stopped.

## Adapter protocol

Implement `workcell-backend/v1alpha1` as a language-neutral executable JSON Lines protocol. WorkCell launches an explicitly selected executable with `protocol`, writes one request to stdin, reads bounded event frames and one result from stdout, and treats stderr as bounded redacted diagnostics only.

Requirements:

- a fresh adapter process per operation; no mandatory daemon;
- request/result IDs, run ID, operation, deadline, profile, payload;
- opaque durable handle in a common wrapper;
- strict line/event/byte/deadline bounds and backpressure;
- protocol stdout contains JSONL only;
- provider non-zero workload exit is a valid execution result, not an adapter exception;
- stable error taxonomy from `07-backend-contract.md`;
- mutating operations idempotent by run/operation key;
- external adapter discovery by small manifest and explicit path/PATH convention;
- no automatic adapter download, hosted registry, or hidden network selection;
- adapter digest/signature enforced only through operator policy.

Use `BACKEND_CONTRACT_PROPOSAL.json` as the machine contract. If implementation reveals an ambiguity, choose the smallest semantics consistent with the narrative and update proposal/docs/tests together. Do not expand it into generic VM/storage/network APIs.

## Capabilities and strictness

Capabilities are dynamic, profile/account/plan/region/runtime-specific. Static manifest capabilities are hints. `resolve` is authoritative for the planned run; provision rechecks volatile requirements.

For every material control retain:

- requested value and whether required;
- acceptance: accepted/rejected/degraded/not-requested;
- resolved value;
- enforcement status: WorkCell-enforced, provider-claimed, operator-claimed, not-enforceable, unsupported, unknown;
- authority/evidence reference;
- observation: observed/not-observed/contradicted/not-applicable, with narrow method/result;
- limitations.

Default is fail-closed. There is no generic best-effort/compatible mode. An operator profile may name exact evidence-only capabilities allowed to degrade, such as metrics or provider cost. Workspace integrity, dirty-source refusal, timeout/termination, output bounds, credentials/redaction, declared artifacts/path safety, ownership cleanup, and requested network/isolation/resource controls never degrade.

`network:none` must never become provider-default egress. Reject before provisioning if the actual profile cannot satisfy it. Runtime/provider names are not proof.

## Definition and profile split

Keep v1 parsing exact. Introduce v2 for remote portability:

- workload: Linux process, image intent, argv, workdir;
- workspace: clean Git source/materialization/mount intent;
- environment and workload secret names;
- semantic compute/execution/network/filesystem requirements;
- artifacts, verification, cleanup, receipt.

Provider backend, credential reference, account/project, region, endpoint, template/snapshot, private pool, and provider-native knobs live in versioned host profiles outside the workload definition. Namespaced `adapter_options.<id>` may express mechanics only; they cannot redefine CPU, memory, timeout, network, artifacts, environment, or cleanup.

Selection precedence:

```text
operator forced policy > explicit CLI/profile > Agent environment mapping > host default > v1 compatibility backend
```

No automatic `cheap`, `fast`, `gpu`, or `strong-isolation` routing.

Reuse Kujo Agent credential conventions: CI environment, explicitly selected ignored owner-only project secret source when supported, and OS credential store. Profiles contain only `credential_ref`. Provider credentials never enter sandbox workload secrets, argv, manifests, fixtures, raw attachments, receipts, logs, patches, or artifacts.

## Remote workspace model

Implement `workcell-workspace/v1` in core:

- source is an exact clean Git commit;
- create a bounded one-commit isolated clone with functional `.git` baseline;
- remove/disable remote credential helpers, hooks, user config, worktree links, ignored files, and ambient secrets;
- deterministic archive ordering/metadata where practical;
- SHA-256 manifest and byte/file/depth counts;
- reject submodules, LFS-only materialization, unsafe file types, and unsupported history needs initially;
- verify package digest after remote materialization;
- provider-side Git clone is optional and not the default.

Do not change v1 Docker/Podman workspace semantics. V2 Docker/Podman should support the portable package so the exact v2 definition can prove local/remote equivalence.

## Artifacts, changes, and logs

WorkCell's declared artifact list remains authoritative. Implement a small WorkCell-owned exporter that runs in the workspace, selects only normalized declarations, rejects traversal/symlink/hardlink/device/FIFO issues, enforces path/global byte/file/depth/extension/secret rules, and creates one deterministic archive plus manifest.

The adapter transfers only that archive. Core rechecks compressed/expanded bounds, paths, types, hashes, and secret policy before extracting into the run-owned output. Never download the whole remote workspace implicitly.

Collect a bounded workspace delta against the portable Git baseline and produce the same redacted patch/change semantics as v1.

Normalized log events must include stream, core sequence, bytes, optional provider timestamp, source, and ordering scope. The final log record reports streaming/buffered/recovered, stdout/stderr separation, per-stream/global/host-arrival/unknown order, timestamps, completeness, truncation, byte counts, and discontinuities. Do not claim global order or completeness the provider cannot prove.

## Receipt v2 and recovery

Implement receipt v2 sections defined in `09-receipt-evidence-design.md`. Keep core receipts compact and provider-neutral. Raw provider metadata is optional, selected/redacted/bounded, API-versioned, and manifest-hashed. Never persist credential values or signed transfer URLs.

Checkpoint atomically after resolve, provision, prepare, start, terminal result, collect/export, and cleanup. Immediately after provisioning, before upload, persist `.workcell/recovery/<run-id>.json` with adapter/provider/profile fingerprints, opaque resource IDs, WorkCell run ID, ownership nonce, creation/expiry, and cleanup plan.

Add `workcell recover`:

- dry-run reconciliation;
- run-specific collection/cleanup retry;
- adapter inventory matching;
- no deletion unless journal, provider ownership marker, account/profile, run ID, and nonce agree;
- itemized remaining/removed/absent/failed/ownership-mismatch results.

`workcell clean` may reuse the engine for bulk owned cleanup. A network disconnect or unknown terminal state is failure, not success. Cleanup failure remains a distinct lifecycle category and preserves the original error.

## File/module ownership

Prefer these WorkCell core locations, adjusting only for concrete Kujo module constraints:

- `src/backend/types.kujo`
- `src/backend/registry.kujo`
- `src/backend/client.kujo`
- `src/backend/resolution.kujo`
- `src/backend/fixture.kujo`
- `src/backend/oci/shared.kujo`
- `src/backend/oci/docker.kujo`
- `src/backend/oci/podman.kujo`
- `src/workspace/package.kujo`
- `src/artifacts/archive.kujo`
- `src/evidence/controls.kujo`
- `src/recovery/recovery.kujo`
- `tests/conformance/`

Keep definition policy in core. Keep artifact authorization in core. Keep receipts/manifests/failure mapping in core. Do not move them into adapters.

Official remote adapters are separate versioned packages/repositories so provider SDK runtimes do not enter WorkCell core. The first adapter order is E2B, Vercel Sandbox, Daytona. Do not begin Vercel/Daytona implementation before E2B proves recovery and declared export. Modal and Runloop follow later. Cloudflare waits for stable 1.0 and is an operator-hosted bridge. Managed jobs are later. Raw Fly Machines/Firecracker are not in this program.

## Migration order

Follow `IMPLEMENTATION_PLAN.md` exactly:

1. freeze v1 goldens and phase timings;
2. semantic types + fixture backend;
3. Docker extraction;
4. Podman/shared OCI extraction;
5. executable protocol/registry;
6. portable workspace/artifact archives;
7. receipt v2/checkpoints/recovery;
8. official conformance suite;
9. E2B remote vertical slice;
10. Vercel vertical slice;
11. Daytona conditional capability slice;
12. Kujo Agent/Bridge/Dispatch/Relay integration in separately scoped repository changes.

Do not parallelize cloud adapters before the abstraction has Docker, Podman, fixture, and E2B implementations.

## Test requirements

Normal tests are offline and credential-free. Each adapter has describe/request/response/failure/timeout/log/artifact/cleanup/drift fixtures and a simulator. The base conformance suite proves:

- version negotiation and schema strictness;
- unsupported required control fails before provision;
- provision/prepare/destroy idempotency;
- ownership safety and orphan recovery;
- exact workspace digest;
- argv/workdir/environment fidelity and secret redaction;
- exit/startup/timeout/cancel/terminal-unknown normalization;
- log quality and bounds;
- declared-only artifact export/path defenses;
- receipt v2 and offline verify;
- provider/API/runtime identities;
- no hidden retry;
- malformed/noisy/oversize/hung adapter handling.

Capability suites run only when execution-time resolution advertises them: compute/disk/PID, network none/allowlists, cancel, pause/resume, snapshot, streaming/order, metrics/cost, custom image/digest.

For official adapter live smokes require an explicit environment gate/profile, tiny immutable fixture, strict resource/time/spend ceilings, unique ownership nonce, final destroy, and inventory proving zero orphans. Do not expose fork PRs to credentials. Live evidence is exact account/plan/region/version evidence, not universal certification.

## Security requirements

- Never write “WorkCell enforced” for a provider control unless WorkCell directly enforces it.
- Provider documentation/configuration becomes `provider-claimed`; operator profile becomes `operator-claimed`; conformance probe is a narrow observation.
- Recheck network-none against actual plan/class/tier. Daytona Tier 1/2 cannot satisfy strict none if essential services remain reachable.
- E2B allowlist stays unadvertised until schema and live tests prove semantics.
- Vercel ordinary runs explicitly use non-persistent behavior and disable preview exposure.
- Provider snapshots, volumes, objects, images, commands, and log handles enter ownership inventory and cleanup.
- Scheduler adapters must set retries/restarts to zero or expose every attempt separately and reject ambiguity.
- Adapter replacement/digest, protocol output, archive extraction, credentials, raw attachments, and recovery deletion receive adversarial tests.

## Performance and cost

Add phase-separated timers for core validation/package/record, adapter resolve/process, provider queue/provision, upload/materialize, start/workload, log recovery, verification/export/download, cleanup. Record timing authority and never subtract unrelated clocks.

Benchmark deterministic no-op, stream, workspace, artifact, compute, and failure workloads. Separate warm/cold, sample count, region, plan, versions. Do not quote provider marketing startup numbers.

Record only provider-reported cost amount or usage with unit/currency/window/source. Otherwise record cost class and `unknown`. WorkCell is not a price router or billing estimator. Operator profiles may cap resources, lifetime, concurrency, transfer, and persistent-resource age only where enforceable.

## Kujo ecosystem integration

Kujo Agent keeps one WorkCell definition and maps environment to a host profile. It must pass invocation input through a versioned override, consume the exact returned receipt path, and expose `execution_boundary: workcell` plus inspectable backend summary. It must not expose provider APIs or credentials to the agent.

Agent Bridge/Plugin exposes one semantic execute tool plus inspect/cancel/evidence/recovery, never provider-specific calls.

Dispatch and Relay own orchestration, approvals, retries, repair, workflow pause/resume, budgets, and correlation. One orchestration attempt equals one WorkCell run. A retry creates a new run. Cancellation propagates to WorkCell and waits for cleanup evidence. WorkCell never retries or repairs workloads.

## Compatibility and release gates

For every core phase run targeted tests, then before completion run the exact WorkCell gates:

```bash
./bin/workcell --help
./bin/workcell --version
./bin/workcell validate --file workcell.json
./tests/version_consistency.sh
./tests/run.sh
./tests/quality.sh
./tests/release_report.sh
./tests/markdown_links.sh
git diff --check
```

Run Docker/Podman gates only when the engine and approved image/host are available, and report explicit blockers without substituting one backend's evidence for another. Add protocol/schema/conformance/receipt-v2/recovery tests. Run adapter live smokes only with explicit authorization and retain redacted exact-commit evidence.

Clean-machine verification must prove core needs only pinned Kujo, Git, jq, and the chosen built-in engine; fixture/conformance needs no provider SDK/runtime/account/network. Each external adapter declares and tests its own dependencies. Verify install, help/version, v1 run, v2 fixture, receipt offline verification, adapter discovery, no leftover resources, and no dirty generated artifacts.

Use semantic versioning and independent contract IDs. Add fields before removal. Input schemas remain strict; output consumers ignore additive fields. Breaking protocol/definition/receipt changes get new identifiers and migration notes. Capture adapter/provider API versions in releases and fixtures.

## Commit and review discipline

Make small meaningful commits by vertical slice. Do not combine the OCI extraction with remote provider code. Do not modify sibling repositories until the core phase and a separately scoped integration task authorize it. Preserve user changes and never rewrite history. Every source change includes tests/docs; every machine-contract change updates fixtures and changelog/migration notes.

At each phase exit, show:

- changed files and contract effects;
- targeted/full test results;
- compatibility comparison;
- security evidence/unknowns;
- benchmark delta;
- remaining owned resources/orphans;
- next phase eligibility.

## Definition of done

The architecture is proven when:

1. v1 Docker/Podman behavior has zero material regression;
2. v2 same workload runs on Docker, Podman, and E2B via profile changes only;
3. unsupported controls reject before provisioning;
4. portable input and declared artifacts verify by digest offline;
5. logs/controls/provider claims are represented honestly;
6. cancellation/disconnect/cleanup/recovery cannot produce false success or unowned deletion;
7. offline conformance passes without credentials;
8. E2B exact-version live smoke leaves zero owned resources;
9. clean-machine gates pass;
10. no scope creep into scheduling, hosted services, billing, generic VMs, automatic routing, or workload repair.

Stop and escalate if a requested security control cannot be represented without weakening current semantics, a provider cannot expose ownership-safe inventory/destruction, remote transfer requires arbitrary dirty workspace upload, or the only path would add a mandatory hosted Kujo service. Do not paper over those blockers with warnings.

