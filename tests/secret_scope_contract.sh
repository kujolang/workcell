#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.name workcell-secret-scope
git -C "$repo" config user.email workcell-secret-scope@example.invalid
printf 'fixture\n' > "$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -qm fixture
jq '.secrets=["WORKCELL_SECRET_SCOPE_CANARY"]' "$ROOT/tests/fixtures/portable/workcell.json" > "$TMP/workcell.json"
jq '.profiles.fixture.adapter_options["external-fixture"].require_execute_secret=true' "$ROOT/tests/fixtures/portable/profiles.json" > "$TMP/profiles.json"
WORKCELL_SECRET_SCOPE_CANARY="scope-secret-value" "$KUJO" run "$ROOT/main.kujo" -- run --file "$TMP/workcell.json" --repo "$repo" --output "$TMP/output" --manifest "$ROOT/tests/fixtures/backend-protocol/manifest.json" --profiles "$TMP/profiles.json" --profile fixture --summary > "$TMP/result.json"
jq -e '.ok == true and .cleanup_status == "complete"' "$TMP/result.json" >/dev/null
printf 'Adapter workload secrets are scoped to execute only.\n'
