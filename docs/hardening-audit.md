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
- Offline contracts cover partial defaults, empty-secret logs, exact/base64-derived secret redaction, binary change metadata, digest/signature-key validation, namespace policy, and null process output; CLI smoke covers the preparation exit-code and Docker-profile contracts.

Verification on the local Docker/Colima daemon passed the full offline suite and `tests/docker_integration.sh`. The integration run covered successful execution, declared artifacts, controlled edits, runtime image builds, digest verification and mismatch failure, workload failure, timeout cleanup, symlink rejection, and ownership-scoped cleanup. Docker buildx 0.35.0 is installed locally and the integration suite now exercises BuildKit.

Remaining enterprise-grade recommendations are rootless or microVM daemon deployment, a controlled egress proxy, explicit seccomp/AppArmor profile selection, key lifecycle/transparency policy around cosign, and streaming/derived-secret redaction. CI now runs on a clean Docker runner, and BuildKit is required in CI with a local legacy-builder fallback.
