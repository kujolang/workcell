#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-kujo}"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
RELEASED_KUJO_COMMIT="692512a9070fdba713f160d795bbddb8077db7b5"

toml_value() {
  local file="$1"
  local section="$2"
  local key="$3"
  awk -v section="[$section]" -v key="$key" '
    $0 == section { active = 1; next }
    active && /^\[/ { active = 0 }
    active && $0 ~ "^" key "[[:space:]]*=" {
      value = $0
      sub("^[^=]*=[[:space:]]*", "", value)
      gsub(/^\"|\"$/, "", value)
      print value
    }
  ' "$file"
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
test "$(toml_value "$ROOT/kujo.toml" package version)" = "$VERSION"
test "$(toml_value "$ROOT/kennel.toml" package version)" = "$VERSION"
test "$(toml_value "$ROOT/kennel.toml" package.status stage)" = "production"
test "$(toml_value "$ROOT/kennel.toml" package.status stability)" = "stable"
test "$(toml_value "$ROOT/kennel.toml" package.status public_api)" = "true"
test "$(toml_value "$ROOT/kennel.toml" kujo minimum_version)" = "1.2.1"
grep -Eq "^## ${VERSION} - [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$ROOT/CHANGELOG.md"
grep -Fq "version-${VERSION}" "$ROOT/README.md"
grep -Fq "workcell-${VERSION}-source.tar.gz" "$ROOT/docs/release-process.md"
grep -Fq "workcell-${VERSION}-checksums.txt" "$ROOT/docs/release-process.md"

KUJO_COMMIT="$(tr -d '[:space:]' < "$ROOT/RUNTIME_VERSION")"
test "$KUJO_COMMIT" = "$RELEASED_KUJO_COMMIT"
test "$(grep -Fc "ARG KUJO_COMMIT=$KUJO_COMMIT" "$ROOT/docker/kujo/Dockerfile")" -eq 1
test "$(grep -Fc "ARG KUJO_COMMIT=$KUJO_COMMIT" "$ROOT/docker/kujo/Dockerfile.local")" -eq 1
test "$(grep -Fc "KUJO_COMMIT=\"$KUJO_COMMIT\"" "$ROOT/docker/kujo/build-local.sh")" -eq 1

test "$(KUJO="$KUJO" "$ROOT/bin/workcell" --version)" = "Workcell $VERSION"
test "$("$KUJO" --version)" = "kujo 1.2.1"

echo "Version consistency passed: Workcell $VERSION on Kujo $KUJO_COMMIT"
