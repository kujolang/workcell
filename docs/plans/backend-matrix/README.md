# WorkCell backend matrix architecture package

Status: implementation-ready architecture decision  
Research date: 2026-09-01  
Audience: WorkCell maintainers and the engineering agent implementing WorkCell 2.x provider portability

## Executive answer

WorkCell should adopt a **layered provider/runtime model exposed through one narrow backend adapter contract**:

```text
Agent, CLI, Dispatch, Relay, CI
              |
              v
WorkCell core: definition, policy, lifecycle, evidence, verification, cleanup
              |
              v
Backend adapter: provisioning, transport, execution control, provider observations
              |
              v
Execution substrate: OCI runtime, sandbox service, VM, microVM, cluster runtime
```

The layers are semantic, not three mandatory plugin systems. WorkCell should have one adapter protocol. An adapter reports the provider and the resolved substrate separately. Docker and Podman are built-in adapters sharing OCI implementation helpers. gVisor and Kata are runtime selections beneath an adapter, not backend IDs. Firecracker is a VMM, not a usable WorkCell provider without a guest/control service. Kubernetes Jobs and managed cloud jobs are higher schedulers and belong in later external adapters, not WorkCell core.

The stable principle remains correct for remote execution, with one precision:

> The selected provider and substrate define what is physically reachable and what isolation they claim. WorkCell defines what is requested, authorized, bounded, observed, exported, verified, and recorded. WorkCell may only call a control enforced when it has evidence at the authority level recorded in the receipt.

## Binding recommendations

- Canonical lifecycle: **resolve → provision → prepare → execute → collect → verify → export → cleanup → record**. `record` also runs on partial failure. Provision and cleanup may be no-ops for an already available local engine, but their outcomes remain explicit.
- Mandatory adapter operations: `describe`, `resolve`, `provision`, `prepare`, `execute`, `collect`, `export`, `destroy`, and `inventory`. The core owns recovery by reconciling inventory and invoking `destroy` only for run-owned resources.
- Mandatory running-workload control: every adapter must provide an effective termination path. Graceful process cancellation is a capability; destroying a run-owned sandbox is the required fallback.
- Optional capabilities: pause, resume, snapshot, provider-side Git clone, persistent volumes, resource metrics, globally ordered logs, cost reporting, custom images, and network allowlists.
- Default negotiation is fail-closed. A requested authorization, isolation, resource, transfer, evidence, or cleanup requirement that cannot be satisfied prevents provisioning. There is no generic best-effort mode. Operator policy may explicitly permit degradation only for named non-security evidence enhancements, such as provider cost or fine-grained metrics.
- Backend selection is explicit and host/operator-owned. Do not implement automatic `cheap`, `fast`, or `strong-isolation` routing in the first release.
- The portable WorkCell definition describes workload and requirements. Provider credentials, endpoints, regions, account/project IDs, and provider-native knobs live in host profiles or adapter manifests. Existing v1 `runtime.backend` remains compatible during migration.
- Remote input defaults to a clean, bounded, one-commit portable Git clone package created by WorkCell. Provider-side Git clone is optional and never the default because it adds mutable refs, network, and credentials to the trust boundary.
- Artifact export remains declared-only. A backend must never download the entire workspace implicitly.
- Receipts record provider, adapter, and substrate separately, plus a per-control ledger that distinguishes requested, accepted, resolved, enforcement claim, observation, contradiction, and unknown state.

## Initial implementation batch

The first batch is intentionally five adapters, implemented in this order:

1. **Docker** — built-in; preserves the current default and proves zero-regression extraction.
2. **Podman** — built-in; proves that capabilities, host inspection, and OCI differences are not backend-name conditionals in core.
3. **E2B** — official external adapter; the smallest remote vertical slice and strongest initial agent-ecosystem distribution opportunity.
4. **Vercel Sandbox** — official external adapter; proves a public REST-backed Firecracker service, dynamic network policy, and ephemeral-versus-persistent resolution.
5. **Daytona** — official external adapter; proves container/VM classes, tier-aware outbound policy, and self-hosted/operator-controlled deployment.

Modal, Runloop, Cloudflare Sandbox, and Kubernetes Agent Sandbox are the next official-adapter candidates. Cloudflare waits for Sandbox SDK 1.0 stability. Modal remains valuable but adds an SDK runtime dependency, while the Vercel REST surface is the cleaner second remote proof. Kubernetes Agent Sandbox should be implemented as an operator adapter only after retry/attempt, object-transfer, and cluster-policy evidence semantics are stable.

## Distribution classification

- **WorkCell core:** adapter protocol, conformance runner, fixture backend, Docker, Podman, provider-neutral profiles, receipts, recovery.
- **Official separate adapters:** first E2B, Vercel Sandbox, Daytona; next Modal, Runloop, Cloudflare Sandbox, Kubernetes Agent Sandbox; later managed cloud jobs where demand justifies them.
- **Community/operator adapters:** Fly Machines, Kubernetes Jobs without Agent Sandbox, Nomad, Coder/Gitpod host integrations, containerd direct, organization-specific VM services.
- **Runtime/substrate profiles, not adapters:** gVisor, Kata Containers, Lima, Colima, Docker Desktop VM.
- **Deliberately unsupported as same-workload backends:** raw Firecracker, raw Apple Virtualization.framework, Wasmtime/WASI, GitHub Codespaces as a disposable run resource, and provider SDKs that cannot expose a bounded lifecycle and cleanup inventory.

## Package map

- [Current architecture](01-current-architecture.md)
- [Backend landscape](02-backend-landscape.md)
- [Taxonomy and inclusion decisions](03-backend-taxonomy.md)
- [Capability matrix](04-capability-matrix.md)
- [Security boundaries](05-security-boundaries.md)
- [Target architecture](06-target-architecture.md)
- [Backend contract](07-backend-contract.md)
- [Definition evolution](08-workcell-definition-evolution.md)
- [Receipts and evidence](09-receipt-evidence-design.md)
- [Testing and conformance](10-testing-conformance.md)
- [Performance and cost](11-performance-cost-model.md)
- [Agent, Relay, and Dispatch integration](12-agent-relay-dispatch-integration.md)
- [Distribution and competitive analysis](13-distribution-analysis.md)
- [Priorities](14-backend-priorities.md)
- [Risk register](RISK_REGISTER.md)
- [Acceptance criteria](ACCEPTANCE_CRITERIA.md)
- [Dependency-ordered implementation plan](IMPLEMENTATION_PLAN.md)
- [Implementation agent prompt](IMPLEMENTATION_PROMPT.md)
- [Research source ledger](REPORT_SOURCE.md)
- [Backend data](BACKEND_MATRIX.json)
- [Capability contract data](CAPABILITY_MATRIX.json)
- [Adapter protocol proposal](BACKEND_CONTRACT_PROPOSAL.json)

## Research method and limitations

The review covered all hand-written WorkCell source, tests, fixtures, examples, release workflows, architecture/security/compatibility documentation, and relevant boundaries in Kujo Agent, Relay, Dispatch, Agents SDK, RunLedger, Watchdog, Eval, CaseFile, Spec, ShipCheck, Kujo Workflows, and Kujo Pi. Provider facts use first-party product, API, security, pricing, and runtime documentation available on the research date. Unknown matrix values remain `null`; marketing phrases are not converted into security guarantees.

No live provider credentials or billable environments were used. Startup numbers in provider marketing are not accepted as WorkCell benchmarks. Every live performance and security claim remains a release gate for the exact adapter version and target environment.
