# Official remote backend adapters

These external adapters implement `workcell-backend/v1alpha1` without adding Node or provider SDKs to WorkCell core. Versions are pinned in `package-lock.json`. Install with `npm ci`, then pass the selected `manifest.json` explicitly to WorkCell.

Credentials are references only: `env:E2B_API_KEY`, `env:VERCEL_OIDC_TOKEN`, or `env:DAYTONA_API_KEY`. Values are inherited only by the adapter process and never enter definitions, profiles, receipts, or protocol payloads.

All adapters provide deterministic `fixture_mode` tests without network access. Live tests are opt-in and must prove capability resolution, declared-only export, offline receipt verification, and zero owned resources after cleanup. Conformance is compatibility evidence, not a security certification; receipts record provider controls as provider-claimed unless WorkCell can inspect them.

Official manifests pin the launcher digest. Each launcher pins a verifier that
checks the shared runtime, package metadata, lockfile, and every file in the
bundled provider SDK dependency set before Node starts. Production installations
must verify the release archive checksum and make the installed adapter tree
read-only. The integrity chain detects local file changes; distribution-channel
authenticity still depends on the separately authorized signature and provenance
policy.

After an intentional runtime or dependency change, run `npm run integrity:update` and review every digest diff. CI runs `npm run integrity:check`; a stale chain fails closed.

The transport dependency is pinned to `follow-redirects` 1.16.1 to preserve
credential stripping across redirects, including array-form headers and custom
header names. Braces has no upstream fix for
[GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm), so all
transitive copies use the reviewed local fork in `vendor/braces`. It rejects
patterns and ASTs beyond 128 levels with `ERR_BRACES_DEPTH`; ordinary globbing
and range limits remain intact. See its `SECURITY-PATCH.md` for provenance and
replacement criteria. The committed npm configuration installs real files so
the fork is bundled and covered by dependency integrity verification.

`npm test` exercises malicious and ordinary patterns through the actual Daytona
SDK and tests redirect handling against local fixtures. The release-candidate
gate repeats security tests against the installed archive and verifies its
integrity before its tamper probe. A zero registry audit is not a substitute for
these local-fork regressions. Live provider certification remains separate.

See [Backend adapter authoring](../../docs/adapter-authoring.md) for the protocol boundary, capability evidence rules, conformance requirements, and promotion gate.

For immutable local release candidates, clean-install verification, rollback,
revocation, and emergency disable procedures, see
[Official adapter distribution](../../docs/official-adapter-distribution.md).
