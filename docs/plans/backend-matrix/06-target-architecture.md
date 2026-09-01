# Target architecture

## Decision

Adopt a layered provider/runtime model with a single executable adapter protocol. This preserves a narrow integration surface while preventing category errors such as calling gVisor a provider or treating Kubernetes scheduling as isolation.

```text
                         host/operator policy
                                  |
                                  v
WorkCell definition -> validation + semantic intent
                                  |
                                  v
                         capability resolver
                                  |
                                  v
                   backend registry / adapter client
                                  |
           +----------------------+----------------------+
           |                      |                      |
     built-in OCI           external sandbox      operator scheduler
   Docker / Podman       E2B/Vercel/Daytona...    K8s/Jobs/custom
           |                      |                      |
     runc/runsc/Kata       provider substrate      RuntimeClass/VMM
```

## Core modules

Suggested modules are implementation guidance, not a requirement to create one file per noun:

- `src/backend/types.kujo` — normalized intents, capabilities, handles, events, results.
- `src/backend/registry.kujo` — built-in and external adapter discovery, version checks, duplicate rejection.
- `src/backend/client.kujo` — bounded JSON protocol process invocation and redaction.
- `src/backend/resolution.kujo` — fail-closed negotiation and drift comparison.
- `src/backend/fixture.kujo` — deterministic offline adapter.
- `src/backend/oci/{shared,docker,podman}.kujo` — extracted current behavior.
- `src/workspace/package.kujo` — portable clean workspace creation and input manifest.
- `src/artifacts/archive.kujo` — safe declared export request and archive validation.
- `src/evidence/controls.kujo` — requested/resolved/enforced/observed ledger.
- `src/recovery/recovery.kujo` — durable resource journal, inventory reconciliation, destroy retry.

Existing modules remain authoritative for definition validation, Git policy, artifact authorization, receipt/manifest, verification decisions, and CLI failure mapping.

## Canonical lifecycle

```text
created
  -> resolving -> resolved
  -> provisioning -> provisioned
  -> preparing -> prepared
  -> executing -> collecting
  -> verifying -> exporting
  -> cleaning
  -> completed | failed | cancelled | cleanup-failed
  -> recorded
```

The semantic operations are:

1. **Resolve** — select adapter/profile, negotiate requirements, capture API/adapter capabilities, produce a no-side-effect execution plan.
2. **Provision** — create/acquire a run-exclusive resource and immediately persist the recovery handle.
3. **Prepare** — transfer/materialize the clean workspace, image/snapshot, environment names, and verification helper; confirm input manifest.
4. **Execute** — start one workload attempt, normalize streams and terminal result, enforce host watchdog.
5. **Collect** — retrieve logs, execution metadata, resource observations, and bounded workspace delta.
6. **Verify** — run declarative checks through the same adapter/workspace and validate source/delta/path invariants in core.
7. **Export** — request only declared artifacts, validate archive paths/limits/hashes locally, write run evidence.
8. **Cleanup** — destroy run-owned remote/local resources and reconcile inventory. Preserve a failure workspace only when explicitly supported and requested; otherwise export failure evidence before destroy.
9. **Record** — finalize receipt and integrity manifest. Partial receipts are written throughout; final recording occurs even after cleanup failure.

`upload/sync`, `start`, `stream`, and `destroy` are adapter mechanics inside these durable phases. Pause, resume, snapshot, and recover are not canonical run phases. Recover is a separate reconciliation command. Pause/resume/snapshot are optional operations on a handle and must not change the meaning of a normal run.

## Adapter responsibilities

Adapters own only:

- provider authentication transport and API version selection;
- dynamic capability discovery for the selected account/profile;
- resource provisioning and provider IDs;
- image/snapshot/provider runtime resolution;
- workspace byte transfer and remote materialization;
- command start, stream transport, terminal status, cancellation primitives;
- provider log/artifact/metrics retrieval;
- ownership metadata attachment, inventory, and idempotent destruction;
- raw provider response attachments after redaction and size bounds.

Adapters do not decide whether a definition is allowed, which artifacts matter, whether degraded execution is acceptable, how failures map to WorkCell categories, or what the receipt claims.

## Portable workspace package

The default remote input is `workcell-workspace/v1`:

- created from a clean, exact Git commit;
- a bounded one-commit isolated clone with a functional `.git` baseline, no remote credential helpers, hooks, ignored files, worktree links, or user config;
- deterministic archive ordering, normalized metadata where practical, SHA-256 file manifest, byte/file/depth counts;
- submodules rejected unless a future explicit, pinned submodule contract is satisfied;
- optional history bundle only when a future declared capability requires it;
- source commit and package digest recorded before upload and confirmed after materialization.

This preserves common Git status/diff behavior without uploading a dirty local directory or requiring provider network clone. Docker/Podman retain current v1 worktree/isolated-clone behavior during compatibility migration.

## Artifact transport

The adapter receives a list of normalized declared paths and limits. Preferred order:

1. run a WorkCell-owned exporter inside the workspace to create a deterministic archive and manifest;
2. transfer that single bounded archive using provider file APIs or a run-owned presigned object;
3. validate compressed and expanded size, path containment, type, symlink policy, file count/depth, per-file hashes, and secret policy locally;
4. extract into the run-owned output and include it in the WorkCell integrity manifest.

Provider-native “download directory” is usable only if it can prove equivalent traversal and bounds. Whole-workspace download is prohibited.

## Recovery and ownership

Each provisioned resource enters `.workcell/recovery/<run-id>.json` before further remote mutation. Resource records include an opaque provider ID and non-secret account/profile fingerprint. Provider-side labels/tags contain `dev.kujo.workcell=true`, run ID, project, adapter contract, and creation nonce where supported.

`workcell recover` should be added rather than overloading `clean` semantics:

- `recover --dry-run` reconciles journals and adapter inventory;
- `recover --run <id>` retries collection/cleanup for that run;
- `clean` remains bulk owned-resource cleanup and may call the same reconciliation engine;
- no operation destroys a resource when journal, provider marker, account/profile, or ownership nonce conflicts;
- partial cleanup remains receipt-visible and retryable.

## Registry and discovery

Use a small manifest plus executable entrypoint. Discovery order is operator-configured directory, project-pinned adapter package, then PATH convention `workcell-backend-<id>`. Reject duplicate IDs unless an explicit path is selected. The registry stores no credentials and performs no network routing.

Minimum manifest metadata:

- backend ID and display name;
- adapter version and backend-contract versions;
- executable argv prefix;
- supported WorkCell version range/platforms;
- credential reference names;
- static capability hints marked non-authoritative;
- manifest signature/digest metadata when operator policy requires it.

Do not build a hosted registry or automatic installer into execution.

## Compatibility

WorkCell 1.x definitions and receipts continue through a compatibility layer:

- `runtime.backend=docker|podman` selects the corresponding built-in;
- current Docker argv, image, security, workspace, exit, receipt, and cleanup tests remain unchanged;
- new fields are additive in receipt v1 only where their absence has the old meaning; the full controls ledger should use `workcell-receipt/v2` to avoid misinterpreting `effective_security_policy`;
- external backends require definition v2/receipt v2 until their semantics are stable;
- no v1 definition is silently routed to a remote backend.

## Non-goals

WorkCell will not become a scheduler, retry engine, cloud account manager, cluster installer, provider billing estimator, VM image factory, guest-agent service, Kubernetes/Temporal replacement, CI service, Docker replacement, or mandatory hosted Kujo control plane.

