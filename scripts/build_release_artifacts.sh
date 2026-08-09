#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-}"
REPORT_PATH="${2:-}"
SOURCE_REF="${3:-HEAD}"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
RUNTIME_COMMIT="$(tr -d '[:space:]' < "$ROOT/RUNTIME_VERSION")"

if [ -z "$OUTPUT_DIR" ] || [ -z "$REPORT_PATH" ]; then
  echo "usage: $0 OUTPUT_DIR RELEASE_REPORT_JSON [GIT_REF]" >&2
  exit 2
fi
if [ -e "$OUTPUT_DIR" ]; then
  echo "release output already exists: $OUTPUT_DIR" >&2
  exit 2
fi
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION is not semantic versioning: $VERSION" >&2
  exit 2
fi
if [ "$(git -C "$ROOT" show "$SOURCE_REF:VERSION" | tr -d '[:space:]')" != "$VERSION" ]; then
  echo "release ref VERSION does not match $VERSION" >&2
  exit 2
fi
jq -e --arg version "$VERSION" '.ok == true and .workcell_version == $version and .schema_version == "workcell-report/v1"' "$REPORT_PATH" >/dev/null

ARCHIVE="workcell-${VERSION}-source.tar.gz"
REPORT="workcell-${VERSION}-release-report.json"
PROVENANCE="workcell-${VERSION}-provenance.json"
CHECKSUMS="workcell-${VERSION}-checksums.txt"
COMMIT="$(git -C "$ROOT" rev-parse "$SOURCE_REF^{commit}")"

mkdir "$OUTPUT_DIR"
git -C "$ROOT" archive --format=tar --prefix="workcell-${VERSION}/" "$SOURCE_REF" | gzip -n > "$OUTPUT_DIR/$ARCHIVE"
cp "$REPORT_PATH" "$OUTPUT_DIR/$REPORT"

archive_sha="$(shasum -a 256 "$OUTPUT_DIR/$ARCHIVE" | awk '{print $1}')"
report_sha="$(shasum -a 256 "$OUTPUT_DIR/$REPORT" | awk '{print $1}')"
jq -n \
  --arg version "$VERSION" \
  --arg tag "v$VERSION" \
  --arg commit "$COMMIT" \
  --arg runtime_commit "$RUNTIME_COMMIT" \
  --arg archive "$ARCHIVE" \
  --arg archive_sha256 "$archive_sha" \
  --arg report "$REPORT" \
  --arg report_sha256 "$report_sha" \
  '{schema_version:"workcell-release-provenance/v1",product:"Workcell",version:$version,tag:$tag,commit:$commit,kujo_runtime_commit:$runtime_commit,source_archive:$archive,source_archive_sha256:$archive_sha256,release_report:$report,release_report_sha256:$report_sha256}' \
  > "$OUTPUT_DIR/$PROVENANCE"

(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$ARCHIVE" "$REPORT" "$PROVENANCE" > "$CHECKSUMS"
  shasum -a 256 -c "$CHECKSUMS"
)

printf '%s\n' "$OUTPUT_DIR/$ARCHIVE" "$OUTPUT_DIR/$REPORT" "$OUTPUT_DIR/$PROVENANCE" "$OUTPUT_DIR/$CHECKSUMS"
