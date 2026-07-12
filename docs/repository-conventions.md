# Kujo Repository Conventions Reviewed for Workcell

Workcell was designed after a read-only audit of the sibling Kujo ecosystem repositories in `/Users/robertdevore/2026/Kujolang/kujo-repos`. The audit covered the language runtime, CLI-oriented tools, and the policy/evidence tools most relevant to a sandbox runner.

## Repositories reviewed

- `kujo`: current language syntax, VM execution, process APIs, capability flags, filesystem primitives, JSON support, and CLI contracts.
- `packwrite`: modular Kujo CLI layout, envelope-style module results, validation boundaries, launcher conventions, and offline tests.
- `runledger`: receipt-oriented record shape, local JSON persistence, read-only Git metadata, and run status conventions.
- `changebucket`: read-only Git diff analysis, bounded change reports, CLI argument parsing, and risk-oriented reporting.
- `shipcheck`: release-readiness checks, documentation expectations, and gate semantics.
- `fence`: architecture-boundary checks, safe path/output handling, deterministic reports, and explicit exit-code taxonomy.
- `casefile`: failure evidence bundles, redaction defaults, path-safe local artifacts, and diagnostic handoff conventions.
- `muzzle`: quiet workflow execution, dry-run behavior, timeout flags, local report paths, and compact machine-readable summaries.
- `agents-sdk`: agent execution result contracts, approvals, artifacts, no-network harnesses, and deterministic offline testing patterns.
- `dispatch`: workflow lifecycle/state modeling, policy profiles, run artifacts, and explicit cleanup/diagnostic operations.

## Conventions Workcell follows

### Repository and source layout

Workcell is a standalone sibling repository named `workcell`, with a thin `main.kujo` entrypoint, a `src/` module tree, hand-rolled Kujo tests under `tests/`, runnable examples under `examples/`, container assets under `docker/`, and user/contributor documentation under `docs/`. The application is substantive Kujo code; Bash is used only for a thin launcher and test orchestration. External integration commands are opt-in and must use explicit argv, bounded time/output, and redacted evidence files.

### Entry point and CLI

`main.kujo` imports one dispatcher, passes `args()`, and calls `exit(code)`. Only `src/cli/cli.kujo` prints user-facing output and selects stable exit codes. Flags are parsed into positionals and a dictionary, with explicit validation for unknown options and missing values. `--json` emits one structured object.

### Module responsibilities

The module tree keeps configuration parsing, domain validation, policy construction, runtime adapters, workspace handling, execution coordination, artifact export, receipts, diagnostics, and presentation separate. The Docker adapter is behind a runtime boundary so additional OCI-compatible backends can be added without moving lifecycle policy into the CLI.

### Errors and results

Internal modules return dictionaries with `ok` plus structured fields or an `error` string. The CLI translates those results into concise human output and stable exit codes. Failure results retain the lifecycle stage, attempted operation, cleanup status, diagnostics path, and next action.

### Filesystem and process safety

Workcell uses Kujo's structured `spawn_process` API for host-side Docker/Git operations, never interpolating untrusted values into shell strings. Paths are normalized with textual containment checks and reject traversal, absolute artifact paths, sensitive mounts, symlink escapes, and direct source-repository writes. Workcell-created resources carry deterministic labels and a run ID.

### Configuration and serialization

The Workcell definition is JSON because it is declarative, deterministic, directly supported by the current Kujo runtime, and does not require executing untrusted configuration code. `version: 1` is validated explicitly. Receipts, change reports, and inspection output are JSON-compatible dictionaries serialized through Kujo's JSON builtins.

### Testing

Tests use the ecosystem's hand-rolled Kujo harness style. Docker-independent tests cover parsing, validation, path safety, policy arguments, redaction, command construction, receipt shape, and lifecycle result handling. Docker integration tests are opt-in and skip cleanly when Docker is unavailable. Shell is limited to the launcher and test runner, not application logic.

### Documentation and operational evidence

The README is the onboarding surface. Architecture, security, definition format, lifecycle, development, roadmap, ADRs, build/tooling/security reports, known limitations, and Kujo improvement opportunities are maintained in `docs/`. Generated `.workcell/` output is ignored. RunLedger, ChangeBucket, ShipCheck, Fence, and CaseFile are used as external ecosystem validation/evidence tools where their current interfaces fit.

## Important runtime findings

- The current Kujo runtime provides `spawn_process(argv, options)` with structured arguments, an optional working directory, timeout, output limits, environment allow/deny controls, explicit environment injection, bounded stream channels/file sinks, incremental redaction, and cancellation metadata.
- The process API does not currently expose a working-directory option, so Workcell uses `git -C <path>` for Git and Docker's explicit `-w /workspace` for container commands.
- The current runtime provides `sha256_file`, JSON parsing/serialization, file/directory APIs, path helpers, and environment reads.
- The repository conventions favor `while` loops in check-clean code where the current Kujo checker has stricter loop-scope rules.
- RunLedger and ChangeBucket remain standalone local tools rather than importable package dependencies, so Workcell uses focused adapters and documents the integration boundary instead of duplicating their repositories.

## Naming and release metadata

The package and CLI are named `workcell`, the product is presented as Workcell, the initial version is `0.1.0`, and the license is MIT, matching the dominant sibling CLI conventions.
