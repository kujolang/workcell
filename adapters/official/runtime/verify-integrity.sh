#!/usr/bin/env sh
set -eu

ROOT="${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "WorkCell adapter integrity check requires sha256sum or shasum" >&2
    exit 70
  fi
}

verify() {
  relative="$1"
  expected="$2"
  file="$ROOT/$relative"
  if [ ! -f "$file" ] || [ "$(hash_file "$file")" != "$expected" ]; then
    echo "WorkCell adapter integrity check failed: $relative" >&2
    exit 70
  fi
}

verify "runtime/adapter.mjs" "37a2f18269f61e4062f30ffe3d364d45f97abfaae16a6c1423e135a276af4779"
verify "runtime/protocol.mjs" "951efacfef8cd1b2e1c01d7904bfbb64d618d009c55f8678bcb219fe72996bbb"
verify "runtime/providers.mjs" "33e4a1cb873ae85616f2b4b11019dddec6d8e52b7d09a78d840493651c1bf50c"
verify "package.json" "04cd69917becfa912c4bb6ef026dbdcffcaec66eb9159434d7105b04cbdceae1"
verify "package-lock.json" "9549318e90d0b9a48b228f2487b0c79a9f17450f91a88b812792c48544b2b630"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "a1e46b75e78c32fba0fe6279738ed5d82895ab55380f2cf7efc4ec60ad5cc808"
verify "runtime/dependencies.files.gz.b64" "d01feb1ea4879c475677195e7a8616a09e556d2bc0a28c5b3642f54b1f181744"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
