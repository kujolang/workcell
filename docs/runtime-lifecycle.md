# Workcell Runtime Lifecycle

The coordinator records these states in order where applicable:

```text
created → validated → preparing → prepared → starting → running
        → collecting → verifying → exporting → completed
                                      ↘ failed
```

1. **Validate**: load JSON, apply safe defaults, reject unknown fields, unsafe paths/options, symlinks, and unbounded resource values.
2. **Prepare**: inspect Git, reject dirty sources, create a detached worktree or isolated clone, canonicalize the existing host workspace path before bind mounting (including macOS `/private` aliases), and resolve the selected Docker/Podman image by build, reuse, or pull.
3. **Launch**: build explicit backend argv and start the labeled container with the configured timeout and bounded output capture.
4. **Collect**: capture stdout/stderr, exit status, timing, changed files, and a Git patch.
5. **Verify**: reject post-run workspace symlinks, run the versioned declarative checks in separate labeled containers when the workload succeeds, validate patch/artifact boundaries, and record execution versus verification separately.
6. **Export**: stream bounded stdout/stderr to redacted run logs while the container runs, then copy declared artifacts only into the run directory and apply the same secret policy to persisted evidence. Declared secret values are always redacted from `changes.patch` before it is written, independently of `artifacts.secret_action`; that field only escalates a patch that held a secret to a failed run when it is set to `reject`.
7. **Record**: write the structured receipt, including failure stage, diagnostics, and a versioned integrity manifest that can be verified offline with `workcell verify`.
8. **Clean**: remove the labeled container and ownership-marked temporary worktree. On failure, `--keep-failed` preserves only the explicitly owned temporary workspace.

Timeouts are distinct from ordinary workload failures. The process API returns a timeout result; Workcell retrieves available container logs, attempts the selected backend's graceful stop, then escalates to label-scoped forced removal. The receipt records `timeout: true` and the CLI returns exit code `6`. Cleanup is attempted after validation-stage partial setup, image failures, startup failures, workload failures, export failures, and receipt failures.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Workcell completed and cleanup succeeded. |
| 2 | Usage or definition validation failure. |
| 3 | Missing Git/source dependency or workspace preparation failure. |
| 4 | Backend/image preparation failure. |
| 5 | Container startup failure. |
| 6 | Timeout. |
| 7 | Workload command exited non-zero. |
| 8 | Verification or artifact export failure. |
| 9 | Cleanup failure. |
| 10 | Internal Workcell failure. |

The workload's own exit code remains in `receipt.json`; the CLI code identifies the category of failure. A Docker/Podman startup error is distinct from a workload command failure.

## Portable v2 lifecycle

Remote execution uses `resolve → provision → prepare → execute → collect → export → destroy → record`. Resolve must accept every required semantic control before provision. Workcell persists an ownership-bound provision intent before calling the provider, then atomically attaches the returned handle before any workspace upload. A lost provision response therefore remains inventory-recoverable instead of being recorded as “not provisioned.” Prepare verifies the observed workspace package digest. Execute and declarative verification produce normalized terminal results; a nonzero workload exit is a result, not an adapter transport failure. Collect may report incomplete deltas or unknown metrics but cannot invent evidence. Export returns only declared paths, which core revalidates and re-hashes. Destroy must return itemized cleanup and zero remaining run-owned resources for a clean success.

Cancel and inventory are mandatory protocol operations used by control and recovery paths. `--cancel-file` gives local callers and agent hosts a deterministic cancellation hook for both v1 containers and portable execute operations. Portable cancellation terminates the adapter process, records a cancelled result, and destroys the owned remote resource from its durable handle; it does not claim that a provider performed graceful process cancellation. Pause, resume, snapshot, and metrics remain optional capabilities and do not alter the canonical success lifecycle. Workcell does not retry workloads; Dispatch or Relay may start a new correlated Workcell attempt under their own policy.

Portable Docker and Podman use the same stable OCI lifecycle implementation as v1 rather than an external subprocess adapter. This keeps engine launch, streaming, artifact export, verification, and cleanup behavior identical while the coordinator presents the backend-neutral receipt v2 contract.
