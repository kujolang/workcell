# Kujo Improvement Opportunities

## Process working directory

- Problem: `spawn_process` does not expose a working-directory option.
- Impact: Workcell must use `git -C` and Docker `--workdir`, and any future host process adapter needs path-aware argv conventions.
- Workaround: structured `git -C`; no shell interpolation.
- Suggested capability: `cwd` in process options.
- Priority: medium.
- Blocks Workcell: no.

## Process lifecycle and signals

- Problem: the current script surface exposes bounded process execution but not a portable explicit signal/escalation API to Kujo code.
- Impact: timeout cleanup relies on the runtime's process timeout behavior and Docker removal after return.
- Workaround: `timeout_ms`, then labeled `docker rm -f`.
- Suggested capability: typed cancellation/termination and completion metadata.
- Priority: high for hardened runtimes.
- Blocks Workcell: no for the Docker MVP.

## Structured filesystem copy

- Problem: recursive artifact copying is not a single Kujo-native filesystem primitive.
- Impact: the MVP uses a structured `cp -R` subprocess behind the Kujo exporter.
- Workaround: validated destination containment plus argv-safe `cp`.
- Suggested capability: recursive copy with symlink policy and containment checks.
- Priority: medium.
- Blocks Workcell: no.

## Schema validation helpers

- Problem: declarative JSON schemas are validated manually in Kujo modules.
- Impact: more local code and future schema-version maintenance.
- Workaround: explicit allowed-field/type/path validation.
- Suggested capability: reusable typed/declarative schema validation.
- Priority: medium.
- Blocks Workcell: no.

## Secret-safe process output

- Problem: exact-value log redaction cannot detect transformed secrets.
- Impact: callers must avoid writing secrets to artifacts and review outputs.
- Workaround: runtime-only env injection and exact-value redaction.
- Suggested capability: provider-aware secret handles and streaming redaction hooks.
- Priority: high for hosted execution.
- Blocks Workcell: no.

## Formatter semantic safety

- Problem: `kujo format --check` reports several valid Workcell modules as needing formatting, but `kujo format --write` rewrites program semantics instead of only layout. Observed transformations included `--` to spaced tokens, `/` inside string literals to `" / "`, and `>=` to `> =`.
- Observed impact: the formatter cannot currently be used as a trustworthy repository gate; its write mode must not be run on Workcell source. The rewritten files were restored and all source behavior was reverified with `kujo check` and the full test suite.
- Current workaround: preserve manually reviewed source formatting, run `kujo check`, `kujo lint`, and `git diff --check`; do not use formatter write mode until the formatter is fixed.
- Suggested Kujo capability: formatter round-trip tests covering operators, CLI flags, path literals, arrays, dictionaries, imports, and string contents; require parse/AST equivalence before accepting formatted output.
- Priority: high for production Kujo repositories.
- Blocks Workcell: no; it blocks a reliable formatting gate, not the Workcell runtime.

## Linter control-flow analysis

- Problem: `kujo lint` exits successfully but emits widespread `unreachable-code` warnings on valid imported/exported module code, plus one `missing-error-handling-pattern` warning in the guarded `read_text` path.
- Observed impact: Workcell lint output is noisy and does not distinguish actionable warnings from analyzer false positives.
- Current workaround: retain the warnings as audit evidence, use `kujo check` and runtime contracts as correctness gates, and review the one fallible filesystem call separately.
- Suggested Kujo capability: module-aware reachability analysis and severity controls for warnings, with a machine-readable baseline mechanism.
- Priority: medium.
- Blocks Workcell: no.
