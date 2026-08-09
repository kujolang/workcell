# Workcell Agent Instructions

Workcell 1.x is the stable local and CI Docker/Podman harness for bounded Kujo and agent workflow execution. Treat Docker/Podman as the physical isolation boundary and Kujo/Workcell receipts as the evidence boundary. Do not extend the stable claim beyond the documented v1 contract.

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
./tests/version_consistency.sh
./tests/run.sh
./tests/quality.sh
./tests/release_report.sh
./tests/markdown_links.sh
git diff --check
```

Run Docker/Podman integration gates only when the engine and required local image are available:

```bash
docker build --tag kujolang/workcell-base:local docker/
./bin/workcell doctor --backend docker --json
./bin/workcell run --file workcell.json --repo . --no-pull
```

## Evidence Rules

- Preserve `.workcell/runs/<run-id>/receipt.json`, `manifest.json`, stdout/stderr logs, and `workcell verify` output outside Git when release evidence is required.
- If Docker image pull/build is blocked by local daemon, credential helper, or network/DNS state, write a blocker receipt with the failed command, reason, closest passing local proof, and safe resume command.
- Workcell v1 is stable only for the documented local and CI Docker/Podman contract. Do not claim universal sandboxing, hosted-service readiness, enterprise certification, or target-environment acceptance without the operator-owned host, egress, image-governance, retention, key-custody, and compliance evidence.

## Prohibited Without Approval

Do not publish images, push release tags, create public releases, deploy hosted runners, use live credentials, sign/notarize artifacts, force-push, rewrite history, or discard user changes.
