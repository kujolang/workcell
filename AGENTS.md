# Workcell Agent Instructions

Workcell 1.x is the stable local and CI Docker/Podman harness for bounded Kujo and agent workflow execution. Treat Docker/Podman as the physical isolation boundary and Kujo/Workcell receipts as the evidence boundary. Do not extend the stable claim beyond the documented v1 contract.

The repository also contains an additive alpha provider-neutral lifecycle. Workcell core owns workload semantics, policy, evidence, verification, failure classification, recovery, and cleanup; adapters own provider compute and transport. Docker and Podman are built in, E2B/Vercel Sandbox/Daytona are official external adapters, and gVisor/Kata remain OCI runtime selections. Do not add provider branches to the workload definition or promote offline conformance into a live security claim.

## Required Reading

- `README.md`
- `docs/security-model.md`
- `docs/enterprise-deployment.md`
- `docs/workcell-definition.md`
- `docs/runtime-lifecycle.md`
- `docs/backend-adapters.md`
- `docs/adapter-authoring.md`
- `docs/api-compatibility.md`
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
npm test --prefix adapters/official
npm run integrity:check --prefix adapters/official
```

Run Docker/Podman integration gates only when the engine and required local image are available:

```bash
docker build --tag kujolang/workcell-base:local docker/
./bin/workcell doctor --backend docker --json
./bin/workcell run --file workcell.json --repo . --no-pull
```

## Evidence Rules

- For agent calls, prefer `inspect --summary` and `run --summary`; follow their pointers to the receipt only when detailed evidence is needed. Do not paste full receipts, logs, capability ledgers, or provider responses into context by default.
- Preserve `.workcell/runs/<run-id>/receipt.json`, `manifest.json`, stdout/stderr logs, and `workcell verify` output outside Git when release evidence is required.
- If Docker image pull/build is blocked by local daemon, credential helper, or network/DNS state, write a blocker receipt with the failed command, reason, closest passing local proof, and safe resume command.
- Workcell v1 is stable only for the documented local and CI Docker/Podman contract. Do not claim universal sandboxing, hosted-service readiness, enterprise certification, or target-environment acceptance without the operator-owned host, egress, image-governance, retention, key-custody, and compliance evidence.
- Remote adapter promotion additionally requires exact account/plan/region/API/SDK evidence for every advertised control, bounded execution and transfer, cancellation, recovery, cost/performance, and zero owned orphans.
- Run `tests/live_certification.sh` only after reading `docs/live-provider-certification.md`. Live mode requires both `WORKCELL_LIVE_AUTHORIZED=1` and the exact provider gate; fixture mode is the only normal development path.

## Prohibited Without Approval

Do not publish images, push release tags, create public releases, deploy hosted runners, use live credentials, sign/notarize artifacts, force-push, rewrite history, or discard user changes.
