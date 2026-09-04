# Official adapter distribution

The three official remote adapters ship together as
`@kujolang/workcell-official-adapters`. A combined package keeps their shared,
integrity-pinned protocol runtime atomic. Provider SDK versions remain exact in
`package-lock.json`; a provider whose SDK cadence or dependency weight makes the
combined package unsafe may move to an independently versioned package only
after a contract and migration review.

## Build a local release candidate

From `adapters/official`, run:

```bash
npm ci --ignore-scripts
npm run release:candidate -- /absolute/path/outside-the-checkout
```

The output contains an immutable npm archive with bundled provider SDKs,
`SHA256SUMS`, an SPDX SBOM, and a small provenance record. The provenance
explicitly records that no signature was created. Publishing and signing
require separate authorization. The build fails on stale launcher or complete
bundled-dependency integrity, high-severity dependency audit findings, or
SBOM/package errors.

Install the archive with scripts disabled, verify `SHA256SUMS`, and make its
installed tree read-only before selecting a manifest. WorkCell verifies the
manifest, launcher, shared runtime, package metadata, lockfile, and every file
in the bundled provider SDK dependency set before execution. The authenticated,
compressed file manifest is generated from the exact npm archive inclusion set.
The package performs no hidden download and does not require a Kujo service or
hosted registry.

## Compatibility and platforms

Version `0.1.x` implements `workcell-backend/v1alpha1` and requires Node.js 20 or
newer. The launchers are portable POSIX shell and the runtime is JavaScript, so
the candidate targets Linux and macOS on x64 and ARM64. Each target must pass the
clean-install test before promotion; untested targets are not certified.

## Rollback, revocation, and emergency disable

Rollback means restoring a previously retained archive and its matching
checksum/provenance set, then updating the operator-selected manifest path.
Never edit an installed package in place. A revoked digest must be removed from
host profiles and CI secrets, and the affected adapter must be disabled until a
replacement passes conformance and live certification. For an emergency
denylist, operators remove execution permission from the launcher or withdraw
the profile; WorkCell then fails closed before provisioning. Existing owned
resources are handled with the recorded recovery journal and the exact formerly
trusted adapter—never with an unverified replacement.

Uninstall only after inventory proves zero owned resources. Remove the profile,
credential reference, and read-only package tree. Credentials remain provider
or host-secret-store concerns and are rotated or revoked separately.
