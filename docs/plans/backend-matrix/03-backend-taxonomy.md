# Backend taxonomy and inclusion decisions

## The model

One flat list is misleading. WorkCell needs three named facts:

1. **Backend adapter** — the component WorkCell calls to provision/control compute and transfer bytes.
2. **Provider** — the engine or service responsible for the resource lifecycle and account boundary.
3. **Substrate/runtime** — the isolation/runtime technology actually used or claimed underneath.

Examples:

| Backend adapter | Provider | Runtime/substrate |
| --- | --- | --- |
| `docker` | local Docker Engine | `runc`, `runsc`, or Kata; Linux or Docker Desktop VM host |
| `podman` | local Podman | crun/runc; rootless or rootful host |
| `vercel-sandbox` | Vercel Sandbox | Firecracker, provider-claimed |
| `kubernetes-agent-sandbox` | operator Kubernetes cluster | default OCI runtime, gVisor, or Kata RuntimeClass |
| `daytona` | Daytona Cloud or operator Daytona deployment | provider-reported container or VM class |

Receipt fields must not collapse these identities.

## Categories

### A. Direct local execution providers

They expose create/run/log/wait/stop/remove and direct workspace access on a developer or CI host.

- Docker — built-in.
- Podman — built-in.
- containerd — possible later adapter; not initial.

### B. Remote sandbox providers

They expose a run-owned sandbox plus process and filesystem APIs.

- E2B, Daytona, Modal — first official external batch.
- Vercel Sandbox, Runloop — next official batch.
- Cloudflare Sandbox — official after stable 1.0 protocol.
- Kubernetes Agent Sandbox — later operator adapter.

### C. Remote VM/microVM providers

They expose a VM lifecycle but may require bootstrap and transfer protocols.

- Fly Machines — community/operator adapter; technically viable REST VM lifecycle, but more infrastructure responsibility than an agent sandbox.
- Organization-owned VM services — custom adapter if they implement conformance.
- Raw Firecracker — excluded because it is a VMM, not a provider service.

### D. Higher container/job orchestration

- Kubernetes Jobs, Nomad, Fargate, Cloud Run Jobs, Azure Container Apps Jobs — later external adapters only.
- They must suppress implicit retries or expose separate attempt evidence.
- WorkCell never owns scheduling, repair, fleet scaling, or cluster policy.

### E. Hosted development environments

- Codespaces, Gitpod, Coder — invocation hosts/templates, not normal backends.
- Their persistent user workspace is not a run-owned disposable resource.

### F. Lower isolation/runtime layers

- gVisor, Kata, Firecracker, Apple Virtualization.framework, Lima, Colima — substrate facts or runtime selections, not provider adapters.

### G. Different workload contracts

- Wasmtime/WASI — excluded until WorkCell defines a different workload kind.

## Inclusion test

A candidate belongs behind the WorkCell backend adapter only when all answers are yes:

1. Can WorkCell create or exclusively acquire a resource for one run?
2. Can it transfer a clean, bounded workspace without exposing the source checkout or ambient credentials?
3. Can it execute an argv workload with a stable terminal result?
4. Can it bound lifetime and terminate the resource after client loss?
5. Can it collect logs and declared artifacts with explicit completeness/ordering quality?
6. Can it inventory and destroy only WorkCell-owned resources?
7. Can it describe capabilities and security evidence without relying on backend-name assumptions?
8. Can normal tests use deterministic fixtures without live credentials?

Failure of item 2, 4, 5, or 6 excludes the adapter. Missing optional capabilities such as snapshots or metrics does not.

## Answers to the abstraction questions

### Should Docker and Podman become backend implementations?

Yes. They prove the adapter extraction without changing current behavior. They should share an internal OCI CLI driver while keeping separate capability probes and error normalization.

### Is one backend abstraction enough?

One **adapter protocol** is enough; one flat conceptual layer is not. The protocol covers provider lifecycle and transport. It reports the runtime/substrate rather than attempting to control every lower layer. A second pluggable runtime interface is unnecessary in the first implementation and would over-generalize. OCI adapters may use an internal runtime-profile resolver for `runc`, gVisor, or Kata.

### Which environments deliberately do not belong?

- raw VMM/frameworks without guest lifecycle and evidence transport;
- persistent developer workspaces not exclusively run-owned;
- schedulers whose retries cannot be disabled or represented honestly;
- runtimes that cannot execute the WorkCell workload ABI;
- providers without bounded artifact download and ownership-safe cleanup;
- any service that requires a mandatory Kujo-hosted control plane.

## Built-in versus external

Built-ins are limited to Docker, Podman, the deterministic fixture backend, adapter discovery/registry, and conformance tooling. This keeps the WorkCell source install small and offline-capable.

Official adapters live in separate versioned Kujo packages/repositories and are maintained against provider API versions. They may use a provider SDK only where protocol-level HTTP would materially increase correctness risk. Adapters are executable protocol peers rather than imported language libraries, so a necessary TypeScript, Python, Go, or Rust SDK does not enter WorkCell core.

Community/operator adapters use the same manifest and conformance suite. “Signed” should mean artifact signature verification against operator trust policy, not a central WorkCell approval service. Conformance proves protocol behavior for advertised capabilities; it is not a security certification.

## Selection and routing

Backend selection precedence:

1. operator-enforced policy/profile;
2. explicit CLI or host invocation override;
3. Agent Project environment mapping;
4. a portable default backend in host config;
5. v1 compatibility value `runtime.backend`.

No automatic route selection is planned. Labels such as `strong-isolation`, `cheap`, `fast`, `local`, or `gpu` are not trustworthy without provider-, region-, plan-, and policy-specific facts. A future router may filter on required capabilities and operator-approved profiles, but the final backend remains explicit and receipt-visible.

