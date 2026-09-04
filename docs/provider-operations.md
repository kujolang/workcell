# Remote provider operations

This runbook covers the official E2B, Vercel Sandbox, and Daytona adapters. It
does not promote any provider: production acceptance remains scoped to an exact
account, plan, region, adapter archive, SDK/API version, profile, and live
certification date.

## Ownership and support

The WorkCell maintainers own the provider-neutral contract, offline verifier,
official adapter source, release-candidate tooling, and security response for
those components. The deploying operator owns credentials, provider accounts,
approved regions/endpoints, spend controls, evidence retention, monitoring, and
incident escalation. Provider availability and deletion behavior remain the
provider's responsibility. No uptime or response-time SLO is offered before a
maintainer and escalation rotation is explicitly published.

## Threat boundaries

The adapter is trusted host code and executes with the invoking user's authority.
Its provider SDK receives only the provider credential for lifecycle operations;
declared workload secrets are added only for `execute`. The authenticated bundled
dependency tree, exact launcher digest, disabled ambient environment inheritance,
bounded JSONL protocol, clean one-commit package, ownership nonce, pre/post-delete
inventory, and local artifact revalidation are required controls. The provider
still enforces remote compute, filesystem, network, inventory, and deletion
semantics. A provider claim is not upgraded to WorkCell-enforced evidence.

## Monitoring and incident response

Alert on `recovery-required`, `cleanup-failed`, terminal-unknown, incomplete
inventory, ownership mismatch, credential failure, capability drift, artifact
rejection, and receipt/manifest verification failure. On an incident:

1. stop new profile use without deleting evidence;
2. revoke or rotate the scoped provider credential;
3. preserve the receipt, manifest, recovery journal, exact adapter archive,
   checksum, profile fingerprint, and provider audit-log reference;
4. inventory by run ID and nonce, then use `workcell recover --dry-run` before
   an authorized recovery;
5. verify repeated zero inventory and local manifests;
6. document exposure, provider/account scope, retention impact, and the exact
   version fixed before re-enabling the profile.

Never edit a recovery journal or package in place. A suspected package compromise
requires archive revocation and rollback to a separately retained, verified
archive.

## Retention, privacy, legal, and licensing

Evidence and provider retention are separate. Operators set local receipt/log/
artifact retention and provider sandbox, snapshot, volume, audit-log, and backup
retention independently. Approved data classifications, residency, subprocess
logging, subprocessors, deletion commitments, terms, and privacy review are live
deployment prerequisites. The adapter package is MIT licensed; its SPDX SBOM is
an input to, not a substitute for, organizational dependency/license approval.

## Drift and deprecation

At each candidate release and on a scheduled cadence, review provider SDK and API
deprecations, lockfile audit results, SBOM/license deltas, capability mappings,
profile routing fields, pricing/plan changes, and provider incident advisories.
Any semantic drift blocks promotion until offline conformance and the protected
live certification matrix pass again. Rollback, revocation, and uninstall steps
are in [Official adapter distribution](official-adapter-distribution.md); exact
provider limits and recovery notes are under [`docs/providers`](providers/).
