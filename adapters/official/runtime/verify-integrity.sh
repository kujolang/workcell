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
verify "runtime/protocol.mjs" "9764630072a9fd2ac658f18ff94ac0f6192c567dbeeaa71aa1f7f4613f29374c"
verify "runtime/providers.mjs" "33e4a1cb873ae85616f2b4b11019dddec6d8e52b7d09a78d840493651c1bf50c"
verify "package.json" "546f3358ad441f0c6f2d7ea1fb5eb111db01be2700a86a40bc9f88bd492112cb"
verify "package-lock.json" "82cc08ae5ca3919f5bf8c3cc9c4c8707d93a0b0d3f8dfc0383acfd31c5f496a6"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "6b8a74441f21aa837c80100fa35584563884afe6e40ad29212b4b523ef7e58ee"
verify "runtime/dependencies.files.gz.b64" "ee8137761bd8b1c9184b8dc4fc6eb1fae768cc81b6a4a9254d49d5833cd034fe"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
