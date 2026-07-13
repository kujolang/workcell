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
- Docker-built image resources now carry Workcell ownership, run ID, project, and version labels for auditable resource boundaries.
- Binary change classification indexes Git's binary paths before updating file metadata, and untracked files use batched MIME probes in bounded chunks rather than one probe per file.
- The current 97 policy/artifact/verification, 11 workspace, and 5 stress contracts cover custom network and egress-policy validation, partial defaults, empty-secret logs, exact/base64-derived secret redaction, secret-safe receipts/errors, binary change metadata, digest/signature-key validation, namespace policy, null process output, bounded absolute output paths, host UID/GID mapping, workspace scan limits, artifact policies, verification plans, optional integration evidence/redaction, dry-run integration skips, Podman policy/doctor selection, atomic-write failure checks, runtime-class validation, backend-neutral CLI output, null-safe human failure output, RunLedger finish-state reporting, versioned manifest verification/tamper detection, active-workspace cleanup protection, empty-orphan recovery, disappearing-workspace handling, schema/help output, release-report, example matrix, API compatibility, and version consistency.

The follow-up hardening pass also added declarative verification containers, bounded artifact export policies, host-mapped workspace ownership, bounded workspace scans, image ID/platform/label provenance, `clean --dry-run` inventory with explicit image retention, a first-class verification example, version-source validation, a compatibility matrix, and a 2,000-file opt-in performance signal.

The continuation review caught and fixed two additional concrete failure paths: human-readable failure output attempted to concatenate a null patch path after early failures, and a workspace scan could race with disappearance between directory discovery and listing. Both now fail with stable fallbacks and regression coverage; empty orphan Workcell directories are safely recoverable while non-empty unowned paths remain preserved.

Verification on the local Docker/Colima daemon passed the full offline suite and `tests/docker_integration.sh`. The integration run covered successful execution, declared artifacts, controlled edits, runtime image builds, digest verification and mismatch failure, workload failure, timeout cleanup, symlink rejection, and ownership-scoped cleanup. Docker buildx 0.35.0 is installed locally and the integration suite now exercises BuildKit.

Remaining enterprise-grade recommendations are rootless or microVM daemon deployment, a controlled egress proxy, and key lifecycle/transparency policy around cosign. Workcell now accepts reviewed named seccomp/AppArmor profiles and pre-created custom networks, rejects arbitrary absolute output destinations, redacts secret literals incrementally in stream logs and completion outputs, records cancellation explicitly, and classifies Docker exit 125 correctly, but does not install profiles or provision the daemon. CI now runs on a clean Docker runner, and BuildKit is required in CI with a local legacy-builder fallback.
