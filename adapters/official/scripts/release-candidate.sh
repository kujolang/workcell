#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-$ROOT/dist}"
case "$OUTPUT" in /*) ;; *) OUTPUT="$PWD/$OUTPUT" ;; esac
if [ -L "$OUTPUT" ]; then echo "release candidate output must not be a symlink" >&2; exit 2; fi
case "$OUTPUT" in /|"$ROOT"|"$ROOT"/*) echo "release candidate output must be a dedicated directory outside the package tree" >&2; exit 2 ;; esac
mkdir -p "$OUTPUT"
package_basename="kujolang-workcell-official-adapters-$(node -p 'require("'"$ROOT"'/package.json").version').tgz"
rm -f "$OUTPUT/$package_basename" "$OUTPUT/SHA256SUMS" "$OUTPUT/sbom.spdx.json" "$OUTPUT/provenance.json"

cd "$ROOT"
npm run integrity:check
npm audit --audit-level=high
npm sbom --sbom-format spdx > "$OUTPUT/sbom.spdx.json"
archive="$(npm pack --pack-destination "$OUTPUT" --json | jq -r '.[0].filename')"
(cd "$OUTPUT" && shasum -a 256 "$archive" > SHA256SUMS)
jq -n \
  --arg package "$(node -p 'require("./package.json").name')" \
  --arg version "$(node -p 'require("./package.json").version')" \
  --arg archive "$archive" \
  --arg sha256 "$(shasum -a 256 "$OUTPUT/$archive" | awk '{print $1}')" \
  --arg node "$(node --version)" --arg npm "$(npm --version)" \
  '{schema:"workcell-adapter-provenance/v1",package:$package,version:$version,archive:$archive,sha256:$sha256,builder:{node:$node,npm:$npm},signature:{status:"not-created",reason:"requires explicit authorization"}}' \
  > "$OUTPUT/provenance.json"
printf '%s\n' "$OUTPUT/$archive"
