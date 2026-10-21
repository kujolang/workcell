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
verify "package.json" "ad7057347391a5a998441feec6bdb978b7f2358e1c828fd3dc63a1b519300a8c"
verify "npm-shrinkwrap.json" "0281f00439431ec6294ecf911a265a67fa818c1acdfcb990045f56d7a82c950a"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "64d24b0dc1165ad151076a51bc4a390dd56676c387c8ab6337ed700e17acf0a4"
verify "runtime/dependencies.files.gz.b64" "5a5b3c3310da1304edc62ff3b44803a6ad3a242b66d68967c9d64a5c528b5b61"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
