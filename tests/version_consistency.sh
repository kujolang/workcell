#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
test -n "$VERSION"
grep -Fq "version = \"$VERSION\"" "$ROOT/kujo.toml"
grep -Fq "version = \"$VERSION\"" "$ROOT/kennel.toml"
grep -Fq "## $VERSION" "$ROOT/CHANGELOG.md"

echo "Version consistency passed: $VERSION"
