# Official remote backend adapters

These external adapters implement `workcell-backend/v1alpha1` without adding Node or provider SDKs to WorkCell core. Versions are pinned in `package-lock.json`. Install with `npm ci`, then pass the selected `manifest.json` explicitly to WorkCell.

Credentials are references only: `env:E2B_API_KEY`, `env:VERCEL_OIDC_TOKEN`, or `env:DAYTONA_API_KEY`. Values are inherited only by the adapter process and never enter definitions, profiles, receipts, or protocol payloads.

All adapters provide deterministic `fixture_mode` tests without network access. Live tests are opt-in and must prove capability resolution, declared-only export, offline receipt verification, and zero owned resources after cleanup. Conformance is compatibility evidence, not a security certification; receipts record provider controls as provider-claimed unless WorkCell can inspect them.
