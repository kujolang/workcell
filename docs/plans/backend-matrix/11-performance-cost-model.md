# Performance and cost model

## Current baseline

The research run measured the current WorkCell code before proposing backend phases. Environment: WorkCell `1.0.0` at `0f8a806`, Kujo `1.0.0`, macOS Darwin `25.3.0` x86_64, Docker Engine `29.5.2` through the configured Colima builder.

| Measurement | Result |
| --- | --- |
| `validate` wall time, 3 samples | 622 ms, 616 ms, 582 ms |
| `inspect` wall time, 3 samples | 884 ms, 894 ms, 912 ms |
| `run --dry-run` wall time, 3 samples | 765 ms, 809 ms, 746 ms |
| committed offline workspace performance fixture | 200 changed files in 3,674 ms; batched binary probe enabled |

These are local diagnostic samples, not release claims. The full Docker lifecycle sample could not be refreshed because the pinned Alpine manifest request to Docker Hub timed out during image build. The repository's existing launch evidence records a successful Docker integration/load/self-proof on the same broad host class, but it does not supply phase timings and is not substituted as a new benchmark. The implementation agent must add phase timers before using full lifecycle results as a regression gate.

## Timing model

Every receipt records these non-overlapping intervals where applicable:

```text
T_total
  = T_core_validate
  + T_core_source_package
  + T_adapter_resolve
  + T_provider_queue
  + T_provider_provision
  + T_workspace_upload
  + T_workspace_materialize
  + T_process_start
  + T_workload
  + T_log_recovery
  + T_verification
  + T_artifact_pack
  + T_artifact_download
  + T_core_verify_extract
  + T_cleanup
  + T_core_record
```

Timers include source/authority:

- `workcell-monotonic` for local phases;
- `adapter-monotonic` for adapter process phases;
- `provider-reported` for provider queue/runtime;
- `derived` only when endpoints share a known clock boundary.

Do not subtract timestamps from unrelated clocks. Do not report provider cold start as WorkCell overhead.

## Benchmark workloads

Use a deterministic suite:

1. **No-op:** tiny workspace, `/bin/true`, no artifacts; measures fixed lifecycle.
2. **Stream:** fixed stdout/stderr chunks; measures first-byte, throughput, truncation.
3. **Workspace:** 1 MiB/100 files and 100 MiB/10,000 files packages; measures archive/upload/materialization.
4. **Artifacts:** declared small files, one large file, deep tree near limits; measures pack/download/verify.
5. **CPU/memory:** bounded synthetic workload; confirms limits and workload timing.
6. **Failure:** non-zero, timeout, cancel, disconnect, artifact failure, cleanup retry.

Report p50/p95 only with enough repetitions and state the sample count, region, plan, image cache state, adapter/API versions, and warm/cold classification. Never use provider-published startup numbers as WorkCell measurements.

## Regression budgets

Phase 1 sets budgets from at least 10 local samples on Linux and macOS. Suggested initial review thresholds, not acceptance values:

- definition/resolve overhead should not grow materially for Docker/Podman;
- adapter protocol process startup is measured separately and must not add unbounded per-log-event processes;
- portable package creation scales with file/byte count and fails at configured ceilings;
- memory use stays bounded during upload/download/archive verification;
- cleanup latency has its own timeout and never extends workload timeout invisibly.

Final thresholds must be derived from the implemented baseline and committed as conformance data, not guessed here.

## Cost semantics

WorkCell records cost; it does not route by price, maintain a rate catalog, or predict invoices.

| Backend class | Billing shape to record |
| --- | --- |
| Docker/Podman/local | `local-operator`; monetary cost unknown |
| E2B | provider usage/rate dimensions for running CPU/RAM; plan concurrency/lifetime |
| Vercel Sandbox | active CPU, provisioned memory, creation, egress, image/snapshot storage where reported |
| Daytona | reserved vCPU/RAM/disk by lifecycle state; snapshots/volumes separate |
| Modal | sandbox CPU/memory and storage/egress dimensions; SDK/provider report only |
| Runloop | running compute and suspended/snapshot storage dimensions |
| Cloudflare | composite Containers + Workers + Durable Objects + logs/egress |
| Fly | started VM plus stopped/suspended rootfs, volumes, snapshots, egress |
| Fargate/Cloud Run/ACA | requested task/job dimensions and provider billing window/minimums |

Sources: [E2B pricing](https://e2b.dev/pricing), [Vercel pricing](https://vercel.com/pricing), [Daytona billing](https://www.daytona.io/docs/en/billing/), [Modal pricing](https://modal.com/pricing), [Runloop pricing](https://runloop.ai/pricing), [Cloudflare Sandbox pricing](https://developers.cloudflare.com/sandbox/platform/pricing/), [Fly billing](https://fly.io/docs/about/billing/), [Fargate pricing](https://aws.amazon.com/fargate/pricing/), [Cloud Run pricing](https://cloud.google.com/run/pricing), [Azure Container Apps billing](https://learn.microsoft.com/en-us/azure/container-apps/billing).

## Spend controls

Provider profiles may set operator budgets:

- max provisioned resources and lifetime;
- max concurrent WorkCells per profile;
- max uploaded/downloaded bytes;
- max run-owned persistent storage age;
- optional provider-native spending/quota guard.

These are preflight controls, not a WorkCell billing system. If exact cost cannot be known before execution, a dollar budget cannot be promised. WorkCell fails closed only on limits it can resolve, otherwise labels monetary cost `unknown`. Every orphan inventory highlights cost-accruing states where the provider reports them.

