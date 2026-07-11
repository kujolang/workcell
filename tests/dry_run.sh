#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP_REPO="$(mktemp -d)"
OUT_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_REPO" "$OUT_ROOT"' EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Fixture\n' > "$TMP_REPO/README.md"
git -C "$TMP_REPO" add README.md
git -C "$TMP_REPO" commit -qm initial

"$KUJO" run "$ROOT/main.kujo" -- run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT" --dry-run --json > "$OUT_ROOT/result.json"
test "$(jq -r '.ok' "$OUT_ROOT/result.json")" = true
receipt="$(jq -r '.receipt_path' "$OUT_ROOT/result.json")"
jq -e '.final_status == "dry-run" and .elapsed_ms >= 0 and (.lifecycle | contains(["cleaning", "cleaned"])) and .verification.execution_succeeded == false and .verification.artifacts_exported == false' "$receipt" >/dev/null
workspace="$(jq -r '.workspace_path' "$receipt")"
test ! -e "$workspace"
test ! -e "$workspace.owner"
echo "Dry-run lifecycle tests passed"
