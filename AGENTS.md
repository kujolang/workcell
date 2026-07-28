# Workcell Agent Instructions

Workcell is the local Docker/Podman proof harness for bounded Kujo and agent workflow execution. Treat Docker/Podman as the physical isolation boundary and Kujo/Workcell receipts as the evidence boundary.

## Required Reading

- `README.md`
- `docs/security-model.md`
- `docs/enterprise-deployment.md`
- `docs/workcell-definition.md`
- `docs/runtime-lifecycle.md`
- `docs/launch-checklist.md`

## Validation

Use the exact Kujo runtime under `KUJO` or `KUJO_BIN`.

```bash
./bin/workcell --help
./bin/workcell --version
./bin/workcell validate --file workcell.json
./tests/run.sh
./tests/quality.sh
git diff --check
```

Run Docker/Podman integration gates only when the engine and required local image are available:

```bash
docker build --tag kujolang/workcell-base:local docker/
./bin/workcell doctor --backend docker --json
./bin/workcell run --file workcell.json --repo .
```

## Evidence Rules

- Preserve `.workcell/runs/<run-id>/receipt.json`, `manifest.json`, stdout/stderr logs, and `workcell verify` output for launch proof.
- If Docker image pull/build is blocked by local daemon, credential helper, or network/DNS state, write a blocker receipt with the failed command, reason, closest passing local proof, and safe resume command.
- Do not call Workcell production-ready or enterprise-ready without target Docker/Podman host hardening, egress, image-governance, retention, and clean-machine proof.

## Prohibited Without Approval

Do not publish images, push release tags, create public releases, deploy hosted runners, use live credentials, sign/notarize artifacts, force-push, rewrite history, or discard user changes.
