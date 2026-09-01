# Security boundary analysis

## Non-negotiable receipt rule

WorkCell must never convert configuration intent or provider marketing into stronger isolation evidence. A receipt must answer five independent questions for every material control:

1. What did the workload request?
2. What did the adapter accept and resolve?
3. Who claims to enforce it?
4. What did WorkCell observe, and how narrow was that observation?
5. What is unsupported, not enforceable, contradicted, or unknown?

## Authority levels

From strongest to weakest for a particular fact:

1. WorkCell-controlled local mechanism with verified result, such as safe artifact extraction or host timeout watchdog.
2. Provider control-plane response tied to the actual resource and API version.
3. Runtime/host inspection tied to the actual resource.
4. Repeatable conformance probe tied to the run.
5. Provider documentation claim.
6. Operator assertion/profile.
7. Unknown.

These levels are not globally ordered security certifications. For example, an egress probe confirms one destination was blocked; it does not prove all egress is blocked.

## Provider boundary table

| Candidate | WorkCell enforces | WorkCell requests / provider claims | Cannot guarantee | Operator responsibility |
| --- | --- | --- | --- | --- |
| Docker | definition, clean workspace, argv, host timeout/output, declared export, hashes, label-scoped cleanup | cgroup limits, namespaces, seccomp/AppArmor, network none, identity | compromised daemon/kernel, generic disk quota, outbound allowlist | host/daemon/kernel hardening, file sharing, firewall, image governance |
| Podman | same core controls | rootless mapping, cgroups, seccomp, network none | unsupported rootless cgroup controls, host kernel, disk quota | subordinate IDs, cgroup v2, storage/network config |
| E2B | input/output manifests, local watchdog, artifact verification, cleanup request | sandbox isolation, configured CPU/memory, deny-all, timeout | PID limit; underlying host proof; allowlist details until verified | account plan, API-key policy, retention and region acceptance |
| Vercel Sandbox | manifests, declared export, host watchdog, ephemeral request | Firecracker isolation claim, network policy, CPU class, timeout | underlying VMM configuration, PID controls, plan-specific ceilings | project/OIDC policy, region/data retention, image governance |
| Daytona | manifests, export, watchdog, cleanup inventory | class-specific container/VM isolation, resource allocation, eligible-tier firewall | a container class as VM isolation; Tier 1/2 network none; PID control | tier/class/profile, self-hosted runner hardening, volume/snapshot ownership |
| Modal | manifests, export, watchdog | gVisor/provider isolation, CPU/memory hard limits, network block/allowlists | PID controls; experimental VM semantics; protocol stability | app/token policy, volume retention, SDK/API pinning |
| Runloop | manifests, export, watchdog | VM/microVM isolation claim, sizes, hostname policy, suspend disk snapshot | process-preserving resume, PID/CIDR controls, metrics completeness | blueprint, API key, snapshot/storage retention |
| Cloudflare Sandbox | manifests and trusted-client validation | deployed Worker/DO/Container policy, internet-off/host filtering | application authentication unless operator supplies it; stable 1.0 behavior | Worker auth, bindings, image deployment, rollout, R2/DO retention |
| Fly Machines | input/image metadata and destroy request | VM sizing, lifecycle, network rules | one stable exec/file/log boundary; proxy-policy coverage | guest agent, private network, log pipeline, volumes, app ownership |
| Kubernetes/Agent Sandbox | manifests and resource labels | ResourceQuota, NetworkPolicy, RuntimeClass, deadlines | CNI/runtime enforcement from YAML alone; single attempt unless configured | cluster RBAC, CNI, nodes, admission, storage, log/metric retention |
| Fargate/Cloud Run/ACA Jobs | manifests, adapter protocol, object hashes | task/job CPU/memory/timeouts | Docker-style network none, PID limit, native artifacts | IAM, VPC/firewall, object storage, logging, scheduler policy |
| gVisor/Kata | nothing directly; WorkCell records inspection | OCI runtime isolation mechanisms | complete Linux compatibility; operator network/storage/control plane | runtime install, host/kernel/hypervisor, RuntimeClass policy |
| Firecracker raw | nothing without a new provider service | VMM/jailer configuration | guest exec, artifacts, logs, networking, cleanup service | effectively the entire provider control plane |

## Requested versus enforced schema

Receipts use a `controls[]` ledger, not a flat `effective_security_policy` assertion:

```json
{
  "control": "compute.memory_limit",
  "requested": {"value": "1g", "required": true},
  "acceptance": "accepted",
  "resolved": {"bytes": 1073741824, "kind": "hard-limit"},
  "enforcement": {
    "status": "provider-claimed",
    "authority": "provider-api",
    "evidence_ref": "provider/resolve.json#/memory"
  },
  "observation": {"status": "not-observed"},
  "limitations": []
}
```

`provider-claimed` is not rendered as “WorkCell enforced.” Human output should say “provider configured/reported.” Only core mechanisms such as local path validation, output truncation, local hashing, and owned cleanup decisions can be `workcell-enforced`.

## Network semantics

Core semantic modes remain `none`, `default`, and operator-managed allowlist/private profiles, but resolution is richer:

- `none` means no intentional workload network path. The backend must document DNS, loopback, metadata endpoints, provider control channels, proxy/interception, and exceptions.
- A domain allowlist records supported protocols, wildcard behavior, DNS ownership, redirects, IP changes, SNI/TLS interception, and whether provider services bypass policy.
- A named network is a reference to operator policy, not proof. It requires an attestation/profile and optionally a run probe.
- Inbound preview URLs/tunnels are disabled unless explicitly requested; a provider's ability to create them is not permission.

Daytona tier restrictions, Cloudflare Worker handlers, Fly Proxy exceptions, and managed job VPC policy show why a boolean capability is insufficient.

## Secrets

- Definitions and adapter manifests contain secret names/references only.
- Resolution order reuses Kujo Agent conventions: CI environment, project-local ignored owner-only secret file where explicitly supported, then OS credential store. Operator profiles name credential references.
- Adapters receive credentials through an inherited allowlist or a one-shot local channel. Never argv, request fixture, manifest, receipt, raw provider metadata, or saved adapter environment.
- Prefer provider credential brokers that keep values outside the sandbox, but record the broker as a separate capability and limitation.
- Core redacts provider API errors, streams, patches, and adapter protocol frames before persistence. Adapters must also redact before emitting; conformance injects canary credentials and scans all evidence.

## Images and snapshots

An OCI digest verified locally is not automatically the runtime image identity remotely. Receipts record source reference, requested digest, provider-resolved image/snapshot ID, and verification authority. Provider-created snapshots are executable state and require ownership, expiration, integrity metadata when available, and separate cleanup. WorkCell does not claim snapshot confidentiality or reproducibility unless provider evidence supports both.

## Remote client loss

The host watchdog must write a durable recovery record immediately after provisioning and before workspace upload. It includes provider resource IDs, ownership marker, adapter/version, profile ID, created time, expiration, and planned cleanup. A network disconnect does not mean the sandbox stopped. Recovery reconciles provider state and may destroy only resources whose ownership marker and provider/account/profile match the record.

## Security release gates

Every official adapter must prove:

- requested unsupported controls fail before compute allocation;
- credential canaries do not appear in protocol frames or evidence;
- network-none probes fail outbound DNS, IP, metadata, and representative provider-service paths where safe;
- no retry or replacement attempt is hidden;
- symlink/traversal/oversize artifact attacks fail closed;
- cleanup is idempotent and cannot delete an unowned same-name resource;
- receipts render provider claims and observations without stronger wording;
- provider/API/runtime versions are captured.

