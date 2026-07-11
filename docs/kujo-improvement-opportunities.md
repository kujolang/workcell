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
