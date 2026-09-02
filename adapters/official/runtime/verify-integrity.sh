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

verify "runtime/adapter.mjs" "4cab815f621c49a93e896b5c0b35c52f47200454a120de908a27a011f46591c2"
verify "runtime/protocol.mjs" "0c7be40ab69ac6946aae5f96b20e13d6ec9a771bc1e5713c9ac5071ecf2014e7"
verify "runtime/providers.mjs" "fad2fd5761e2530d42b39a39c9c4db30e112a8bf9f3bf67e972475c4b2b4eda3"
verify "package.json" "b288d6d8036fcc83fc1dc7dc2ad3a7001fc09a941a9ef0d6dcd0b65e07df8f86"
verify "package-lock.json" "754da3c337c82cf1fadebd1a8dc8038c93c60447748c6bd38502a5fb68c71794"
