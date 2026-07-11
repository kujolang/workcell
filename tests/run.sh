#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"

check_all() {
  "$KUJO" check "$ROOT/main.kujo"
  while IFS= read -r file; do
    "$KUJO" check "$ROOT/$file"
  done < <(cd "$ROOT" && find src -type f -name '*.kujo' | sort)
  "$KUJO" check "$ROOT/tests/workcell_test.kujo"
}

if [ "${1:-}" = "--check-only" ]; then
  check_all
  exit 0
fi

check_all
"$KUJO" run "$ROOT/tests/workcell_test.kujo"
