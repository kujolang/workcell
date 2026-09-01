# Backend priorities

## Scoring method

Scores support implementation sequencing, not security certification or provider quality. Each criterion is 1–5 and weighted: adoption 15%, agent relevance 15%, API quality 15%, implementation ease 10%, architecture coverage 10%, security-control fit 10%, distribution 10%, pricing accessibility 5%, offline/live testability 10%.

| Candidate | Weighted score / 100 | Tier | Decision |
| --- | ---: | --- | --- |
| E2B | 89 | first remote | Official adapter; implement after OCI extraction/conformance fixture |
| Vercel Sandbox | 87 | first remote | Official adapter; second remote vertical slice |
| Docker | 86 | foundation | Built-in; first extraction slice |
| Daytona | 84 | first remote | Official adapter; third remote slice with tier/class negotiation |
| Podman | 82 | foundation | Built-in; second extraction slice |
| Modal | 78 | next | Official adapter after SDK/runtime strategy is proven |
| Runloop | 76 | next | Official adapter; overlaps initial remote coverage |
| Kubernetes Agent Sandbox | 73 | next/operator | Official operator adapter after scheduler/attempt semantics |
| Cloudflare Sandbox | 69 | defer | Official operator bridge after SDK 1.0 stability |
| Cloud Run Jobs | 63 | later | Official cloud-job adapter if demanded |
| AWS Fargate | 61 | later | Official cloud-job adapter if object/VPC protocol is justified |
| Azure Container Apps Jobs | 59 | later | Official cloud-job adapter after missing controls are verified |
| Fly Machines | 54 | community/operator | No initial direct adapter; requires guest-agent/control design |
| Nomad | 52 | community/operator | External enterprise adapter only |
| containerd | 50 | community/later local | Adds no first-batch category; not a security tier |
| Codespaces/Gitpod/Coder | 40 | host integration | Templates/invocation hosts, not normal backends |
| raw Firecracker | 27 | unsupported | Lower VMM; building a provider is out of scope |
| Wasmtime/WASI | 25 | unsupported workload | Different ABI; needs a future workload contract |

The score includes architecture coverage, so Docker/Podman remain foundation work despite E2B/Vercel's distribution score. Exact criterion rows are research judgments derived from the documented capabilities; unknown fields reduce rather than assume a score.

## First batch

### 1. Docker

Extract existing behavior behind the adapter types with no public change. It establishes the protocol-independent core and provides the regression baseline.

### 2. Podman

Move Podman-specific security/rootless inspection behind the adapter and shared OCI driver. This proves backend capability resolution cannot be a Docker alias.

### 3. E2B

Implement the smallest remote slice: clean package upload, one command, stream capture, deny-all networking where resolved, declared artifact archive, kill/destroy, inventory/recovery. It has the strongest immediate agent distribution path.

### 4. Vercel Sandbox

Use the public REST API to prove a second independent remote implementation, Firecracker provider claims, dynamic network policy, non-persistent resolution, command log recovery, and snapshots kept outside the core lifecycle.

### 5. Daytona

Prove account-tier and sandbox-class capability negotiation, container-versus-VM evidence, explicit ephemeral mode, strict eligible-tier network policy, and self-hosted endpoint profiles.

## Smallest architecture proof

The smallest credible proof is not five integrations. It is:

1. Docker and Podman behind semantic adapters with all v1 gates unchanged.
2. Executable fixture adapter and base conformance suite.
3. One E2B remote end-to-end run using a clean portable package, one declared artifact, deny-all network resolution, normalized logs, receipt v2, destroy, recovery inventory, and offline verification.

Only after that proof should Vercel and Daytona begin. This prevents cloud-specific assumptions from hardening before the contract has two local and one remote implementation.

## Deferred reasons

- Modal: strong capability fit, but SDK-first integration adds an adapter runtime/dependency decision after HTTP-native proof.
- Runloop: suitable but overlaps initial agent sandbox and persistent workspace coverage.
- Cloudflare: operator deployment and pre-1.0 divergence make it a poor contract validator today.
- managed jobs: require object-store/bootstrap and attempt semantics absent from sandbox services.
- gVisor/Kata: implement runtime-profile inspection alongside OCI/Kubernetes adapters, not backend work.

## Explicit non-goals

- automatic backend routing by cost/speed/security label;
- a hosted WorkCell sandbox or adapter registry service;
- arbitrary VM management or a Firecracker guest agent;
- cluster installation and fleet scheduling;
- hidden workload retries or repair;
- provider billing estimation;
- full-workspace export or persistent developer-workspace deletion;
- security claims inferred from provider/backend names.

