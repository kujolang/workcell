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
verify "runtime/protocol.mjs" "951efacfef8cd1b2e1c01d7904bfbb64d618d009c55f8678bcb219fe72996bbb"
verify "runtime/providers.mjs" "33e4a1cb873ae85616f2b4b11019dddec6d8e52b7d09a78d840493651c1bf50c"
verify "package.json" "e91582bbbd214281ec29371156d5ff4824947ff116102eba0d6b6fd4ef2ab637"
verify "package-lock.json" "47a7eedd0cc3376230842d10220c5c4b0186dfd95b8568e9bae5dc6eeebbab62"
verify "runtime/verify-dependencies.mjs" "8ee29df092ff814d18c3dd92afc1601608949ba43695d9187890ae0c4a687b16"
verify "runtime/dependencies.sha256" "2735436c1a089cd5f427995651fd11d68b99e79d57721152e3ea58bc262fbadd"
verify "runtime/dependencies.files.gz.b64" "d01feb1ea4879c475677195e7a8616a09e556d2bc0a28c5b3642f54b1f181744"
node "$ROOT/runtime/verify-dependencies.mjs" "$ROOT"
