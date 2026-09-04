# Live provider certification

Live certification is an explicit, provider-specific operational gate. It is
not part of normal tests, never runs from a pull request, and never starts merely
because a credential exists. A passing report applies only to the exact account,
plan, region, adapter, SDK/API, image/template, profile fingerprint, source
commit, and date recorded in the evidence bundle.

## Offline fixture proof

The fixture path exercises the same profile selection, capability resolution,
portable source package, lifecycle coordinator, receipt, cleanup, and offline
manifest verification without a provider credential or network call:

```bash
export KUJO=/path/to/pinned/kujo
WORKCELL_LIVE_EVIDENCE_DIR=/tmp/workcell-certification-e2b \
  ./tests/live_certification.sh e2b --fixture
```

Run the contract across all official providers with:

```bash
KUJO="$KUJO" ./tests/live_certification_contract.sh
```

Fixture reports use `mode: fixture`. They are protocol and harness evidence,
not provider isolation, network, cleanup, cost, retention, or live certification.

## Live authorization boundary

An approved live run requires both `WORKCELL_LIVE_AUTHORIZED=1` and the exact
provider gate:

- `WORKCELL_LIVE_E2B=1`
- `WORKCELL_LIVE_VERCEL_SANDBOX=1`
- `WORKCELL_LIVE_DAYTONA=1`

It also requires an absolute evidence directory outside the repository, an
explicit host-profile file and ID, account/plan, region, image/template, and a
reviewed spend ceiling. The selected profile supplies the credential reference,
provider routing, guarantees, integrity digest, and policy ceilings. The harness
does not invent those values or fall back to ambient SDK authentication.

```bash
WORKCELL_LIVE_AUTHORIZED=1 \
WORKCELL_LIVE_E2B=1 \
WORKCELL_LIVE_EVIDENCE_DIR=/approved/outside-git/e2b-2026-09-04 \
WORKCELL_LIVE_PROFILES_FILE=/approved/workcell/host-profiles.json \
WORKCELL_LIVE_PROFILE_ID=e2b-certification \
WORKCELL_LIVE_ACCOUNT_PLAN=team-plan-name \
WORKCELL_LIVE_REGION=provider-region \
WORKCELL_LIVE_IMAGE_TEMPLATE=immutable-template-id \
WORKCELL_LIVE_SPEND_CEILING=operator-reviewed-provider-budget \
KUJO=/path/to/pinned/kujo \
./tests/live_certification.sh e2b
```

The script caps runtime at 300 seconds, concurrency at one, workspace upload
and artifact download at 10 MiB each, and captured logs at 1 MiB. Lower values
are encouraged. A value above a hard cap fails before inspection or provisioning.

## Required evidence beyond the smoke

The harness's first live run proves only the bounded success lifecycle it records.
Production promotion also requires independently retained, redacted cases for
non-zero exit, timeout, cancellation, disconnect, provider error, quota/rate
limit, lost provision response, lost destroy response, exact workspace digest,
declared artifact export, pagination, secondary-resource inventory, and repeated
zero-orphan reconciliation.

Security probes must record DNS, direct IPv4, direct IPv6, metadata endpoints,
private/link-local addresses, redirects, provider control-plane exceptions, and
secret canaries. `not-run` and `not-observed` remain blockers. A failed connection
to one destination is a narrow observation, not universal network enforcement.
The committed report schema is
[`workcell-live-certification/v1`](../schemas/workcell-live-certification-v1.schema.json).

## Failure and recovery

If a run does not return a receipt path, the report is
`recovery-required`; preserve the entire evidence directory. If a receipt exists
but cleanup is incomplete, follow its recovery journal:

```bash
./bin/workcell recover \
  --journal /approved/outside-git/run/recovery/<run-id>.json \
  --manifest adapters/official/<provider>/manifest.json \
  --profile /approved/workcell/resolved-adapter-options.json \
  --dry-run --json
```

Review the dry run, account/profile fingerprint, run ID, nonce, and complete
inventory before removing any exact owned resource. Never delete by display name
or run ID alone. A missing or incomplete inventory remains a release blocker.
