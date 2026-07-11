#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
TMP_REPO="$(mktemp -d)"
OUT_ROOT="$(mktemp -d)"
SPACE_ROOT="$(mktemp -d)/output with spaces"
mkdir -p "$SPACE_ROOT"
trap 'rm -rf "$TMP_REPO" "$OUT_ROOT" "${SPACE_ROOT%/*}"' EXIT

git -C "$TMP_REPO" init -q
git -C "$TMP_REPO" config user.email workcell@example.invalid
git -C "$TMP_REPO" config user.name Workcell
printf '# Fixture\n' > "$TMP_REPO/README.md"
ln -s /tmp "$TMP_REPO/source-escape"
git -C "$TMP_REPO" add README.md source-escape
git -C "$TMP_REPO" commit -qm symlink-fixture

set +e
SYMLINK_OUTPUT="$($KUJO run "$ROOT/main.kujo" -- run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/source" --json 2>/dev/null)"
SOURCE_CODE=$?
set -e
test "$SOURCE_CODE" -eq 3
printf '%s' "$SYMLINK_OUTPUT" | jq -e '.stage == "preparing" and (.error | contains("symlink"))' >/dev/null

git -C "$TMP_REPO" rm -q source-escape
git -C "$TMP_REPO" commit -qm clean-fixture
ln -s /tmp "$OUT_ROOT/output-link"

set +e
OUTPUT_RESULT="$($KUJO run "$ROOT/main.kujo" -- run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "$OUT_ROOT/output-link" --json 2>/dev/null)"
OUTPUT_CODE=$?
set -e
test "$OUTPUT_CODE" -eq 3
printf '%s' "$OUTPUT_RESULT" | jq -e '.stage == "preparing" and (.error | contains("symlink"))' >/dev/null

set +e
TRAVERSAL_RESULT="$($KUJO run "$ROOT/main.kujo" -- run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "../output-escape" --json 2>/dev/null)"
TRAVERSAL_CODE=$?
set -e
test "$TRAVERSAL_CODE" -eq 3
printf '%s' "$TRAVERSAL_RESULT" | jq -e '.stage == "preparing" and (.error | contains("parent traversal"))' >/dev/null

"$KUJO" run "$ROOT/main.kujo" -- run --file "$ROOT/examples/hello/workcell.json" --repo "$TMP_REPO" --output "$SPACE_ROOT" --dry-run --json >/dev/null

echo "Path-safety tests passed"
