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

- Resolved: Kujo commits `ff31153` and `7ef6eb8` protect strings/comments and multi-character operators, cache formatter regexes, and disable unsafe line-oriented wrapping until an AST-aware pass exists.
- Evidence: all Workcell `.kujo` files pass `kujo format --check`; formatted temporary copies pass `kujo check`; formatter regression tests cover operators, CLI flags, paths, arrays, dictionaries, imports, comments, and string contents.
- Remaining opportunity: implement AST-aware wrapping so line length can be improved without moving commas across expression boundaries.
- Priority: medium for production Kujo repositories.
- Blocks Workcell: no; formatting is now a safe gate, with wrapping intentionally conservative.

## Linter control-flow analysis

- Resolved: Kujo commit `7ef6eb8` makes reachability token-aware and distinguishes multiline returned data from statements after a direct terminator. Workcell now handles its fallible file/JSON calls explicitly.
- Evidence: every Workcell source module passes `kujo lint --json` with zero findings; the linter regression suite covers direct unreachable code and multiline returned dictionaries.
- Remaining opportunity: evolve the linter from line facts to AST/control-flow analysis for branch-sensitive reachability.
- Priority: medium.
- Blocks Workcell: no; lint output is currently clean for the repository.
