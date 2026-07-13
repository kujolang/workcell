#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

while IFS= read -r -d '' file; do
  "$KUJO" format --check "$ROOT/$file" >/dev/null
done < <(cd "$ROOT" && find . -type f -name '*.kujo' -not -path './.git/*' -print0 | sort -z)

while IFS= read -r -d '' file; do
  findings="$($KUJO lint --json "$ROOT/$file")"
  test "$(printf '%s' "$findings" | jq 'length')" -eq 0
done < <(cd "$ROOT" && find src -type f -name '*.kujo' -print0 | sort -z)

while IFS= read -r -d '' file; do
  bash -n "$ROOT/$file"
done < <(cd "$ROOT" && find tests bin docker -type f -name '*.sh' -print0 | sort -z)

git -C "$ROOT" diff --check
echo "Quality gates passed"
