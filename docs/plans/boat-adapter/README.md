# WorkCell + Boat: current integration plan

Reviewed **2026-09-30**, against WorkCell `e645d80` (1.2.0), Kujo 1.6.0 at `44af277848173664f72ca85f2a1b3b98d634ecdd`, current public Boat documentation, and the Boat founder's direct answers supplied by the user. This is the current decision record. It supersedes conflicting names, provider facts, milestones, and preservation claims in the [September 5 Box research](../box-adapter/README.md); that report remains the detailed historical design. No adapter implementation or live certification is claimed. [Source hashes](source-index.json) identify the September 26 public inputs; implementation must refresh them before pinning dependencies. The current npm SDK was `@boatdev/sdk@1.4.0` on September 30.

## Recommendation and scope

Proceed with an **offline experimental external adapter**, followed by provider clarification and explicitly authorized live certification. Keep WorkCell on the controller host, with a pinned minimal worker supervising a constrained OCI workload inside each Boat VM. Keep the controller credential off the VM. Boat supplies compute and transport; WorkCell owns workload policy, evidence, verification, recovery, and cleanup. Paperclip and additional orchestration systems remain out of scope.

The VM's shell and sudo access do not satisfy WorkCell's exact argv, OCI image, CPU/memory/PID, read-only root, and network controls. The worker must enforce those controls through Docker and report observations honestly. A Boat snapshot can accelerate worker/toolchain preparation, but cannot substitute for the workload image digest. Use disposable runs first; retained remote snapshots are a later, separate lifecycle milestone.

## What changed

| Area | Current evidence | Integration consequence |
| --- | --- | --- |
| Identity and API | Boat by ASCII; API base `https://boat.dev/api/v1`, resources `/sandboxes`; docs at `docs.boat.dev`. | Use Boat naming in new provider IDs, profiles and documentation. Do not assume every old URL/header/package was mechanically renamed. |
| SDKs | Published npm `@boatdev/sdk@1.4.0` on September 30, class `BoatApi`; Python uses package `boat-sdk`, module `boat_sdk`. | Pin the current package and integrity at implementation time; review its serializers against OpenAPI. Existing Box package pins are historical. |
| Credentials | Scoped, expiring keys with action and sandbox/environment restrictions; old keys remain account-wide until reissued. Scoped creation can be temporarily disabled. | Use a host-only `BOAT_API_KEY` with explicit actions and short expiry. Test create, inventory and cleanup visibility with the actual scope. A `ci` preset is not proof that every required cleanup route is granted. |
| WorkCell preservation | `c11e114` added preservation outcomes; `ecdddbe`/`e57ea19` added execution/re-execution evidence; `0baac3d` added expired local-workspace cleanup. | Reuse these contracts. The old assertion that remote `keep_failed` is simply ignored is obsolete. Remote cleanup still destroys the resource and filesystem preservation reports unsupported; Boat snapshot retention is not implemented. |
| Snapshot inspection | Cursor-paginated history, tree browsing, direct file/folder download from a stopped snapshot, and chunk download/reassembly. | Useful later for bounded forensic export without restarting a VM. Validate paths, byte limits, hashes and complete history; a truncated/unavailable tree is not complete evidence. |
| Stop failures and billing | Snapshot documentation says a refused stop leaves the VM running but pauses billing from the first refused attempt, until use resumes. | Replace the old blanket assumption that a failed snapshot necessarily keeps accruing compute charges. This is a documented provider behavior, not a tested hard budget guarantee. |
| Billing visibility | Per-sandbox usage and explicit organization wallet selection; member caps exist in the dashboard. | Record provider-reported cost separately from local estimates. Set the wallet explicitly; organization billing does not make inventory shared. |

Sources: [API](https://docs.boat.dev/api/v1), [OpenAPI](https://docs.boat.dev/openapi/boat-v1.yaml), [keys](https://docs.boat.dev/api-keys), [TypeScript](https://docs.boat.dev/sdks/typescript), [Python](https://docs.boat.dev/sdks/python), [snapshots](https://docs.boat.dev/snapshots), [billing](https://docs.boat.dev/billing), [WorkCell lifecycle](../../runtime-lifecycle.md), [remote coordinator](../../../src/execution/portable_coordinator.kujo).

## Remaining limitations and build gates

1. **Create/fork recovery is supported inside a defined window.** Public docs state that retrying the exact account, `Idempotency-Key`, and request body returns the same sandbox; keys are retained for 24 hours. The founder confirmed this is the intended lost-response recovery path. Persist the exact key and canonical request before calling Boat, retry only the identical body, handle `idempotency_in_progress`, and fail closed after the 24-hour window. WorkCell recovery currently inventories an intent without replaying provision, so the implementation must add the smallest provider-neutral recovery path or prove that bounded in-call retries cover its stated crash model. Do not turn `inventory` into a mutating create call.
2. **Delete recovery is supported, pending live certification.** The founder confirmed that repeating `DELETE` for the same sandbox ID returns the same deletion operation. Persist the sandbox ID and any returned operation ID, re-send the exact target-bound request after a lost response, then poll to `completed`. The public OpenAPI retrieved on September 30 documents asynchronous deletion and operation polling but does not yet state this replay behavior, so test it live before promotion. Preserve the exact confirmation header (`X-Ascii-Confirm-Delete`) despite the rebrand. A bare 404 or empty list still is not cleanup proof without a successful replay or terminal operation record.
3. **Immutable launch selection remains the provider gap.** The founder confirmed this is not supported yet and is on Boat's roadmap. Create takes an environment name and named snapshot `from`; it does not atomically select an immutable snapshot ID plus environment version. GET can report the observed environment version, which improves evidence but cannot prevent a concurrent alias replacement. Keep reusable-template mode experimental, record the observed identities, and use fresh `noEnv` sandboxes for initial certification.
4. **Shell transport still requires a worker.** Command requests take a string, cwd and timeout (1–600 seconds), optionally detached. There is no structured argv/env/stdin request contract or documented command-specific cancellation endpoint. Agent interrupt/prompt status are for integrated agent work, not proof of arbitrary workload cancellation. Treat ambiguous submission failures as possibly executed; never blindly retry user work.
5. **Network claims remain bounded.** No create-time network deny/allowlist/metadata-access policy appears in the reviewed schema. `noEnv: true` limits credential inheritance, not networking. Enforce supported workload controls inside the OCI boundary; leave unsupported provider-level egress claims unsupported.
6. **Remote retention still needs real lifecycle integration.** Current portable coordinator destroys resources before recording preservation. Reuse `kujo.preservation-outcome/v1`, `kujo.execution-result/v1` and `kujo.reexecution-descriptor/v1`; add provider-neutral retain/snapshot behavior only where missing. Do not make `destroy` silently mean archive. Re-execution is a new attempt, not deterministic replay. `clean --preservation` handles expired local workspaces, not Boat snapshots.
7. **Secrets and spending require explicit policy.** Automatic snapshots can retain task secrets. Start with no-secret disposable certification; never put the host key or credentials into templates. Balance exhaustion has a documented 24-hour grace period with outstanding usage payable later. Dashboard member caps and TTL are useful controls, but not a per-run dollar ceiling. Budget enforcement and erasure guarantees need provider confirmation and failure tests.

These are limits of the reviewed public contract plus the founder clarification supplied on September 30. The immutable selector is the only item the founder identified as roadmap work. Sources: [API](https://docs.boat.dev/api/v1#idempotent-sandbox-creation), [OpenAPI](https://docs.boat.dev/openapi/boat-v1.yaml), [retention](https://docs.boat.dev/data-retention), [environments](https://docs.boat.dev/environments), [billing](https://docs.boat.dev/billing).

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
| M0: provider agreement | **Complete for the three primary questions.** Same-key create/fork replay and same-target DELETE replay are supported; immutable snapshot/environment selection is not yet supported and is on the roadmap. Public documentation and live failure-injection evidence still gate promotion. |
| M1: offline candidate | Proposed `boat` external adapter in `adapters/official`, pinned SDK/worker, explicit endpoint/wallet, action-scoped credential reference, bounded state ledger and no live calls. Fixtures cover lost create response, expired idempotency, lost delete response, blocked deletion, scope expiry, immutable-template races, partial transfer and setup failure. Missing guarantees fail closed. |
| M2: disposable execution | Enforce OCI controls; verify workspace/image/worker digests; preserve exact argv and declared environment; collect bounded logs/artifacts; require itemized completed cleanup. Distinguish VM ready, setup done and worker ready. No task-secret snapshots or retained VM claims. |
| M3: authorized live certification | Follow existing WorkCell live-provider gates; propose `BOAT_API_KEY` plus `WORKCELL_BOAT_LIVE=1` and the global `WORKCELL_LIVE_AUTHORIZED=1` (the Boat gate is not implemented). Use one small machine, short TTL, immutable harmless fixture and unconditional cleanup. Certify actual credential scopes, resource enforcement, cancellation, restart recovery, export and cleanup on an isolated account with explicit cost limits. Attach evidence for the exact adapter/worker versions. Do not promote on fixture results alone. |
| M4: preservation extension | Add provider-neutral snapshot ownership, retention deadline, cleanup handle and honest reconstruction status to the existing preservation flow. Test no-secret snapshot capture, integrity, expiry and recovery. Use snapshot file access for bounded evidence retrieval; account ZDR remains operator policy. |

Integration ideas worth keeping: clean reusable toolchain templates; many independent disposable executions; stopped-snapshot evidence extraction; per-run usage reporting; optional lifecycle webhooks after polling is correct. Boat's integrated agent harnesses may support a later explicit workload mode, but should not replace WorkCell's deterministic command contract or expand this project into an agent orchestrator.

## Founder clarification

The user sent the three recovery questions to Boat and supplied the founder's reply on September 30:

1. Create and fork recover by retrying the same `Idempotency-Key`; the retry returns the same sandbox. This matches the public idempotency documentation and its 24-hour retention period.
2. Re-send DELETE for the sandbox ID; it returns the same deletion operation. Treat this direct confirmation as a testable contract until the public reference states it explicitly.
3. Atomic immutable snapshot/environment selection is not available yet and is on the roadmap.

This closes the provider-question milestone. It does not replace offline failure injection or credential-gated live certification.

## Verification and evidence boundaries

Reviewed the current documentation index, API/OpenAPI, SDK documentation and npm generated declarations, plus WorkCell source changes since the original report. Public document hashes and package identity are recorded in the source index. Local Markdown links and whitespace are checked for this documentation-only change. No provider account, credential, billable sandbox, deployment, or runtime integration test was used. Provider documentation describes behavior; live certification must establish observed behavior separately.
