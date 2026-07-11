# Contributing to Workcell

Keep application logic in Kujo modules under `src/`. `main.kujo` should remain a thin entrypoint, `src/cli/cli.kujo` owns output and exit-code translation, and Docker/Git operations must use structured `spawn_process` arguments. Do not add shell interpolation for host-side inputs.

Before submitting changes:

```bash
export KUJO=/path/to/kujo/target/release/kujo
./tests/run.sh
git diff --check
```

Use temporary Git repositories for integration tests. Do not require Docker for the default offline suite. Update the documentation and security review when changing policy, mounts, secrets, lifecycle states, or receipt fields.
