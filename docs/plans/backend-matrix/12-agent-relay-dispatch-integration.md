# Kujo Agent, plugin, Relay, and Dispatch integration

## Ownership rule

WorkCell remains execution-only. It accepts one bounded workload attempt and returns evidence. It does not choose agent strategy, retry workloads, repair code, schedule missions, approve effects, route models, or orchestrate multi-step workflows.

## Kujo Agent

Current `kujo agent run --workcell`:

- validates a clean Agent Project Git commit;
- stages Agents SDK into an image build context;
- rewrites the last WorkCell command argument with the prompt;
- invokes `workcell run` as a subprocess;
- locates the newest receipt and reports `isolation: workcell`.

Target behavior:

- continue referencing one WorkCell definition path;
- pass prompt/input through a versioned invocation override rather than rewriting arbitrary definition JSON;
- select a host/operator WorkCell profile by environment mapping;
- invoke `workcell run --profile <id>` and consume the returned exact receipt path, never “latest child” discovery;
- report `execution_boundary: workcell` and an inspectable backend summary without using backend identity as the agent abstraction;
- keep model/provider credentials separate from backend control-plane credentials;
- continue rejecting dirty projects before WorkCell remote packaging.

Portable Agent Project example:

```text
same agent.project.json + same workcell.json
  developer host -> profile local-docker
  Linux CI       -> profile ci-podman
  Codex host     -> profile e2b-project
  enterprise     -> profile daytona-private
```

Backend choice belongs in host integration/operator policy, not the agent's skills, intelligence, tools, or prompt.

## Kujo Agent Bridge/Plugin

Expose one semantic tool:

```text
execute_workcell(definition_ref, input_overrides, profile_hint?)
```

The bridge may expose inspect, cancel, receipt, and recovery status as separate bounded operations. It must not expose `call_e2b`, `create_daytona`, or provider credentials to the agent. Backend identity, capabilities, resolved security, and cost class remain inspectable in the result/receipt. Profile hints are advisory and subject to operator policy.

The plugin must stream normalized WorkCell events, not raw provider SDK events. Approval applies to the WorkCell effect and selected policy/profile. Provider escape-hatch options are not agent-writable.

## Dispatch

Dispatch owns orchestration: workflow DAG/state, approvals, retries, repair ceilings, budgets, resumability, and step correlation. It may select an operator-approved WorkCell profile as part of step policy, but it does not negotiate provider details itself.

Contract:

- Dispatch creates a unique WorkCell run/attempt correlation ID.
- One Dispatch step attempt maps to one WorkCell run. No adapter retries the workload.
- Dispatch retries create a new WorkCell run with `caused_by` pointing to the prior attempt.
- Dispatch cancellation calls WorkCell cancel; WorkCell gracefully cancels or destroys the run resource and returns evidence.
- WorkCell pause/resume is not used for Dispatch workflow pause. Dispatch pause means do not start new effects; an active WorkCell is cancelled or allowed to finish under explicit policy.
- WorkCell returns receipt/manifest references; Dispatch records links/digests rather than redefining evidence.
- Dispatch owns repair decisions; WorkCell never repairs or mutates workflow policy.

## Relay

Relay owns bounded mission composition, agent/tool policy, lifecycle handoffs, mission pause/resume/repair/cancel, and higher-level evidence. WorkCell may be a Relay execution tool for an individual bounded mission step.

- Relay passes correlation/causation IDs and profile selection under operator policy.
- Relay pause does not imply pausing a VM. It controls mission scheduling.
- Relay cancellation propagates to WorkCell and waits for cleanup evidence.
- Relay retries/repair create new WorkCell attempts.
- Relay does not parse provider IDs or call provider APIs.
- WorkCell receipts remain authoritative for execution, artifacts, controls, and cleanup; Relay receipts remain authoritative for mission state and handoff.

## Watchdog, RunLedger, Eval, CaseFile, Spec, ShipCheck

- Watchdog may receive normalized timing/events and provider request telemetry through an explicit integration, but WorkCell does not require a proxy or daemon.
- RunLedger records the WorkCell receipt reference, adapter/profile, usage/cost status, and outcome; it does not replace the receipt.
- Eval runs deterministic checks either as WorkCell verification commands or after exported evidence, with ownership stated explicitly.
- CaseFile captures unresolved failure evidence by explicit workflow choice. It does not become automatic WorkCell storage.
- Spec can declare a WorkCell definition/profile requirement at task-contract level without embedding provider credentials/options.
- ShipCheck validates release readiness and exact live-smoke evidence for official adapters; it does not certify isolation.

## Correlation fields

Receipt v2 accepts optional caller metadata through `workcell run --context <path>`:

```json
{
  "schema": "workcell-caller-context/v1",
  "caller": "dispatch",
  "workflow_id": "...",
  "run_id": "...",
  "step_id": "...",
  "attempt": 2,
  "correlation_id": "...",
  "causation_id": "..."
}
```

`caller` and `correlation_id` are required. Workflow, step, attempt, and causation IDs are optional bounded identifiers. Unknown fields fail validation so the context cannot become an orchestration-policy or secret side channel.

Values are bounded non-secret identifiers. WorkCell's own run ID remains unique and authoritative for resource ownership.
