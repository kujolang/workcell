# Distribution and competitive analysis

## Distribution thesis

An adapter is distribution-worthy when provider users can discover WorkCell as the evidence/policy layer they are missing, not merely as another SDK wrapper. The message is:

> Run the same bounded, declared workload through your sandbox provider and receive portable artifacts, policy resolution, cleanup evidence, and offline verification.

## Provider opportunities

| Adapter | Verified paths | Why users discover Kujo | Speculative/unverified paths |
| --- | --- | --- | --- |
| E2B | official OpenAI Agents SDK integration, E2B cookbook/community, Docker MCP partnership | agent builders already need repeatable sandbox execution; WorkCell adds provider-neutral evidence and cleanup | formal third-party marketplace listing |
| Vercel Sandbox | Vercel Marketplace/partner APIs and integration submission, Vercel developer ecosystem | Vercel agents can gain portable WorkCell contracts and move off-provider without workload rewrite | Marketplace approval and co-marketing; requires separate hosted integration/support product |
| Daytona | official Agent Skills and Claude plugin marketplace instructions, open-source repo/community, self-hosted users | enterprise/self-hosted sandbox users value policy/evidence portability | general Daytona adapter marketplace |
| Modal | official examples/docs/community; AWS and GCP marketplace purchasing is verified for Modal itself | serverless/ML teams get bounded agent-workload evidence without adopting orchestration | a Modal integration catalog entry for WorkCell |
| Runloop | agent-builder docs/SDK/community | Devbox users gain declared artifacts, offline verification, and cross-provider workload definitions | external marketplace not verified |
| Cloudflare | Workers/Sandbox docs, Cloudflare developer community, npm ecosystem | Workers developers get a portable execution contract above their deployed Worker/DO/Container bridge | listing as a direct Cloudflare sandbox provider; current architecture is operator-deployed |
| Kubernetes Agent Sandbox | Kubernetes SIG Apps/CNCF channels, runtime templates, Go/Python clients | platform teams get WorkCell evidence above a standardized sandbox CRD | a provider marketplace |
| Docker/Podman | container ecosystem, GitHub examples, package channels | local-first developers get the existing WorkCell golden path | vendor marketplace promotion |
| gVisor/Kata | official Docker/containerd/Kubernetes integration guides, RuntimeClass/Helm | security-conscious operators can inspect stronger substrate profiles while keeping WorkCell contract | separate adapter listing; they are not providers |
| Coder/Codespaces/Gitpod | templates/devcontainers/Coder Registry/Open in Coder | development workspaces can ship WorkCell as an inner bounded runner | treating user workspaces as disposable backends |

E2B is the strongest immediate distribution opportunity because verified agent ecosystem integrations align directly with WorkCell's target user and do not require WorkCell to operate a hosted marketplace service. Vercel has broader developer reach and a formal Marketplace, but publication there is a separate product/support obligation rather than a consequence of shipping an adapter. Sources: [E2B Agents SDK announcement](https://e2b.dev/blog/e2b-is-now-in-agents-sdk), [E2B/Docker MCP partnership](https://e2b.dev/blog/docker-e2b-partner-to-introduce-mcp-support-in-e2b-sandbox), [Vercel partner API](https://vercel.com/docs/integrations/create-integration/marketplace-api/reference/partner), [Daytona Agent Skills](https://www.daytona.io/docs/en/agent-skills/).

## Launch assets per official adapter

- a minimal `same-workcell-different-backend` example;
- provider profile schema and credential setup using Kujo Agent auth conventions;
- offline fixture walkthrough and conformance badge tied to adapter release;
- live smoke receipt with requested/resolved/enforced/observed controls;
- provider-specific security limitations page;
- cost/orphan cleanup walkthrough;
- tutorial integrating Kujo Agent without provider API exposure;
- upstream/provider community announcement only after exact release evidence passes.

Do not claim partner status, marketplace availability, certified security, or provider endorsement without verified acceptance.

## Competitive landscape

### Sandbox API abstraction libraries

[`@sandbox-sdk/core`](https://sandbox-sdk.sh/) already offers a small TypeScript API for files, processes, ports, snapshots, and provider escape hatches across multiple sandboxes. WorkCell should not recreate that generic application SDK. Its differentiation is strict workload definition, clean-source transfer, fail-closed capability negotiation, declared-only export, normalized evidence, offline verification, and recovery ownership.

### Kubernetes Agent Sandbox

[Kubernetes Agent Sandbox](https://agent-sandbox.sigs.k8s.io/docs/) standardizes stateful singleton sandbox resources, templates, claims, warm pools, and isolation runtime choice on Kubernetes. WorkCell should integrate as a workload/evidence client, not compete as a Kubernetes controller.

### Agent runtimes with multiple sandbox providers

OpenHands and the OpenAI Agents SDK examples expose multiple third-party sandbox runtimes; a Temporal community sandbox harness demonstrates start/stop/suspend/snapshot provider interfaces. These systems validate demand for provider portability but operate at agent runtime/orchestration layers. WorkCell should supply a stable execution/evidence contract they can call. [OpenAI Agents sandbox extensions](https://github.com/openai/openai-agents-python/blob/main/examples/sandbox/extensions/README.md), [Temporal sandbox harness](https://github.com/temporal-community/sandbox-orchestration-harness).

### CI and job abstractions

Kubernetes Jobs, Nomad, and managed cloud job APIs solve scheduling, retries, and fleet execution. WorkCell does not compete. A later adapter constrains one attempt and normalizes evidence.

### Provider-native SDKs

Provider SDKs remain authoritative for provider features. Official adapters may reuse them, but WorkCell's public contract is smaller and semantic. Provider escape hatches stay in operator profiles and cannot redefine workload policy.

## Positioning

Do not market WorkCell as “one SDK for every sandbox.” Position it as:

- a portable workload and policy contract;
- an evidence and verification boundary;
- a safe declared artifact boundary;
- ownership-aware cleanup and recovery;
- an agent/orchestrator-neutral execution primitive;
- local-first with no mandatory control plane.

This focus avoids rebuilding cloud SDKs while making provider integrations independently valuable.

