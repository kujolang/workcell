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
verify "runtime/protocol.mjs" "5b57df387aa60578cdfcf85d279f936410be21bd9df0702e47179c42a23d9e0e"
verify "runtime/providers.mjs" "33e4a1cb873ae85616f2b4b11019dddec6d8e52b7d09a78d840493651c1bf50c"
verify "package.json" "902114a7991d193de79e1d3b8d734b1a9fea094b3948e062da02a8601a3c46a9"
verify "npm-shrinkwrap.json" "28cde6df1588dfb3553af922bc0cdbbd4533a0d4e92866cc9ef92925f14577da"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "cd3c2eca4d0e79963eee17a5a089673fa22d071f1ed1d2523340ccc70ed2fe4d"
verify "runtime/dependencies.files.gz.b64" "3a0917b38ee18d988ec03fea9c59b0232c3e0c68bb0974cdb12040be241e18cb"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
