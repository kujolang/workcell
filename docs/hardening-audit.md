# Workcell hardening audit

Date: 2026-07-11

The audit reproduced four defects before fixes. Each now has a regression test:

1. Partial nested definitions passed validation and then crashed when summaries or policies read a missing field. `resolve_definition` now fills nested defaults before validation.
2. Newly created binary files were reported as `binary: false` in `changes.json`, even though the generated patch contained binary data. Untracked files now use Git's binary-aware no-index numstat detection.
3. Image-preparation failures returned JSON `exit_code: 4` but the launcher process exited `3` unless the error text happened to contain the word `docker`. The CLI now honors the structured result code.
4. An empty declared secret caused log redaction to replace every string boundary, corrupting captured logs. Empty secret values are now skipped by the redactor.

Additional hardening completed in this pass:

- Nested default filling is centralized in one helper instead of repeating field-by-field logic at each call site.
- Host-control environment policy is centralized and now rejects proxy, Git credential-helper, GitHub, npm-token, and existing Docker/cloud control variables.
- Binary change classification indexes Git's binary paths before updating file metadata, avoiding the previous nested file/numstat scan for tracked changes.
- Offline contracts cover partial defaults, empty-secret logs, and binary change metadata; CLI smoke covers the preparation exit-code contract.

Verification on the local Docker/Colima daemon passed the full offline suite and `tests/docker_integration.sh`. The integration run covered successful execution, declared artifacts, controlled edits, workload failure, timeout cleanup, symlink rejection, and ownership-scoped cleanup. The Docker build still emits a legacy-builder warning because this daemon does not provide the `buildx` plugin; this is a tooling upgrade item, not a Workcell test failure.

Remaining enterprise-grade recommendations are image signature/policy verification, digest-pinned definitions rather than mutable tags, a rootless or isolated daemon, a controlled egress proxy, seccomp/AppArmor policy selection, CI execution on a clean Docker runner, and streaming secret redaction.
