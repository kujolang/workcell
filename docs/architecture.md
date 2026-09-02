# Workcell Architecture

## Position in the Kujo execution hierarchy

```text
Agent or orchestrator
        |
        v
Kujo trust and policy controls
        |
        v
Workcell execution request
        |
        v
Docker-backed disposable environment
        |
        v
Patch, artifacts, receipt, verification
```

Workcell supplies a physical boundary and a durable evidence boundary. Kujo trust profiles, approvals, and script controls remain the authorization layer above it.

## Modules

- `src/domain/definition.kujo`: JSON loading, defaults, schema/semantic validation, duration normalization.
- `src/policy/policy.kujo`: explicit backend-neutral OCI security arguments and runtime environment policy.
- `src/runtime/docker.kujo`: OCI runtime availability, image build/pull/inspect, run, output collection, and ownership-scoped cleanup for Docker or Podman.
- `src/integrations/integrations.kujo`: opt-in RunLedger, ChangeBucket, ShipCheck, Fence, PackWrite, and Muzzle evidence adapters with bounded execution and redacted reports.
- `src/workspace/workspace.kujo`: Git repository inspection, clean-source enforcement, worktree/clone creation, patch and change collection, safe cleanup.
- `src/verification/verification.kujo`: versioned post-run checks in separate labeled containers using the same runtime policy.
- `src/execution/coordinator.kujo`: stateful `validate → prepare → launch → execute → collect → verify → export → record → clean` lifecycle.
- `src/artifacts/exporter.kujo`: declared artifact copying and secret-redacted logs.
- `src/receipts/receipt.kujo`: structured run receipt shape and finalization.
- `src/doctor/doctor.kujo`: actionable local diagnostics.
- `src/cli/cli.kujo`: argument parsing, human/machine output, and stable exit-code mapping.

The runtime adapter is intentionally narrow. Docker is the default and Podman is the compatible OCI implementation; lifecycle and policy code do not depend on engine-specific cleanup details beyond the adapter boundary.

The additive portable path keeps that boundary and introduces an executable adapter protocol rather than provider branches in core:

```text
definition v2 + host profile
  → semantic requirements
  → strict capability resolution
  → backend protocol
      → E2B | Vercel Sandbox | Daytona | third party
  → receipt v2 + recovery journal + integrity manifest
```

`src/backend/types.kujo` and `src/backend/client.kujo` define the small machine contract. `src/execution/portable_coordinator.kujo` owns lifecycle order and failure precedence. `src/workspace/package.kujo` and `src/artifacts/archive.kujo` keep transfer policy in core. Provider SDK dependencies live under `adapters/official`, outside the Kujo core path. Lower layers such as gVisor/Kata remain substrate evidence; raw Firecracker is not an adapter because it lacks command, workspace, evidence, and cleanup services.

## Workspace and artifact flow

Workcell resolves a clean source repository and current commit, creates a detached Git worktree (or isolated clone), and mounts only that temporary path read-write at `/workspace`. The source repository is never mounted as the writable execution directory. After execution, Git diff and changed-file metadata are collected, declared artifacts are copied into the run-owned output directory, and the temporary workspace is removed unless failed-workspace preservation was requested.

## Receipts

The receipt records source commit, definition hash, image/digest, command, timestamps, timeout, resource policy, secret names, mounts, changed files, patch, logs, artifact paths, cleanup, errors, and a verification block. The verification block distinguishes execution success, verification success, artifact export, and cleanup.

## Integration boundaries

RunLedger is the ecosystem reference for run receipts, ChangeBucket for bounded change-footprint reports, ShipCheck for release readiness, Fence for architecture boundaries, CaseFile for failure evidence, PackWrite for context packaging, and Muzzle for quiet workflows. Workcell currently keeps local adapters and reports rather than importing sibling repositories as unstable package dependencies.
