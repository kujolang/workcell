# Cloudflare Sandbox operator-bridge decision

## Decision

Cloudflare Sandbox is technically capable of running the WorkCell Linux-process
contract, but ordinary Workers are not. A Free-plan Worker has a 10 ms CPU limit,
an isolate runtime, and no general Linux process or container boundary. The
Sandbox SDK supplies command execution and files by adding Cloudflare Containers
and Durable Objects; both the Sandbox SDK and Containers require Workers Paid.

WorkCell therefore keeps Cloudflare classified as a deferred operator bridge,
not a standard provider and not a substitute for Docker, Podman, E2B, Vercel
Sandbox, or Daytona certification. The bridge must be deployed into an
operator-owned Cloudflare account and called by a separately packaged WorkCell
adapter. No Cloudflare-wide isolation, authentication, retention, or cleanup
claim may be inferred from one operator deployment.

Sources: [Sandbox SDK](https://developers.cloudflare.com/sandbox/),
[Sandbox bridge](https://developers.cloudflare.com/sandbox/bridge/),
[Containers](https://developers.cloudflare.com/containers/), and
[Workers limits](https://developers.cloudflare.com/workers/platform/limits/).

## Free-account preflight

Run the read-only entitlement check without creating a Worker, Durable Object,
Container, route, secret, or billable resource:

```bash
./scripts/cloudflare-sandbox-preflight.sh
```

The script reports only booleans and a normalized blocker; it does not print or
persist account IDs, email addresses, tokens, or Wrangler output. Exit `0` means
the account can list Containers. Exit `3` is an external prerequisite. On
2026-09-04, Wrangler authentication succeeded on the implementation host, the
local Docker daemon was reachable, and Cloudflare denied Containers because the
account did not have Workers Paid. No Cloudflare resources were created.

## Ownership contract before implementation

- The operator owns the Worker, Durable Object namespace, Container application,
  bridge authentication, bindings, image rollout, logs, storage, retention,
  region policy, quotas, and spend ceiling.
- WorkCell owns the local JSON-lines adapter contract, portable workspace package,
  declared artifact validation, normalized receipts, and redaction.
- Every remote resource must carry both the WorkCell run ID and an unpredictable
  ownership nonce. Inventory and destruction must require both values plus the
  configured account/profile identity.
- A lost create, command, transfer, or destroy response enters recovery. Cleanup
  is not complete until authoritative inventory reports zero owned Containers,
  Durable Objects, staged objects, and bridge-side run records.
- Network-none and allowlist claims require live negative probes for DNS, IPv4,
  IPv6, redirects, private/link-local and metadata endpoints, plus any documented
  Cloudflare exceptions.

## Gates that remain after entitlement

Workers Paid only unlocks implementation and live testing. Before promotion,
the bridge still needs an architecture review, exact SDK/image pinning, an
authenticated bridge deployment, bounded live certification, concurrency and
fault injection, cost/performance evidence, zero-orphan recovery, packaging,
onboarding, support, and rollback evidence. `MEGA_PROMPT.md` also keeps phase 11
behind completion of the E2B, Vercel Sandbox, and Daytona live, packaging,
onboarding, and operational gates.

After the plan is upgraded, resume with:

```bash
./scripts/cloudflare-sandbox-preflight.sh
```

Do not scaffold or deploy the bridge merely because that command returns
`eligible`; first record the phase-11 architecture review and approved spend
ceiling.
