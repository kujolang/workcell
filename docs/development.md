# Workcell Development

## Runtime and tests

Use the current Kujo runtime, not the unrelated Python `kujo` linter:

```bash
export KUJO=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
./tests/run.sh --check-only
./tests/run.sh
```

The offline suite checks every `.kujo` file, runs 51 policy/validation/path/redaction contract assertions, and runs a 7-assertion workspace patch/change-report contract without Docker, plus path-safety, dry-run lifecycle, example-definition, and CLI smoke scripts. Docker integration tests should run in a clean temporary Git repository and are intentionally not part of the default suite when a daemon is unavailable.

CI reads the pinned Kujo commit from `RUNTIME_VERSION`, requires Docker BuildKit/buildx, runs the offline suite, Docker integration suite, and doctor check. Local Docker hosts without buildx use the legacy builder as a compatibility fallback and will emit Docker's deprecation warning.

Build example images when Docker is available:

```bash
docker build --tag kujolang/workcell-base:local docker/
docker/kujo/build-local.sh /path/to/kujo-source
```

## Adding a runtime adapter

Keep the lifecycle contract in `src/execution/coordinator.kujo`. Add an adapter beside `src/runtime/docker.kujo` that provides availability, image/preparation, execution, output, and ownership-scoped cleanup. Preserve the policy fields and receipt distinctions; do not let a backend silently weaken network, mount, resource, or cleanup guarantees.

## Adding a receipt integration

Keep the local receipt writer as the fallback. An adapter to RunLedger should receive the completed Workcell receipt and retain the same run ID, source commit, result status, and evidence paths. Never store secret values or claim a RunLedger write succeeded without checking its command result.

## Debugging

Run `workcell inspect --json` before Docker. On failure, inspect the run directory's receipt, stdout, stderr, changes.patch, failure.txt, and preserved workspace path if `--keep-failed` was used. Run `workcell clean` only after confirming it will target Workcell-owned resources.
