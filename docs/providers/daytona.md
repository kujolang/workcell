# Daytona adapter operations

## Exact identity and setup

The official candidate pins adapter and SDK version `0.207.1`, manifest schema
`workcell-backend-manifest/v1`, protocol `workcell-backend/v1alpha1`, and profile
schema `workcell-daytona-profile/v1alpha1`. Install it through
[Official adapter distribution](../official-adapter-distribution.md). The profile
refers to `env:DAYTONA_API_KEY`; the value is never profile or evidence data.
Hosted and self-hosted profiles must be separate. Confirm account, target,
region, sandbox class, endpoint, CA/TLS policy, and image before enabling one.

The manifest advertises provisioning, network-none, domain allowlisting,
workspace staging, and selective artifact export. These do not establish that a
specific hosted or self-hosted deployment enforces the controls. Self-hosted
authority belongs partly to the operator and substrate, and must not inherit a
hosted-service claim.

## Certification, limits, and recovery

Use [Live provider certification](../live-provider-certification.md) independently
for each hosted plan/region and approved self-hosted deployment class. Current
evidence is offline fixture-only. Network negative probes, compute/disk/PID and
filesystem semantics, persistence/TTL, cancellation/disconnect, performance,
cost, retention, and repeated zero-orphan inventory remain live blockers.

Owned sandboxes carry run ID and nonce labels. Recover with the journal and
exact trusted adapter, first confirming endpoint and account. Match both labels,
delete item by item, and repeat complete inventory to zero. Include secondary
volumes, snapshots, objects, images, and tasks when a deployment exposes them;
an adapter that cannot inventory them is not promotable. For credential or TLS
incidents, disable the profile, rotate the key, restore the reviewed CA/endpoint
configuration, and retain only redacted evidence.

## Support

WorkCell maintainers own the adapter package and contract. The operator owns
hosted/self-hosted deployment security, credentials, endpoint trust, capacity,
retention, backups, upgrades, spend, and provider escalation. No production SLO
or hosted/self-hosted equivalence is claimed. Roll back by verified digest and
uninstall only after complete zero-owned-resource inventory.
