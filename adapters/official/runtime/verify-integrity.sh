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
verify "runtime/protocol.mjs" "a2eefa118819da0621631ff198ace6f59109c6db4700d47fc4b7776f5368f1e2"
verify "runtime/providers.mjs" "33e4a1cb873ae85616f2b4b11019dddec6d8e52b7d09a78d840493651c1bf50c"
verify "package.json" "5bf090bd408eb564b9a2a547a01e6b787d50e00574a427179c69fd6c82305dbb"
verify "npm-shrinkwrap.json" "0e25993ae9e683a0d47a62f92ebb45e461e0c9788759591de6f8371ef9549824"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "851171fdca337cea2ac6b2e69d1763bd49e74747a3d2ab84a72e120689542b2e"
verify "runtime/dependencies.files.gz.b64" "7f20e66eb6a3cccb417819cc7916118c9fb1df99c681ac4222dcafd036752978"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
