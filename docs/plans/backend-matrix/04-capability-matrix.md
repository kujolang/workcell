# Capability model and negotiation

## Principle

Capabilities describe semantic facts, never backend names. They are versioned claims made by an adapter and resolved for one actual profile, account, plan, region, runtime class, and host. A static manifest is discovery metadata; only `resolve` produces execution-authoritative capability results.

## Capability groups

### Mandatory portable contract

Every conforming backend must satisfy these capabilities for an accepted run:

| Capability | Meaning |
| --- | --- |
| `lifecycle.provision` | Acquire a resource exclusively owned by the run, or prove a local resource namespace can be created. |
| `lifecycle.terminate` | End the workload through graceful cancel or run-resource destruction. |
| `lifecycle.destroy` | Idempotently remove every run-owned compute resource. |
| `lifecycle.inventory` | List run-owned resources and stable provider IDs for recovery. |
| `workspace.stage` | Materialize exactly the WorkCell-approved clean workspace package. |
| `workspace.collect_delta` | Return bounded change metadata/patch inputs without exporting undeclared arbitrary content. |
| `process.argv` | Execute one command without requiring unescaped shell interpolation. |
| `process.exit_status` | Return a terminal status and workload exit code or an honest unknown. |
| `execution.timeout` | Enforce a bounded lifetime with a host-side watchdog fallback. |
| `logs.bounded` | Keep captured logs under WorkCell's configured output bound. |
| `artifact.selective_export` | Export only declared paths with size/file/depth checks and safe archive semantics. |
| `environment.explicit` | Avoid ambient host environment inheritance. |
| `credentials.redacted_transport` | Inject credential values without placing them in manifests, argv, logs, receipts, or adapter errors. |
| `evidence.provider_identity` | Report adapter/provider/API/profile/resource IDs and timing. |
| `ownership.markers` | Attach and retrieve WorkCell ownership metadata before destructive cleanup. |

`network.none`, CPU, memory, and PID limits are not universally mandatory for the adapter protocol, but they are mandatory when the definition requests them. Because current WorkCell defaults request CPU, memory, PIDs, timeout, output, and network none, a backend that cannot enforce those defaults will normally reject a current portable workload at resolve time.

### Optional controls

- `compute.cpu_limit`, `compute.memory_limit`, `compute.pid_limit`, `compute.disk_limit`
- `network.none`, `network.allowlist.ip`, `network.allowlist.domain`, `network.private`, `network.custom`
- `filesystem.read_only_root`, `filesystem.tmpfs`, `filesystem.no_symlink_escape`
- `image.oci`, `image.custom`, `image.digest`, `image.signature`
- `logs.streaming`, `logs.stdout_stderr_separate`, `logs.timestamps`, `logs.global_order`
- `lifecycle.cancel_process`, `lifecycle.pause`, `lifecycle.resume`, `lifecycle.snapshot`
- `workspace.provider_git_clone`, `workspace.persistent_volume`
- `secrets.provider_store`, `secrets.egress_broker`
- `metrics.cpu`, `metrics.memory`, `metrics.disk`, `metrics.network`
- `cost.provider_usage`, `cost.provider_amount`
- `placement.region`, `placement.private_pool`

## Capability state

The state for a capability is not a boolean:

```json
{
  "id": "network.none",
  "support": "supported",
  "requested": true,
  "acceptance": "accepted",
  "resolved": {"mode": "deny-all"},
  "enforcement": {
    "status": "provider-claimed",
    "authority": "provider-api",
    "evidence": "networkPolicy=deny-all"
  },
  "observation": {
    "status": "observed",
    "method": "negative-egress-probe",
    "result": "blocked"
  },
  "limitations": []
}
```

Allowed support values are `supported`, `unsupported`, `conditional`, and `unknown`. Acceptance values are `accepted`, `rejected`, `degraded`, `not-requested`. Enforcement status is `workcell-enforced`, `provider-claimed`, `operator-claimed`, `not-enforceable`, `unsupported`, or `unknown`. Observation is separate: `observed`, `not-observed`, `contradicted`, or `not-applicable`. An observation such as a failed test connection does not prove universal firewall enforcement; it records only the probe.

## Three negotiation points

### Validate

Definition validation is backend-independent. It checks schema, bounds, contradictions, and whether a requested requirement is allowed to degrade. It does not consult credentials or make network calls.

### Inspect/resolve

`workcell inspect --backend ...` loads the adapter, verifies credentials without exposing them, evaluates static and dynamic capabilities for the selected profile/account/plan/region/runtime class, and returns a resolution. It fails before provisioning when a required capability is unsupported, conditional but unmet, or unknown.

Examples:

- Daytona Tier 1/2 cannot resolve strict `network.none` if essential services remain reachable.
- Fargate cannot resolve `network.none` merely because a security group was named; the profile must include an operator policy and a verifiable egress-deny posture.
- `runtime=runsc` does not resolve `isolation.application_kernel` until the OCI adapter inspects the selected runtime.

### Execute

The adapter rechecks volatile prerequisites immediately before provisioning and returns the actual resolved values. Drift between inspect and execution causes a `capability-drift` failure unless all changed fields are non-required evidence enhancements. The receipt stores both inspect-time and execution-time resolutions.

## Strictness

WorkCell should use two policies, not three vague modes:

1. `fail-closed` — default. Every requested capability is required.
2. `explicit-degradation` — an operator profile may name specific evidence-only capabilities allowed to be absent, such as `metrics.cpu` or `cost.provider_amount`.

The following can never degrade silently or through a wildcard: workspace source integrity, dirty-source refusal, artifact declaration, path safety, credential redaction, timeout/termination, ownership-safe cleanup, output bounds, and any requested network/isolation/resource control.

A definition never says “best effort.” If a portable workload does not require a capability, it omits the requirement. If an operator permits missing metrics, the receipt records `degraded` and why. A request for `network.none` can only be `accepted` and enforced/claimed with evidence or rejected; provider-default networking is not a compatible substitute.

## Capability implication rules

- Advertising `lifecycle.pause` without `lifecycle.resume` is invalid.
- Disk snapshot resume is not process pause/resume. It advertises `lifecycle.snapshot`, not `lifecycle.pause`.
- `logs.streaming` does not imply stdout/stderr separation, timestamps, global ordering, completeness, or retention.
- `image.oci` does not imply digest verification; each is separate.
- `network.allowlist.domain` must state protocols, DNS behavior, wildcard rules, proxy/interception, and provider exceptions.
- `compute.cpu_limit` distinguishes request/reservation from a hard ceiling.
- `workspace.provider_git_clone` does not satisfy `workspace.stage` unless commit identity, credential isolation, dirty-source policy, and input manifest are equivalent.
- `cost.provider_amount` requires provider-reported currency and billing window. WorkCell estimates never satisfy it.

## Backend resolution examples

| Backend/profile | Likely accepted current defaults | Conditional/rejected fields |
| --- | --- | --- |
| Docker/rootful Linux | CPU, memory, PID, timeout, output, network none | disk limit unknown; isolation shared kernel |
| Podman/rootless+cgroup v2 | CPU, memory, PID, timeout, output, network none | cgroup-v1 controls may reject; disk unknown |
| E2B/eligible plan | CPU, memory, timeout, output, network deny-all | PID unknown; allowlist pending schema proof |
| Vercel/ephemeral | CPU class, timeout, output, deny-all/domain/IP policy | PID unknown; precise memory/disk ceiling plan-dependent |
| Daytona/Tier 3+ eligible class | CPU, memory, disk, timeout, deny-all/allowlist | PID unknown; class and tier must resolve |
| Cloud Run Job/default | CPU, memory, timeout, logs | network none rejected without verified VPC policy; workspace/artifacts require object protocol |

The machine-readable definitions are in `CAPABILITY_MATRIX.json`.

