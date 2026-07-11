# Workcell Runtime Lifecycle

The coordinator records these states in order where applicable:

```text
created → validated → preparing → prepared → starting → running
        → collecting → verifying → exporting → completed
                                      ↘ failed
```

1. **Validate**: load JSON, apply safe defaults, reject unknown fields and unsafe paths/options.
2. **Prepare**: inspect Git, reject dirty sources, create a detached worktree or isolated clone, resolve image by build/reuse/pull.
3. **Launch**: build explicit Docker argv and start the labeled container with the configured timeout.
4. **Collect**: capture stdout/stderr, exit status, timing, changed files, and a Git patch.
5. **Verify**: validate patch/artifact boundaries and record whether execution and verification succeeded separately.
6. **Export**: copy declared artifacts only into the run directory and redact known secret values from logs.
7. **Record**: write the structured receipt, including failure stage and diagnostics.
8. **Clean**: remove the labeled container and temporary worktree. On failure, `--keep-failed` preserves only the temporary workspace.

Timeouts are distinct from ordinary workload failures. The process API attempts termination and returns a timeout result; the receipt records `timeout: true` and the CLI returns exit code `6`. Cleanup is attempted after validation-stage partial setup, image failures, startup failures, workload failures, export failures, and receipt failures.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Workcell completed and cleanup succeeded. |
| 2 | Usage or definition validation failure. |
| 3 | Missing Git/source dependency or preparation failure. |
| 5 | Container startup failure. |
| 6 | Timeout. |
| 7 | Workload command exited non-zero. |
| 8 | Verification or artifact export failure. |
| 9 | Cleanup failure. |
| 10 | Internal Workcell failure. |

The workload's own exit code remains in `receipt.json`; the CLI code identifies the category of failure.
