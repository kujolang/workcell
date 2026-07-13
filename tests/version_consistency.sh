#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
test -n "$VERSION"
grep -Fq "version = \"$VERSION\"" "$ROOT/kujo.toml"
grep -Fq "version = \"$VERSION\"" "$ROOT/kennel.toml"
grep -Fq "## $VERSION" "$ROOT/CHANGELOG.md"

KUJO_COMMIT="$(tr -d '[:space:]' < "$ROOT/RUNTIME_VERSION")"
test "${#KUJO_COMMIT}" -eq 40
grep -Fq "ARG KUJO_COMMIT=$KUJO_COMMIT" "$ROOT/docker/kujo/Dockerfile"
grep -Fq "ARG KUJO_COMMIT=$KUJO_COMMIT" "$ROOT/docker/kujo/Dockerfile.local"
grep -Fq "KUJO_COMMIT=\"$KUJO_COMMIT\"" "$ROOT/docker/kujo/build-local.sh"

echo "Version consistency passed: $VERSION"
