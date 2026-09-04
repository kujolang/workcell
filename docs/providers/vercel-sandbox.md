# Vercel Sandbox adapter operations

## Exact identity and setup

The official candidate pins adapter and SDK version `3.2.1`, manifest schema
`workcell-backend-manifest/v1`, protocol `workcell-backend/v1alpha1`, and profile
schema `workcell-vercel-sandbox-profile/v1alpha1`. Install and verify the archive
through [Official adapter distribution](../official-adapter-distribution.md).
The profile refers to `env:VERCEL_OIDC_TOKEN`; no ambient credential fallback is
permitted. Use a dedicated project and short-lived OIDC policy with only the
scope required to create, connect, list, and stop owned sandboxes. Confirm the
team/project, plan, region, and image before enabling the profile.

The manifest advertises provisioning, network-none, domain allowlisting,
workspace staging, and selective artifact export. These are routing hints only.
The exact behavior of redirects, DNS, IPv4/IPv6 literals, metadata and private
addresses, project policy, filesystem, compute, retention, and isolation must be
established by exact live negative probes before promotion.

## Certification, limits, and recovery

Use [Live provider certification](../live-provider-certification.md), with the
smallest allowed bounds. The repository currently proves fixture conformance,
not live enforcement, performance, cost, or cleanup. OIDC expiry, revocation,
wrong-project identity, quota, unsupported region/image, timeout, cancellation,
disconnect, and lost-response branches remain live blockers.

Owned sandboxes are tagged with run ID and nonce. Recovery requires the journal,
exact trusted adapter, and account/project agreement; inventory must match both
ownership fields before stop/delete and must be repeated to zero. A wrong or
incomplete inventory is recovery-required, never permission to broaden deletion.
For credential incidents, revoke the OIDC trust/token, disable the profile, and
retain redacted evidence.

## Support

WorkCell maintainers own protocol and package behavior; operators own Vercel
identity, project controls, policy, spend, retention, and escalation. No
production SLO is claimed. Roll back by verified archive digest, and uninstall
only after complete zero-owned-resource inventory.
