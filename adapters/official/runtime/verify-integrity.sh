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
verify "runtime/providers.mjs" "faede2c15c27abcd54f0d8f56442e94d250578dd7842be27684bc7cfddb47b75"
verify "package.json" "f00a008062bbea84c483b14c818e5f24b32ee6f9759b45e9072b678fdb5ca910"
verify "npm-shrinkwrap.json" "1d1bf26cf6f2479612e466dbdb83b2a21d49b61632a2cf9b458b196774eab28c"
verify "runtime/verify-dependencies.mjs" "f1a0a4281116850cb1a18e8176fa8436ca2ec4d352c52f1126c8d34f449766dc"
verify "runtime/dependencies.sha256" "dfa572c86c96758588657fb618f3113101c7c949364bfa31b304fc9115c595c0"
verify "runtime/dependencies.files.gz.b64" "7f20e66eb6a3cccb417819cc7916118c9fb1df99c681ac4222dcafd036752978"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
