# Backend landscape

This document records architectural fit, not vendor marketing rank. Structured values and explicit unknowns are in `BACKEND_MATRIX.json`.

## Direct remote sandbox services

### E2B

E2B exposes a purpose-built sandbox lifecycle with command execution, filesystem APIs, metadata, kill, and configurable lifetime. Current SDK documentation exposes `allow_internet_access`, defaulting to true, and sandboxes can be killed or have their timeout changed. It is a strong first remote adapter because its resource is close to one WorkCell run and the agent ecosystem already recognizes the category. The integration must use the provider's documented API/SDK contract and must not treat “secure and isolated” as proof of any control not returned by configuration or provider documentation. [E2B Sandbox SDK reference](https://e2b.dev/docs/sdk-reference/python-sdk/v2.3.3/sandbox_sync), [E2B JavaScript SDK reference](https://e2b.dev/docs/sdk-reference/js-sdk/v2.10.5/sandbox).

### Daytona

Daytona exposes container and VM sandbox classes, SDKs/CLI/REST, lifecycle states, files, process execution, snapshots, volumes, regions, resource pools, and strict outbound firewall controls on eligible tiers. `networkBlockAll`, CIDR allowlists, and domain allowlists are first-class, but tier policy can prevent per-sandbox override; WorkCell must negotiate against the actual organization tier. Volumes outlive sandboxes and therefore cannot be run-owned unless WorkCell created and marks them. The OpenAPI surface makes a Kujo HTTP adapter possible, while official SDKs remain useful references. [Daytona API](https://www.daytona.io/docs/en/tools/api/), [network limits](https://www.daytona.io/docs/en/network-limits/), [limits](https://www.daytona.io/docs/limits), [volumes](https://www.daytona.io/docs/en/volumes/).

### Modal

Modal Sandboxes provide create/exec/stream/poll/terminate, images, secrets/environment, CPU and memory request/limit fields, regions, volumes, snapshots, and explicit outbound network blocking/CIDR/domain rules. The documented default lifetime is five minutes and the configurable maximum is 24 hours. A sandbox is a container scheduled on Modal infrastructure; it is not a claim of a dedicated VM per WorkCell. Modal is a useful serverless category proof, but its SDK/API stability and V2 transition must be version-captured. [Modal Sandboxes](https://modal.com/docs/guide/sandboxes), [Sandbox networking](https://modal.com/docs/guide/sandbox-networking), [V2 feature status](https://modal.com/docs/guide/sandbox-v2), [Python SDK](https://modal.com/docs/sdk/py/latest/Sandbox).

### Vercel Sandbox

Vercel documents Firecracker-backed sandbox isolation, command/filesystem SDKs, CLI, snapshots, timeouts, OIDC/access-token auth, network policy, and custom images. Snapshotting stops the active sandbox; persistence and session lifetime have separate semantics. Vercel is a good official phase-two adapter and a strong distribution channel, but “Firecracker” must be recorded as provider-claimed substrate rather than inspected host proof. [Vercel Sandbox](https://vercel.com/docs/sandbox), [snapshots](https://vercel.com/docs/vercel-sandbox/concepts/snapshots), [duration and persistence](https://vercel.com/kb/guide/vercel-sandbox-duration-and-persistence).

### Cloudflare Sandbox

Cloudflare Sandbox is built on Cloudflare Containers and invoked through Workers/Durable Objects. It supports command execution, files, background processes, streaming, custom images, object-storage mounts, and outbound HTTP policy. The package and container image must stay on a compatible release line; the 1.0 SDK was still previewed during research, and Workers subrequest limits affect adapter transport. It belongs as an official adapter after 1.0 stabilizes, not in the first batch. [Sandbox SDK](https://developers.cloudflare.com/sandbox/), [limits](https://developers.cloudflare.com/sandbox/platform/limits/).

### Runloop

Runloop Devboxes are VM-oriented agent environments with create/shutdown/suspend/resume, command execution, separate stdout/stderr streaming, file upload/download, disk snapshots, usage APIs, and network policies. Disk suspend does not snapshot process memory, so it must not be called transparent pause/resume. The API is well suited to a later official adapter, though its shell-string execution surface requires a reviewed argv encoder or a provider-supported direct argv path before conformance. [Devbox overview](https://docs.runloop.ai/docs/devboxes/overview), [commands](https://docs.runloop.ai/docs/devboxes/execute-commands), [files](https://docs.runloop.ai/docs/devboxes/files), [snapshots](https://docs.runloop.ai/docs/devboxes/snapshots).

## Direct local container providers

### Docker and Podman

Docker and Podman are direct providers because they expose the complete resource lifecycle WorkCell already needs: image resolution, create/run/wait, attached streams, inspect, stop/kill, copy/mount, inventory, and removal. Both remain shared-kernel container boundaries. Docker Desktop or Colima may add a shared VM underneath many containers; that does not make each WorkCell a microVM.

CPU, memory, and PID enforcement depend on host cgroups and permissions. Generic disk limits and outbound allowlists are not portable engine capabilities. `network=none` is directly requestable, but the receipt still records the actual engine/substrate and inspection evidence. [Docker resource constraints](https://docs.docker.com/engine/containers/resource_constraints/), [Docker none network](https://docs.docker.com/engine/network/drivers/none/), [Docker security](https://docs.docker.com/engine/security/), [Podman run](https://docs.podman.io/en/latest/markdown/podman-run.1.html).

## Lower runtime and isolation layers

### gVisor and Kata Containers

gVisor `runsc` and Kata Containers implement OCI/CRI integration below Docker/containerd/Kubernetes. They do not provision a WorkCell resource, transfer a workspace, collect declared artifacts, or own cleanup. The adapter remains Docker, Podman, containerd, or Kubernetes; the receipt records `runtime=runsc` or `runtime=kata` plus observed configuration. gVisor is a userspace application kernel with compatibility tradeoffs. Kata places workloads in lightweight VMs but explicitly leaves network, storage, and control-plane multi-tenancy to the operator. [gVisor architecture](https://gvisor.dev/docs/architecture_guide/intro/), [gVisor security](https://gvisor.dev/docs/architecture_guide/security/), [Kata architecture](https://github.com/kata-containers/kata-containers/blob/main/docs/index.md).

### Firecracker

Firecracker provides a KVM microVM VMM, REST control socket, vCPU/memory configuration, block/network devices, pause/resume, snapshots, and a jailer. It does not provide guest command execution, a workspace protocol, logs, declared artifacts, auth, billing, or run inventory. A direct adapter would require building and maintaining a guest agent, kernel/rootfs pipeline, TAP/network enforcement, cgroups/jailer policy, snapshot custody, and recovery service. That is a new VM provider and is an explicit non-goal. Use Firecracker through a provider such as Vercel or a separately governed future service. [Firecracker design](https://github.com/firecracker-microvm/firecracker/blob/main/docs/design.md), [snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md), [production host setup](https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md).

### containerd, Lima, Colima, Apple Virtualization.framework

containerd is designed to be embedded and manages images, snapshots, execution, shims, and garbage collection. It could support a later local adapter but adds gRPC, lease, CNI, FIFO, and daemon lifecycle complexity without proving a new first-batch category. Lima/Colima and Apple Virtualization.framework are host substrates. WorkCell should use Docker/Podman exposed by Lima/Colima and record substrate facts; it should not create provider IDs for them. [containerd](https://github.com/containerd/containerd/blob/main/README.md), [Lima](https://github.com/lima-vm/lima), [Colima](https://github.com/abiosoft/colima/blob/main/README.md), [Apple Virtualization](https://developer.apple.com/documentation/virtualization).

## Higher schedulers and managed jobs

Kubernetes Jobs, Nomad batch jobs, AWS ECS/Fargate, Google Cloud Run Jobs, and Azure Container Apps Jobs can eventually satisfy a WorkCell adapter, but their native abstraction is scheduled job/task execution, not a sandbox filesystem API. They introduce retries/replacement attempts, external log retention, object-store transfer, cluster network policy, IAM, and scheduler garbage collection. An adapter must force one attempt and zero retries where possible; otherwise every attempt needs its own evidence identity.

- Kubernetes requires one Job/Pod, `restartPolicy: Never`, `backoffLimit: 0`, explicit deadline, unique labels, runtime-class capture, and an owned artifact-transfer protocol. [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/).
- Fargate tasks cannot use the Docker-style `disableNetworking`; `network:none` requires verified operator VPC controls. [Fargate security](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-security-considerations.html), [Fargate pricing](https://aws.amazon.com/fargate/pricing/).
- Cloud Run Jobs default to public outbound access and need owned VPC/firewall policy for a strict egress denial. [Cloud Run Jobs](https://cloud.google.com/run/docs/create-jobs), [pricing](https://cloud.google.com/run/pricing).
- Azure Container Apps Jobs expose manual start/stop and execution history, but PID/disk/network-none enforcement remained unverified in reviewed first-party contracts. [Container Apps Jobs](https://learn.microsoft.com/en-us/azure/container-apps/jobs), [billing](https://learn.microsoft.com/en-us/azure/container-apps/billing).
- Nomad can stream allocation logs and metrics, but logs are documented as best-effort and task-driver/retry behavior is deployment-specific. [Nomad jobs](https://developer.hashicorp.com/nomad/docs/concepts/job), [logs](https://developer.hashicorp.com/nomad/docs/job-run/logs).

These are later official or operator adapters, not core dependencies.

## Hosted development environments

GitHub Codespaces, Gitpod, and Coder own persistent developer workspaces and user lifecycle. Deleting one during WorkCell cleanup could destroy user-owned state. They should host WorkCell or publish templates that install it. A community adapter is acceptable only if it creates a disposable resource under exclusive run ownership and proves that deletion cannot touch a user workspace. [Codespaces lifecycle](https://docs.github.com/en/codespaces/about-codespaces/understanding-the-codespace-lifecycle), [Gitpod docs](https://www.gitpod.io/docs), [Coder workspace lifecycle](https://coder.com/docs/user-guides/workspace-lifecycle).

## Alternate workload ABI

Wasmtime/WASI offers valuable capability-based filesystem imports and interruption, but it cannot execute the same arbitrary Linux image/argv workload. Supporting it under the existing backend contract would break the core portability promise. Revisit only with a separate versioned `workload.kind = wasm-component` definition and conformance suite. [Wasmtime security](https://docs.wasmtime.dev/security.html), [interrupting WebAssembly](https://docs.wasmtime.dev/examples-interrupting-wasm.html).

## Additional candidate: Kubernetes Agent Sandbox

Kubernetes SIG Apps Agent Sandbox is more appropriate than raw Kubernetes Jobs for a later operator adapter. Its CRDs model singleton sandboxes, claims, templates, warm pools, hibernation, stable identity, and runtime choice including gVisor and Kata. It remains a Kubernetes control plane with cluster/operator policy, so WorkCell must not ship or require it in core. [Agent Sandbox documentation](https://agent-sandbox.sigs.k8s.io/docs/), [threat model](https://github.com/kubernetes-sigs/agent-sandbox/blob/main/docs/security/threat_model.md).

## Research stop condition

The research stopped when each consequential inclusion decision had first-party support and additional searches were repeating capability lists without changing the taxonomy. Remaining unknowns are deliberate: generic Docker/Podman disk enforcement, exact cross-stream ordering for most services, several provider PID limits, live retention behavior, and marketplace publication paths. They are conformance/live-smoke questions, not gaps to fill by inference.

