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
verify "runtime/protocol.mjs" "46d77642de72001007f09176c61412399c19185f6129911ff0b72ed571d445ed"
verify "runtime/providers.mjs" "fad2fd5761e2530d42b39a39c9c4db30e112a8bf9f3bf67e972475c4b2b4eda3"
verify "package.json" "ea3908a7121abd8115b3826a01edb26f4b78b5a430b710ca852ae513c0ad51cd"
verify "package-lock.json" "754da3c337c82cf1fadebd1a8dc8038c93c60447748c6bd38502a5fb68c71794"
