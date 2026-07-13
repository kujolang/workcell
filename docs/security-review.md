# Workcell Security Review

## Implemented protections

- Clean-source enforcement prevents silent omission of dirty repository changes.
- Git worktree/clone isolation prevents direct writable mounts of the source repository.
- Structured argv prevents host-side command injection through image/path arguments.
- Docker policy rejects host networking, privileged mode, Docker socket/root/home/credential mounts, host namespaces, devices, and unbounded resource values.
- Containers receive non-root identity, read-only root by default, no-new-privileges, dropped capabilities, explicit network, resource, PID, and timeout limits.
- Artifact paths are normalized and contained; only declared outputs are copied.
- Secret names are explicit, values are runtime-only, and known values are redacted from captured logs and excluded from receipts.
- Artifact secret policies fail closed when a declared secret cannot be inspected as text; binary artifacts are not silently exported under `reject` or `redact` policies.
- Cleanup filters Docker resources by Workcell ownership labels.
- Workcell-built images receive deterministic ownership, run ID, project, and version labels; the integration suite verifies the label set.
- Source workspaces are scanned for symlinks, output roots reject symlink components, and temporary workspace deletion requires a Workcell ownership marker.
- Resource values are bounded (CPU, memory, PIDs, and a 24-hour timeout maximum); duration parsing rejects non-integer amounts.

## Adversarial review

- Offline tests (161 assertions plus 18 workspace and 5 stress assertions) reject host network, parent traversal, absolute artifact paths, unsafe tmpfs targets and mount targets, symlink artifact sources, image shell metacharacters, unknown fields, invalid timeouts including integer overflow, overflowed identities and memory values, partial numeric resource and scan sections without runtime crashes, exported policy, summary, daemon-security, verification, integration, image-build/ensure, receipt, container-policy, workspace-operation, utility, artifact-export/log, manifest, Docker-runtime, repository-inspection, symlink-scan, workspace-creation, doctor, policy-construction/inspection, coordinator-output, CLI-argument, integration/image-source, and verification-execution API calls with incomplete inputs without runtime crashes, receipt mutation/path input failures without crashes, duplicate secret/artifact inputs, undeclared secret assignments, invalid environment names/values, unbounded resources, bounded artifact policies, invalid verification plans, invalid workspace scan/run-as policies, malformed network section types, privileged argument presence, Docker socket references, host-control/proxy environment exposure, arbitrary absolute output destinations, digest/signature-key errors, registry allowlist errors, custom-network, managed/unmanaged egress, and security-profile validation errors, namespace regressions, null process output, exact/base64-derived secret leakage regressions, secret literals in receipts/errors/verification plans, spoofed ownership markers, active-workspace cleanup races, empty-orphan recovery, disappearing-workspace handling, optional integration defaults/bounds/redaction, explicit dry-run integration skips, runtime-class injection, backend-neutral CLI output, RunLedger finish-state reporting, manifest tamper detection, Podman policy selection, rootless workspace identity, partial-default regressions, and binary artifact secret inspection failures. The dedicated adversarial CLI suite also rejects host-network, sensitive-mount/privileged-field, traversal, image/runtime injection, resource, secret, and build-context attacks, then verifies the restrictive inspect policy and missing-Podman doctor diagnostics. `inspect --json` was inspected to confirm the effective policy contains `--network none`, `--read-only`, `--init`, private IPC, `--cap-drop ALL`, `no-new-privileges`, host-mapped non-root identity, labels, bounded resources, and only the workspace mount. Fence reports zero boundary violations.

Docker integration now covers timeout termination, Docker exit-125 workload classification, arbitrary output-path rejection, and label-scoped cleanup on the local daemon. The rootless OCI smoke runs the selected backend's doctor preflight; Podman security inspection now requires an enabled seccomp profile and has a fake-CLI regression contract proving disabled seccomp fails closed. The adversarial CLI suite covers privileged/socket/root-mount request rejection before runtime; the suite does not claim to exercise a real privileged container because the policy must reject it first.

The concurrent load contract runs four Workcell executions against one clean source repository and shared output root. It passed on rootful Docker and rootless Docker/Podman in the Colima Linux VM, proving run-ID separation, unchanged source, verified manifests/artifacts, and cleanup of successful run workspaces and containers.

CLI parsing is fail-closed for command boundaries: global help/version are explicit, unsupported command options and extra positionals return usage code 2, and the machine-readable CLI contract exposes the global options.

## Residual risk

Docker daemon and host kernel trust, transformed secret leakage, external cosign key lifecycle/transparency policy, no hardened microVM, and no controlled proxy remain explicit limitations.
