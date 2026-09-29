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
verify "package.json" "f636705b0db3ef4e73ff7a9f10714ea24c498f8a271a004283da2534159b48c7"
verify "package-lock.json" "bc49e3a26c07eb080604d45cc6c670ad8f450462463c2ef1d40cfc926e0d9478"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "07629fccf6e579d3841b78c41e33f6c17c3748b0c00ee6e7523471ce9261c65e"
verify "runtime/dependencies.files.gz.b64" "3b0edc6d9fe93e1bb09320c5f2038072ae085d6392bb587400613a9fbb860955"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
