# Contributing to Workcell

Keep application logic in Kujo modules under `src/`. `main.kujo` should remain a thin entrypoint, `src/cli/cli.kujo` owns output and exit-code translation, and Docker/Git operations must use structured `spawn_process` arguments. Do not add shell interpolation for host-side inputs.

Before submitting changes:

```bash
export KUJO=/path/to/kujo-1.0.0/kujo
test "$(git -C /path/to/kujo-1.0.0 rev-parse HEAD)" = "$(cat RUNTIME_VERSION)"
KUJO="$KUJO" ./tests/version_consistency.sh
./tests/run.sh
./tests/quality.sh
./tests/markdown_links.sh
git diff --check
```

Use temporary Git repositories for integration tests. Do not require Docker for the default offline suite. Update the documentation, compatibility policy, and security review when changing policy, mounts, secrets, lifecycle states, receipt fields, or exit codes. Product, definition, receipt, manifest, report, and other contract versions are independent; do not bump schema identifiers solely because the Workcell product version changes.
