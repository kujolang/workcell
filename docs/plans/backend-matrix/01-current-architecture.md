# Current WorkCell architecture

## Baseline

The audited baseline is WorkCell `1.0.0` at commit `0f8a806`, pinned to Kujo `1.0.0` commit `2b3e07d398016e92008d8399e79c441e012dce38`. The supported product boundary is local and CI execution through Docker or Podman. It is not a hosted sandbox service and does not claim protection from a compromised engine or host kernel.

## Current component map

```text
main.kujo / src/cli/cli.kujo
  |
  v
src/execution/coordinator.kujo
  |-- definition: src/domain/definition.kujo
  |-- workspace:  src/workspace/workspace.kujo
  |-- policy:     src/policy/policy.kujo
  |-- runtime:    src/runtime/docker.kujo
  |-- verify:     src/verification/verification.kujo
  |-- artifacts:  src/artifacts/exporter.kujo
  |-- evidence:   src/receipts/{receipt,manifest}.kujo
  |-- optional:   src/integrations/integrations.kujo
  `-- utilities:  src/util.kujo
```

The documented “runtime adapter” is narrower than the file name suggests, but the boundary is incomplete. `src/runtime/docker.kujo` owns engine calls, image preparation, execution, logs, and container cleanup. `src/policy/policy.kujo` still emits Docker/Podman CLI argv. Definition validation hard-codes the two backend names and OCI-shaped fields. Verification imports container functions directly. The coordinator names containers and image fields directly. Provider portability therefore requires extraction across four modules, not only renaming `docker.kujo`.

## Ownership map

| Concern | Current owner | Classification | Target ownership |
| --- | --- | --- | --- |
| Definition parsing, defaults, unknown-field rejection | `domain/definition.kujo` | backend-agnostic plus OCI schema | WorkCell core |
| Repository validation and clean-source rule | `workspace/workspace.kujo` | host/Git-specific | WorkCell core |
| Worktree and isolated clone creation | `workspace/workspace.kujo` | host-specific | WorkCell core; add portable package strategy |
| Runtime selection | definition plus `runtime_program()` | Docker/Podman-specific | host selection + registry |
| Image pull/build/inspect/signature | `runtime/docker.kujo` | OCI-specific | OCI shared driver; adapters resolve image semantics |
| Security argument construction | `policy/policy.kujo` | container-backend-specific | core semantic intent + adapter resolution |
| CPU, memory, PID limits | definition + Docker argv | policy-specific and OCI-specific | core request; adapter resolves and proves |
| Timeout/output bound | Kujo process options | host-specific enforcement | core mandatory bound; adapter timeout plus host watchdog |
| Filesystem/mount mapping | policy argv | OCI-specific | core workspace intent; adapter transport/mount resolution |
| Environment allowlist | definition/policy | core policy plus OCI encoding | WorkCell core; adapter transports names/values safely |
| Secrets | environment lookup, redaction, Docker `--env NAME` | core policy plus OCI transport | core credentials/redaction; adapter secret channel capability |
| Network selection | policy argv and declaration | OCI-specific implementation | core network intent; adapter resolves evidence |
| Output streaming | Kujo process API around engine CLI | host/container-specific | core normalized event sink; adapter supplies quality metadata |
| Cancellation | process cancellation marker and container stop/remove | host/container-specific | core cancellation state; adapter graceful cancel or destroy fallback |
| Exit classification | coordinator/CLI | evidence-specific | WorkCell core |
| Changed files and patch | host Git after execution | host/workspace-specific | core; remote package returns bounded workspace delta |
| Verification commands | separate labeled containers | container-specific runner, core semantics | WorkCell core invoking adapter `execute` in same workspace |
| Artifact declaration and policy | exporter | evidence/policy-specific | WorkCell core |
| Artifact copy | host `cp -R` from bind mount | host-specific | adapter export transport + core safe validation |
| Receipt and manifest | receipts modules | evidence-specific | WorkCell core |
| Container cleanup | runtime module | Docker/Podman-specific | adapter `destroy` |
| Workspace cleanup and stale recovery | workspace module | host-specific | core inventory/recovery plus adapter inventory |
| Ecosystem integration reports | integrations module | core post-receipt integration | remain optional and outside primary verdict |

## Current lifecycle and guarantees

The coordinator performs:

```text
load/validate
  -> inspect clean Git source
  -> create run output and disposable workspace
  -> construct OCI policy
  -> write initial receipt
  -> ensure and verify image
  -> run container with bounded/redacted streams
  -> collect logs, Git delta, patch
  -> execute declarative verification containers
  -> export declared artifacts
  -> stop/remove container and clean/preserve workspace
  -> finalize receipt, integrations, integrity manifest
```

Stable guarantees that must survive extraction:

- clean source is required and the source checkout is not the writable execution workspace;
- resource fields are bounded at definition validation;
- the default network is `none`;
- host effects use structured argv;
- the engine receives non-root/rootless identity, read-only root, private IPC, dropped capabilities, no-new-privileges, bounded resources, one workspace mount, and explicit environment;
- digest, registry, and optional cosign checks fail closed;
- stream output, patches, verification output, and receipts redact declared secret values and common base64 encodings;
- post-run symlinks and traversal are rejected;
- only declared artifacts cross the export boundary, with byte/file/depth/extension/secret policy;
- failure category is separate from workload exit code;
- cleanup targets only labeled containers and ownership-marked workspaces;
- the manifest hashes immutable evidence and can be verified offline.

## Backend-specific code inventory

### Backend-agnostic and should remain explicit

- JSON strictness, safe defaults, path validation, time/output maxima.
- clean Git source, run IDs, output ownership, failure-preservation policy.
- command argv contract, environment-name validation, secret-name handling.
- artifact declarations/limits, patch policy, receipt construction, SHA-256 manifest.
- lifecycle and exit-category decisions.
- optional integrations remaining after the primary receipt boundary.

### Container-backend-specific and worth abstracting

- OCI image resolution and provenance inspection.
- bind-mounted workspace and `--workdir`.
- `--read-only`, tmpfs, identity, capabilities, seccomp/AppArmor, IPC, cgroup flags.
- container name/label encoding.
- `run`, `inspect`, `logs`, `stop`, `rm`, `ps`, and image inventory.
- startup-error interpretation such as Docker exit `125`.

### Docker-specific

- Docker security-options parsing.
- Buildx detection and fallback to `docker build`.
- Docker Desktop/Colima host behavior and image metadata shapes.
- Docker error text used for missing-container idempotency.

### Podman-specific

- `.Host.Security` parsing, seccomp/rootless/AppArmor interpretation.
- rootless identity compatibility rules and Podman error variants.
- Podman build/image ID normalization.

### Host-specific

- Git commands, local temp-root/file-sharing semantics, UID/GID/chown, symlink inspection.
- Kujo process timeout/cancellation/output capture.
- `cp`, local filesystem hashing, atomic writes, local recovery markers.

### Policy/evidence-specific and must not move into adapters

- whether a requested control is required;
- whether an execution may proceed after negotiation;
- declaration of artifacts and secret treatment;
- normalized status and failure classification;
- wording and authority of security claims;
- receipt and manifest schemas;
- cleanup ownership rules.

## Duplicate and intentionally explicit behavior

Docker and Podman currently share nearly all runtime argv and lifecycle code. The small engine branches are real compatibility differences and should remain visible in shared OCI helpers, not be erased through stringly generic code. Conversely, `policy.build_policy()` returning `docker_args`, verification importing `run_container()`, and the coordinator directly handling `container_name` are portability leaks and should move behind semantic adapter results.

Do not abstract `workspace`, `artifacts`, or `receipts` into provider callbacks merely to reduce code. Providers transport bytes and report facts; WorkCell decides which bytes are valid evidence.

## Existing recovery behavior

`workcell clean` inventories engine resources by WorkCell labels and reconciles temporary workspaces by ownership markers and active run IDs. Container removal is idempotent for “not found.” Cleanup occurs after image, startup, workload, verification, export, receipt, timeout, and cancellation failures. This becomes the minimum remote recovery contract: an adapter must expose run-owned inventory and idempotent destruction. A provider list API without unforgeable/verified ownership metadata is insufficient.

## Baseline test architecture

The offline suite already provides a useful extraction seam:

- fake `docker`/`podman` executables for startup, unavailable runtime, cleanup, lifecycle, and verification failures;
- policy and schema tests for unsafe definitions and exact receipt identifiers;
- workspace/path/symlink/adversarial tests;
- performance and stress tests that avoid live cloud providers;
- gated Docker/Podman integration, concurrent load, egress, doctor, self-proof, and cleanup.

The first implementation phase should preserve these tests byte-for-byte where they assert public behavior, then re-express engine fakes as backend-protocol fixtures without weakening the existing OCI gates.

