#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KUJO_SOURCE="${1:-}"
KUJO_COMMIT="475fb1a6ee88b53b799cd1a62e5e771516106da8"

if [ -z "$KUJO_SOURCE" ]; then
  echo "usage: $0 /path/to/kujo-source" >&2
  exit 2
fi
if [ ! -d "$KUJO_SOURCE/.git" ]; then
  echo "Kujo source must be a Git checkout: $KUJO_SOURCE" >&2
  exit 2
fi
if [ "$(git -C "$KUJO_SOURCE" rev-parse HEAD)" != "$KUJO_COMMIT" ]; then
  echo "Kujo source must be at commit $KUJO_COMMIT" >&2
  exit 2
fi

CONTEXT="$(mktemp -d)"
cleanup() {
  rm -rf "$CONTEXT"
}
trap cleanup EXIT

git -C "$KUJO_SOURCE" archive --format=tar "$KUJO_COMMIT" | tar -x -C "$CONTEXT"
if docker buildx version >/dev/null 2>&1; then
  docker buildx build --load --tag kujolang/workcell-kujo:local \
    --file "$ROOT/docker/kujo/Dockerfile.local" "$CONTEXT"
else
  docker build --tag kujolang/workcell-kujo:local \
    --file "$ROOT/docker/kujo/Dockerfile.local" "$CONTEXT"
fi
