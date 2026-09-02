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

verify "runtime/adapter.mjs" "876a8472be19a58746cceeacfe491cf25578827f98e1585eeb63420eec1bf6ad"
verify "runtime/protocol.mjs" "29952a1d72825b11882185cdeb12a2fd6543f19b8352abc127a9c9e2d19cc86a"
verify "runtime/providers.mjs" "33e4a1cb873ae85616f2b4b11019dddec6d8e52b7d09a78d840493651c1bf50c"
verify "package.json" "b288d6d8036fcc83fc1dc7dc2ad3a7001fc09a941a9ef0d6dcd0b65e07df8f86"
verify "package-lock.json" "754da3c337c82cf1fadebd1a8dc8038c93c60447748c6bd38502a5fb68c71794"
