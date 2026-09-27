# Controlled Git process participant

Experimental, opt-in and unreleased. This bounded source-runtime example invokes
[the existing Git CAS profile](contracts/git-assurance-profile.md) directly.
It does not use Ability, expose a general Git command runner, or change stable
Workcell execution/preservation contracts.

## Ownership and interface

The operator launches `examples/controlled-git/supervisor.mjs ROOT ATTEMPT` from a
trusted installation. ROOT, runtime, installation directory, repository and intent
are operator configuration, **not caller arguments**. The Node supervisor is an
offline real-process crash harness; admission, action and recording are Kujo.
The only untrusted request is a bounded JSON file containing exactly `call_id`.
There is no network service or standalone mode in this experiment.

The controller writes a private ticket containing participant/call identity,
Dispatch run/step/action-attempt/effect, a distinct `workcell_effect_id` alias,
transaction commitment, preservation outcome and a 120-second expiry. It selects
the current ticket separately. The participant checks request identity, current
attempt, expiry and exact intent commitment before atomically creating an
exclusive confined claim. Duplicate contenders cannot enter the action. A claim
is never automatically refunded after failure. Expiry is rechecked after claim;
Workcell also checks intent validity immediately before its ref transaction.

`workcell_effect_id` is a host-assigned correlation alias, not a new native Git
identifier. Native logical effect identity remains the profile's scoped key and
intent marker. The process invocation UUID is distinct from that stable alias,
call ID and Dispatch attempt. A replay has a fresh ticket, call and process UUID.

The action calls `git_effect_apply`; hooks remain disabled, dangerous Git
environment is not inherited, and bounded argv and operator-owned bare repository
rules remain unchanged. No input can select a repository, raw ref, executable,
profile, verifier, authority, evidence root or Dispatch identity.

## Handoff

[The schema](contracts/git-process-handoff-v1alpha1.schema.json) defines
`workcell.git-process-handoff/v1alpha1`, a closed 13-field document:

| Fields | Meaning/owner |
| --- | --- |
| `schema` | Exact participant format |
| `participant_id`, `participant_call_id`, `participant_invocation_id` | Installed participant, controller-correlated request, actual process invocation |
| `workcell_effect_id` | Host alias for this scoped Git logical effect |
| `dispatch_run_id`, `dispatch_step_id`, `dispatch_attempt_id`, `dispatch_effect_id` | Dispatch-owned authority correlation |
| `outcome` | Participant knowledge: `completion_lost` or `completed`; neither grants replay |
| `execution_result_ref` | Required exact-byte content address |
| `assurance_ref` | Null before live verification; new handoff references selected beta evidence |
| `transaction_sha256` | Existing Workcell intent commitment, not a universal transaction definition |

Maximum handoff UTF-8 bytes: 4096. Identifiers: ASCII, 1–128 characters, start
alphanumeric, remaining alphanumeric or `_.:-`, no control characters. Digests
are lowercase SHA-256 hex; references are exactly `sha256:` plus 64 hex characters.
Compact sorted-key `to_json` bytes are required, including exact wire equality.
Artifacts are exclusive files under host-owned `artifacts/<digest>.json`;
confined readers reject symlinks, traversal, URLs, size excess and digest mismatch.
Request/ticket/config limits are respectively 1024/4096/8192 bytes. Subprocess
streams are bounded to 8192 bytes, supervisor waits at most 15 seconds per child,
and underlying Git commands retain their 5-second bound. No unbounded retries.

No repository paths, raw refs, content, credentials, commands, receipt bodies or
application identities appear in this document. The authoritative v1 result has
an additive `process_correlation` extension binding the invocation and outcome.
The controller attaches assurance by publishing a **new** handoff, without
changing historical result or handoff bytes.

## Uncertainty and replay

The test supervisor sends actual SIGKILL at Workcell's pre/post-ref-transaction
barriers. It records `completion_lost`, never “effect absent.” A separate recorder
uses existing readback to create evidence; Dispatch later repeats live readback
under required/deny beta policy at locked admission. Before commit, the predicate
proves absence only if the target is exactly old and marker absent. After commit,
exact marker plus new target proves sink deduplication. Git errors, moved targets
and mismatched markers never count as absence.

A failure before admission reports `not_admitted`. A caught failure after claim
reports `completion_unknown`; transport/evidence failures do not refund tickets
or authorize replay. The bounded demonstrated recovery covers the two explicit
crash barriers with a surviving host recorder/store, not arbitrary machine loss.

Dispatch alone pauses, checkpoints, validates decisions and invokes a fresh
participant after live assurance. A handoff reader performs integrity/correlation
only. Existing control journal/lifecycle events observe this flow; no new telemetry
bus, Git command/path logging or participant replay engine is introduced.

## Validation

Run the source-runtime owner gate:

```sh
KUJO_BIN=/path/to/source-kujo bash tests/effect_assurance.sh
```

It includes four genuinely concurrent participant processes sharing a ticket:
one admitted, three denied, one marker and one target transition. The Dispatch
`tests/git_participant_integration.mjs` scenarios `before_commit` and `after_commit`
add actual kills, fresh controllers, checkpoint invalidation, hostile inputs,
substitutions, confined reads and privacy. Full evidence is maintained in the
Dispatch Wave D Git audit. These tests do not certify stable Kujo 1.2.1 support
for experimental source-runtime primitives.
