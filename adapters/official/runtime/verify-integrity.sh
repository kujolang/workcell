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

verify "runtime/adapter.mjs" "7101ddd1990cb15c0026506c4675f5ca47f2d8449642c796132729a9ad856100"
verify "runtime/protocol.mjs" "3db6e67bd25f0f3006cca6025496be043091844e4060b368ad3de5f8ccf7b9d3"
verify "runtime/providers.mjs" "fad2fd5761e2530d42b39a39c9c4db30e112a8bf9f3bf67e972475c4b2b4eda3"
verify "package.json" "ea3908a7121abd8115b3826a01edb26f4b78b5a430b710ca852ae513c0ad51cd"
verify "package-lock.json" "754da3c337c82cf1fadebd1a8dc8038c93c60447748c6bd38502a5fb68c71794"
