# Experimental effect assurance: two local adapters

Unreleased Wave C prototype. This is not a stable Workcell effect API, a new
execution-result version, or a change to workload admission/preservation.

`src/evidence/git_effect.kujo` demonstrates a repository/ref effect independently
of Dispatch's SQLite transaction sink. It uses a dedicated operator-owned bare
Git repository, digest-only intent, structured argv, bounded 5-second/8-KiB
subprocesses, no inherited Git environment, and disabled hooks. Git and the
repository/configuration are trusted local infrastructure; producer JSON never
selects a path, executable, ref name or URL. A compromised host/operator remains
outside this proof. Repositories shared with arbitrary writers are unsupported.

The target ref is `refs/kujo-targets/<target_sha256>`. The immutable operation ref
is `refs/kujo-effects/<scope_sha256>/<key_sha256>` and points to the exact bounded
intent blob. One `git update-ref --stdin` transaction creates that marker and
compare-and-swaps the target from the expected old object to the requested new
object. Repeating the same intent observes the marker and postcondition without
updating the target again. Changed input, target, expiry, precondition or scope
cannot borrow the original marker. If the target subsequently moves, observation
and replay reject, even if the old marker remains. No ref history/ABA guarantee,
remote Git service guarantee, deployment guarantee or rollback follows.

The prototype supports SHA-1 Git object repositories only; outer assurance uses
SHA-256 exact bytes and digests. Git object identities are not treated as signed
producer identities. Supporting SHA-256 Git repositories requires another tested
adapter profile, not an unvalidated length change.

## Source-runtime fixture

Use Kujo source runtime `39d5a0a381c374a6f9bd6ec75bb820a5b68aeb68` (runtime code
unchanged from `5d72aab`) or the Dispatch source pin with process stdin and bounded
reads. The stable Workcell `RUNTIME_VERSION` remains unchanged; this experimental
harness is not a claim that npm/native 1.5.0 or Workcell's 1.2.1 pin includes every
required primitive.

```bash
KUJO_BIN=/path/to/source/kujo bash tests/effect_assurance.sh
```

The adapter entrypoint `examples/effect-assurance/adapter.kujo` consumes an
**operator-owned** config directory. `config.json` names the dedicated repository,
old/new object identities and fixed intent. Never expose that entrypoint as an
untrusted tool/config endpoint. `before_commit` and `after_commit` are test-only
crash barriers; normal embeddings call the module with an empty barrier string.
The sink checks current UTC validity again at mutation admission. Expiry is not
permission to forget an old marker or to reuse its key for a new request.

Cross-repository proof lives in Dispatch `tests/effect_assurance_integration.mjs`:
actual adapter processes are SIGKILLed before the ref transaction or after it
commits, then a fresh controller resolves evidence and invokes existing Dispatch
review/retry semantics. A pre-transaction kill can leave an unreachable intent
blob, but no logical target/ref effect. Mid-Git-process and machine-power-loss
recovery are not established by this fixture. Workcell preservation and v1
execution-result derivation remain unchanged.

## Assurance handoff

Dispatch's local `dispatch.effect-assurance/v1alpha1` document binds exact result
bytes, run/step/attempt/effect, operation, target, account/environment/key scope,
input/precondition, transaction, reported versus observed completion and validity.
The schema is additive and experimental. One effect/one evidence digest, 8 KiB,
closed fields, no raw target path or payload. The issuer label does not authorize
anything: a separately configured verifier invokes this adapter and compares live
sink facts with the document. A hash is identity, not authentication. The adapter
never fetches an evidence reference.

Compensation is explicitly `not_evaluated`: support, request, execution and verified
reversal remain separate future facts. No saga engine is introduced.

## Checked local Git mutation boundary

`git_effect_apply_checked(repo, intent, old_oid, new_oid, verify)` is an
experimental installed-host integration point. Workcell independently validates
intent and live refs, invokes `verify` immediately before its bounded atomic Git
ref transaction, and rechecks the intent deadline. False or throwing callbacks
deny mutation. An already committed effect does not pass this checked boundary;
ordinary `git_effect_apply` retains its historical duplicate-observation behavior.

Dispatch retains its run lock and owns selection, lifecycle, current authority,
and permanent admission consumption. Workcell owns target/marker observation and
Git compare-and-swap. Neither the callback nor a successful admission proves the
mutation happened: lost replies require fresh live verification, never replay.
The callback is an installed trusted-host function, not serialized participant
permission. This does not provide cross-host authority, arbitrary-writer fencing,
cross-sink transactions, exactly-once execution, or rollback.

Validation: `tests/git_effect_contract.mjs` exercises refusal, callback exception,
checked mutation and refusal after completion alongside the historical API cases.
Dispatch's sequential fixture independently exercises C/D lifecycles and process
loss against real Workcell refs using this same implementation.
