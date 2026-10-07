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
verify "package-lock.json" "7b87de436027e0a4820cd6f6eb5c90bbb88af26a1ae65617cfd4cbe841a0a096"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "6b8a74441f21aa837c80100fa35584563884afe6e40ad29212b4b523ef7e58ee"
verify "runtime/dependencies.files.gz.b64" "8b86830b3c84725efb120c3adebb052523c907bbaab034491671c08b0a24de4f"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
