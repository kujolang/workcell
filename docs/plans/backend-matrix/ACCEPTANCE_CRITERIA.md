# Acceptance criteria and explicit decision answers

## Product acceptance

- Existing WorkCell v1 Docker and Podman definitions, CLI, exit categories, receipts, artifacts, verification, and cleanup retain equivalent or stronger behavior.
- A v2 workload runs unchanged through Docker, Podman, and the E2B proof adapter by changing only the host/operator profile.
- Unsupported required controls fail at resolve before compute creation.
- Receipts distinguish adapter, provider, runtime/substrate, requested, accepted, resolved, enforcement authority, observation, unsupported/not-enforceable, unknown, and contradiction.
- Remote input is derived from an exact clean commit and verified after materialization.
- Only declared artifacts are downloaded, safely validated, hashed, and added to the offline manifest.
- Timeout/cancel/disconnect cannot be reported as workload success; cleanup/recovery remains ownership-scoped.
- Core development and conformance are offline and need no cloud credentials or non-Kujo provider SDK.
- The official E2B adapter passes offline conformance and a gated exact-version live smoke with zero remaining owned resources.

## Explicit answers to the 35 research questions

1. **What does WorkCell own today?** Strict definition validation, clean disposable Git workspaces, semantic authorization/bounds, OCI policy construction, lifecycle/failure classification, logs/redaction, change/patch collection, declared artifacts, verification, receipts/manifests, and ownership-scoped cleanup/recovery.
2. **What is Docker/Podman-specific?** Backend-name schema, OCI image build/pull/inspect, engine security inspection, CLI argv, mounts/identity/cgroup/network/security flags, container logs/stop/remove/inventory, and container-shaped fields across policy, verification, coordinator, and receipts.
3. **Smallest preserving interface?** `describe`, `resolve`, `provision`, `prepare`, `execute`, `collect`, `export`, `destroy`, `inventory`, with optional `cancel/pause/resume/snapshot`; semantic JSON results and opaque durable handles.
4. **Should Docker/Podman be implementations?** Yes, built-in adapters sharing visible OCI helpers.
5. **Is one abstraction enough?** One adapter protocol is enough; architecture and receipts must separately model provider and lower runtime/substrate. Do not add a second public runtime plugin interface initially.
6. **Which environments belong?** Docker, Podman, E2B, Vercel Sandbox, Daytona, Modal, Runloop, later Cloudflare operator bridge, Kubernetes Agent Sandbox, and selected cloud-job/operator adapters that pass conformance.
7. **Which do not?** Raw Firecracker/VZ, gVisor/Kata as provider IDs, Codespaces/Gitpod/Coder persistent user workspaces, Wasmtime under the Linux contract, and services without safe transfer/termination/inventory.
8. **Canonical lifecycle?** Resolve → provision → prepare → execute → collect → verify → export → cleanup → record.
9. **Mandatory operations?** Capability description/resolution, exclusive provisioning, clean staging, argv execution/terminal result, bounded logs, declared export, effective termination, inventory, idempotent destroy.
10. **Optional operations?** Graceful process cancel, pause/resume, snapshot, provider Git clone, persistent volume, metrics/cost, custom image, richer ordering.
11. **Unsupported security requirements?** Reject before provisioning. No silent downgrade and no generic best effort.
12. **Requested versus enforced representation?** Per-control requested/required, acceptance, resolved value, enforcement status/authority/evidence, observation/method/result, limitations.
13. **Remote workspace transfer?** Core-created bounded one-commit portable clone archive and manifest; provider clone only as optional exact-commit capability.
14. **Safe artifact collection?** In-workspace declared exporter, one bounded archive/manifest, local no-follow validation, limits/hashes, declared-only extraction.
15. **Log normalization?** Bounded stream events with stream ID, sequence, optional timestamps, source, ordering scope, truncation, discontinuities, and completeness.
16. **Cancellation?** Core requests graceful cancel when supported, then destroys the run-owned resource; unknown terminal state remains failure/recovery.
17. **Pause/resume in core?** Optional capability/operation only, not canonical lifecycle. Disk snapshot is not pause.
18. **Remote cleanup ownership?** Durable handle plus provider markers, run ID, nonce, account/profile match, itemized idempotent deletion.
19. **Orphan recovery?** New `workcell recover` reconciles durable journals with adapter inventory; `clean` reuses the engine for bulk owned cleanup.
20. **Receipt contents?** Normalized workload/source/backend/provider/substrate IDs, controls ledger, timings/exit/log quality, artifacts/changes/verification, resources/metrics/cost, itemized cleanup/errors.
21. **Credentials?** Kujo Agent auth/OS store/CI env references in host profiles; values never definitions, manifests, argv, receipts, logs, or artifacts.
22. **Provider-specific config?** Versioned namespaced adapter profile schema outside the workload definition; core semantics cannot be overridden there.
23. **Adapter distribution?** Docker/Podman/core built-in; official external signed/digest-pinned packages; community/operator adapters use the same protocol; no mandatory hosted registry.
24. **Third-party implementation?** Ship manifest, executable JSONL protocol implementation, offline simulator/fixtures, profile schema, docs, and conformance evidence.
25. **Proof of conformance?** Base suite plus execution-time capability suites, credential/path/ownership adversarial tests, and optional exact-version live smoke. It is not security certification.
26. **Provider drift?** API/version capture, reviewed fixtures, scheduled adapter smoke, capability snapshot diff, deprecation warnings, issue automation outside runtime.
27. **Cost representation?** Provider-reported amount or usage with currency/units/window/source; otherwise cost class and `unknown`. No invented estimate.
28. **Performance benchmark?** Phase-separated WorkCell/provider/network/workload timers, deterministic workloads, warm/cold labels, samples/region/plan/version, p50/p95 only with adequate runs.
29. **How does Kujo Agent choose?** Host/operator environment mapping and CLI/profile policy; same Agent Project and WorkCell definition.
30. **How do Agent Plugins expose it?** One bounded WorkCell execution tool plus inspect/cancel/evidence; no provider APIs or credentials in agent abstraction.
31. **Relay/Dispatch interaction?** They own orchestration, retries, repair, approvals, pause, and correlation. WorkCell owns one execution attempt and propagates cancel/receipt evidence.
32. **First 3–5 backends?** Docker, Podman, E2B, Vercel Sandbox, Daytona.
33. **Strongest distribution opportunity?** E2B initially, based on verified agent ecosystem integrations; Vercel has broader formal marketplace potential but requires a separate hosted partner product.
34. **Smallest proving implementation?** Docker/Podman extraction + fixture conformance + one E2B end-to-end remote run with clean package, network-none resolution, one artifact, receipt v2, destroy/recovery, offline verify.
35. **Out of scope?** Cloud/scheduler/CI/billing service, generic VM manager, Docker/Kubernetes/Temporal replacement, hosted Kujo control plane, automatic routing, workload repair/retry, raw VMM guest service, and alternate Wasm ABI.

## Contract acceptance

- `BACKEND_CONTRACT_PROPOSAL.json` and `CAPABILITY_MATRIX.json` validate as JSON and match narrative IDs.
- Malformed/oversize/protocol-noise adapter output fails safely.
- Operations are deadline-bounded and idempotency keys are tested.
- A provisioned handle is durably written before prepare.
- Provider non-zero workload results do not become adapter errors that lose exit/log evidence.
- `destroy` rejects ownership mismatch and treats absent owned resources idempotently.

## Security acceptance

- Receipt wording tests prevent “enforced” when authority is provider documentation, operator claim, or narrow probe.
- Network-none release profiles test DNS, IP, metadata/private, and provider exception paths where safely observable.
- Secret canaries are absent from stdout/stderr, protocol frames, fixtures, raw attachments, receipts, patches, manifests, and artifacts.
- Workspace and artifact archive bombs, hardlinks, devices, FIFOs, symlinks, absolute/traversal paths, duplicate/overlapping names, and Unicode/path edge cases fail closed.
- No official adapter hides retry, replacement, persistence, or residual billable resources.

## Verification commands for the final implementation

At minimum:

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

Plus backend protocol schema/fixture/conformance tests, Docker/Podman integration where available, E2B opt-in live smoke in an approved credentialed environment, offline receipt verification, resource inventory proving zero owned orphans, and clean-machine installation verification.

