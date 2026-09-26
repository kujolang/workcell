# WorkCell + Boat: current integration plan

Reviewed **2026-09-26**, against WorkCell `e57ea19` (1.1.0) and public Boat documentation retrieved without authentication. This is the current decision record. It supersedes conflicting names, provider facts, milestones, and preservation claims in the [September 5 Box research](../box-adapter/README.md); that report remains the detailed historical design. No adapter implementation or live certification is claimed. [Source hashes](source-index.json) identify this review's inputs.

## Recommendation and scope

Proceed with an **offline experimental external adapter**, followed by provider clarification and explicitly authorized live certification. Keep WorkCell on the controller host, with a pinned minimal worker supervising a constrained OCI workload inside each Boat VM. Keep the controller credential off the VM. Boat supplies compute and transport; WorkCell owns workload policy, evidence, verification, recovery, and cleanup. Paperclip and additional orchestration systems remain out of scope.

The VM's shell and sudo access do not satisfy WorkCell's exact argv, OCI image, CPU/memory/PID, read-only root, and network controls. The worker must enforce those controls through Docker and report observations honestly. A Boat snapshot can accelerate worker/toolchain preparation, but cannot substitute for the workload image digest. Use disposable runs first; retained remote snapshots are a later, separate lifecycle milestone.

## What changed

| Area | Current evidence | Integration consequence |
| --- | --- | --- |
| Identity and API | Boat by ASCII; API base `https://boat.dev/api/v1`, resources `/sandboxes`; docs at `docs.boat.dev`. | Use Boat naming in new provider IDs, profiles and documentation. Do not assume every old URL/header/package was mechanically renamed. |
| SDKs | Published npm `@boatdev/sdk@1.0.1`, class `BoatApi`; Python `boat-sdk==1.0.1`, module `boat_sdk`. npm package metadata and generated create/Sandbox declarations inspected. | Pin the new package and integrity at implementation time; review its serializers against OpenAPI. Existing Box package pins are historical. |
| Credentials | Scoped, expiring keys with action and sandbox/environment restrictions; old keys remain account-wide until reissued. Scoped creation can be temporarily disabled. | Use a host-only `BOAT_API_KEY` with explicit actions and short expiry. Test create, inventory and cleanup visibility with the actual scope. A `ci` preset is not proof that every required cleanup route is granted. |
| WorkCell preservation | `c11e114` added preservation outcomes; `ecdddbe`/`e57ea19` added execution/re-execution evidence; `0baac3d` added expired local-workspace cleanup. | Reuse these contracts. The old assertion that remote `keep_failed` is simply ignored is obsolete. Remote cleanup still destroys the resource and filesystem preservation reports unsupported; Boat snapshot retention is not implemented. |
| Snapshot inspection | Cursor-paginated history, tree browsing, direct file/folder download from a stopped snapshot, and chunk download/reassembly. | Useful later for bounded forensic export without restarting a VM. Validate paths, byte limits, hashes and complete history; a truncated/unavailable tree is not complete evidence. |
| Stop failures and billing | Snapshot documentation says a refused stop leaves the VM running but pauses billing from the first refused attempt, until use resumes. | Replace the old blanket assumption that a failed snapshot necessarily keeps accruing compute charges. This is a documented provider behavior, not a tested hard budget guarantee. |
| Billing visibility | Per-sandbox usage and explicit organization wallet selection; member caps exist in the dashboard. | Record provider-reported cost separately from local estimates. Set the wallet explicitly; organization billing does not make inventory shared. |

Sources: [API](https://docs.boat.dev/api/v1), [OpenAPI](https://docs.boat.dev/openapi/boat-v1.yaml), [keys](https://docs.boat.dev/api-keys), [TypeScript](https://docs.boat.dev/sdks/typescript), [Python](https://docs.boat.dev/sdks/python), [snapshots](https://docs.boat.dev/snapshots), [billing](https://docs.boat.dev/billing), [WorkCell lifecycle](../../runtime-lifecycle.md), [remote coordinator](../../../src/execution/portable_coordinator.kujo).

## Remaining limitations and build gates

1. **Unknown-create recovery remains a gate.** Create and fork support account-scoped idempotency for 24 hours. Retrying the identical request within that window can recover an existing sandbox, but the API also releases failed attempts so a retry can provision. Current create fields and Sandbox responses still expose no atomic immutable run/nonce metadata, and the documented routes contain no read-only idempotency-key lookup. Recovery must not create new resources to discover old ones. Post-create rename, guest environment markers, or timestamps are not ownership proof. Obtain a supported ownership/lookup contract before claiming WorkCell inventory conformance.
2. **Lost deletion acknowledgments remain a gate.** Deletion returns an asynchronous operation, and normal inventory hides the target before completion. The API provides lookup by operation ID, not a documented target-ID search. Persist operation IDs and include pending/blocked deletions in run-owned inventory. A lost first response must remain unresolved; 404 or an empty list cannot establish completed cleanup. Preserve the exact confirmation header in OpenAPI (`X-Ascii-Confirm-Delete`), despite the rebrand.
3. **Immutable launch selection remains incomplete.** Create takes an environment name and named snapshot `from`; it does not expose an immutable snapshot-ID plus environment-version selector. GET can report the observed environment version, which improves evidence but cannot prevent a concurrent alias replacement. Pre/post checks do not close that race. Ask for an atomic immutable selection or conditional precondition API.
4. **Shell transport still requires a worker.** Command requests take a string, cwd and timeout (1–600 seconds), optionally detached. There is no structured argv/env/stdin request contract or documented command-specific cancellation endpoint. Agent interrupt/prompt status are for integrated agent work, not proof of arbitrary workload cancellation. Treat ambiguous submission failures as possibly executed; never blindly retry user work.
5. **Network claims remain bounded.** No create-time network deny/allowlist/metadata-access policy appears in the reviewed schema. `noEnv: true` limits credential inheritance, not networking. Enforce supported workload controls inside the OCI boundary; leave unsupported provider-level egress claims unsupported.
6. **Remote retention still needs real lifecycle integration.** Current portable coordinator destroys resources before recording preservation. Reuse `kujo.preservation-outcome/v1`, `kujo.execution-result/v1` and `kujo.reexecution-descriptor/v1`; add provider-neutral retain/snapshot behavior only where missing. Do not make `destroy` silently mean archive. Re-execution is a new attempt, not deterministic replay. `clean --preservation` handles expired local workspaces, not Boat snapshots.
7. **Secrets and spending require explicit policy.** Automatic snapshots can retain task secrets. Start with no-secret disposable certification; never put the host key or credentials into templates. Balance exhaustion has a documented 24-hour grace period with outstanding usage payable later. Dashboard member caps and TTL are useful controls, but not a per-run dollar ceiling. Budget enforcement and erasure guarantees need provider confirmation and failure tests.

These are limits of the **reviewed public contract**, not claims that private features cannot exist. No public roadmap commitment for resolving these gaps was found in the reviewed pages. Sources: [OpenAPI](https://docs.boat.dev/openapi/boat-v1.yaml), [retention](https://docs.boat.dev/data-retention), [environments](https://docs.boat.dev/environments), [billing](https://docs.boat.dev/billing).

## Pricing and capacity refresh

Published hourly prices remain small $0.018, default $0.036, large $0.072 and xlarge $0.200. Current usable data space is 12/50/125/251 GB respectively. This is user-data capacity, not total OS disk. Current plan limits replace the September table:

| Monthly plan | Concurrent sandboxes | Starts/minute / hour / day |
| --- | --- | --- |
| $20 | 100 | 12 / 60 / 200 |
| $100 | 300 | 30 / 210 / 840 |
| $500 | 1,000 | 65 / 420 / 1,680 |
| $2,000 | 2,000 | 90 / 600 / 2,400 |

Plan dollars convert into machine time; organization quotas multiply by seats. Pricing documents xlarge as requiring a $100+ plan and operator allocation, while both the current create OpenAPI enum and published TypeScript create enum list only small/default/large. Exclude xlarge from the initial supported adapter profile until the supported API contract is clarified. Query live limits during authorized preflight; static prices are not quota reservations. [Pricing](https://docs.boat.dev/pricing), [machines](https://docs.boat.dev/machines).

## Implementation goals and next steps

| Milestone | Concrete deliverable and exit gate |
| --- | --- |
| M0: provider agreement | Send the questions below. Record answers with date and supported API/spec references. Settle ownership and deletion recovery before any claim of complete lifecycle conformance. |
| M1: offline candidate | Proposed `boat` external adapter in `adapters/official`, pinned SDK/worker, explicit endpoint/wallet, action-scoped credential reference, bounded state ledger and no live calls. Fixtures cover lost create response, expired idempotency, lost delete response, blocked deletion, scope expiry, immutable-template races, partial transfer and setup failure. Missing guarantees fail closed. |
| M2: disposable execution | Enforce OCI controls; verify workspace/image/worker digests; preserve exact argv and declared environment; collect bounded logs/artifacts; require itemized completed cleanup. Distinguish VM ready, setup done and worker ready. No task-secret snapshots or retained VM claims. |
| M3: authorized live certification | Follow existing WorkCell live-provider gates; propose `BOAT_API_KEY` plus `WORKCELL_BOAT_LIVE=1` and the global `WORKCELL_LIVE_AUTHORIZED=1` (the Boat gate is not implemented). Use one small machine, short TTL, immutable harmless fixture and unconditional cleanup. Certify actual credential scopes, resource enforcement, cancellation, restart recovery, export and cleanup on an isolated account with explicit cost limits. Attach evidence for the exact adapter/worker versions. Do not promote on fixture results alone. |
| M4: preservation extension | Add provider-neutral snapshot ownership, retention deadline, cleanup handle and honest reconstruction status to the existing preservation flow. Test no-secret snapshot capture, integrity, expiry and recovery. Use snapshot file access for bounded evidence retrieval; account ZDR remains operator policy. |

Integration ideas worth keeping: clean reusable toolchain templates; many independent disposable executions; stopped-snapshot evidence extraction; per-run usage reporting; optional lifecycle webhooks after polling is correct. Boat's integrated agent harnesses may support a later explicit workload mode, but should not replace WorkCell's deterministic command contract or expand this project into an agent orchestrator.

## Message to Boat's founder

> I'm building a direct WorkCell integration with Boat: policy-controlled jobs, reproducible inputs, evidence, and ownership-safe cleanup. The new scoped keys and snapshot APIs are useful. I reviewed the current public API and would love to clarify three things before we certify recovery:
>
> 1. Can create/fork atomically attach an immutable external run ID and nonce visible in inventory, or can we look up an idempotency key without issuing another create? What remains available after the 24-hour window?
> 2. If a DELETE is accepted but its response is lost, how can we find its deletion operation by sandbox/snapshot ID and determine completion?
> 3. Can create select an immutable snapshot ID and environment version atomically, rather than mutable names?
>
> Are these already supported through another documented interface, planned, or something we could help specify and test? We can contribute failure-injection fixtures and a small integration test suite. Secondary questions: supported xlarge API inputs, minimum key scopes for complete cleanup, provider-level network policy, and a hard per-job spend boundary.

This is a draft for the user to send; no outreach was sent.

## Verification and evidence boundaries

Reviewed the current documentation index, API/OpenAPI, SDK documentation and npm generated declarations, plus WorkCell source changes since the original report. Public document hashes and package identity are recorded in the source index. Local Markdown links and whitespace are checked for this documentation-only change. No provider account, credential, billable sandbox, deployment, or runtime integration test was used. Provider documentation describes behavior; live certification must establish observed behavior separately.
