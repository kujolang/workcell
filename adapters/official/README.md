# Official remote backend adapters

These external adapters implement `workcell-backend/v1alpha1` without adding Node or provider SDKs to WorkCell core. Versions are pinned in `package-lock.json`. Install with `npm ci`, then pass the selected `manifest.json` explicitly to WorkCell.

Credentials are references only: `env:E2B_API_KEY`, `env:VERCEL_OIDC_TOKEN`, or `env:DAYTONA_API_KEY`. Values are inherited only by the adapter process and never enter definitions, profiles, receipts, or protocol payloads.

All adapters provide deterministic `fixture_mode` tests without network access. Live tests are opt-in and must prove capability resolution, declared-only export, offline receipt verification, and zero owned resources after cleanup. Conformance is compatibility evidence, not a security certification; receipts record provider controls as provider-claimed unless WorkCell can inspect them.

Official manifests pin the launcher digest. Each launcher pins a verifier that checks the shared runtime, `package.json`, and `package-lock.json` before Node starts. Production installations must use `npm ci` from the committed lockfile and make the installed adapter tree read-only. The integrity chain detects local file changes; it does not authenticate a distribution channel or prove that a mutable `node_modules` tree matches the lockfile.
