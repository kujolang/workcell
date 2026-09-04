# E2B adapter operations

## Exact identity and setup

The official candidate pins adapter and SDK version `2.46.1`, manifest schema
`workcell-backend-manifest/v1`, protocol `workcell-backend/v1alpha1`, and profile
schema `workcell-e2b-profile/v1alpha1`. Install and verify the immutable archive
as described in [Official adapter distribution](../official-adapter-distribution.md).
The profile refers to `env:E2B_API_KEY`; the value must not appear in a WorkCell
definition, profile, receipt, log, or evidence bundle. Use a dedicated
least-privilege E2B project and confirm its plan, region behavior, and template
before enabling the profile.

The manifest advertises provisioning, network-none, workspace staging, and
selective artifact export. These are static routing hints, not certification.
CPU, memory, PID, disk, filesystem, network, timeout, output, persistence,
retention, and isolation authority remain unpromoted until exact live evidence
records what E2B enforces and what WorkCell merely requests or observes.

## Certification, limits, and recovery

Run the protected matrix in [Live provider certification](../live-provider-certification.md).
Its bounds cap one concurrent sandbox, five minutes, 10 MiB each direction, and
1 MiB of logs; operators should select stricter values when possible. The
current repository has offline fixture evidence only and makes no live account,
region, template, performance, cost, network-isolation, or zero-orphan claim.

Every owned sandbox carries the WorkCell run ID and nonce. On disconnect or
lost provision/destroy response, retain the recovery journal and exact trusted
adapter, inventory by both ownership values, cancel/kill the identified sandbox,
and repeat complete inventory until zero. Never delete on a run-ID-only match.
Rotate the E2B key after suspected leakage, disable the host profile, preserve
redacted evidence, and follow the provider incident path.

## Support

The WorkCell maintainers own the adapter contract, packaging, and receipt logic;
the operator owns credentials, account policy, provider configuration, spend,
and provider escalation. There is no production SLO until live certification
and an owner-approved support policy are recorded. Roll back by digest to a
previous retained archive; uninstall only after zero-owned-resource inventory.
