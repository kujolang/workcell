#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
npm ci --ignore-scripts --prefix "$ROOT/adapters/official"
archive="$("$ROOT/adapters/official/scripts/release-candidate.sh" "$TMP/dist" | tail -1)"
(cd "$TMP/dist" && shasum -a 256 -c SHA256SUMS)
jq -e '.spdxVersion and .packages' "$TMP/dist/sbom.spdx.json" >/dev/null
jq -e '.schema == "workcell-adapter-provenance/v1" and .signature.status == "not-created"' "$TMP/dist/provenance.json" >/dev/null
mkdir -p "$TMP/install"
npm install --ignore-scripts --no-audit --no-fund --prefix "$TMP/install" "$archive"
package_root="$TMP/install/node_modules/@kujolang/workcell-official-adapters"
for provider in e2b vercel-sandbox daytona; do
  executable="$package_root/$provider/workcell-backend-$provider"
  test -x "$executable"
  expected="$(jq -r '.digest | sub("^sha256:"; "")' "$package_root/$provider/manifest.json")"
  actual="$(shasum -a 256 "$executable" | awk '{print $1}')"
  test "$expected" = "$actual"
done
printf 'Official adapter release candidate passed clean-install and integrity checks.\n'
