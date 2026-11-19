#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/fragments.sh
. scripts/release-rewrite.sh
version="${1:-}"
number='(0|[1-9][0-9]*)'
if ! [[ "$version" =~ ^$number\.$number\.$number$ ]]; then
  echo "usage: scripts/release-commit.sh X.Y.Z" >&2
  exit 1
fi
last="$(last_tag)"
base="${last:-v0.0.0}"
if ! awk -v next_version="$version" -v last="${base#v}" 'BEGIN {
  split(next_version, a, ".")
  split(last, b, ".")
  for (i = 1; i <= 3; i++) {
    if (a[i] + 0 > b[i] + 0) exit 0
    if (a[i] + 0 < b[i] + 0) exit 1
  }
  exit 1
}'; then
  if [ -n "$last" ]; then
    echo "$version is not above the last release $last" >&2
  else
    echo "$version is not above 0.0.0, where the first release counts from" >&2
  fi
  exit 1
fi
pending="$(pending_fragments "$last")"
if [ -z "$pending" ]; then
  echo "no fragment in changes/ is pending since ${last:-the first commit}; nothing to release" >&2
  exit 1
fi
bullets="$(
  while IFS= read -r file; do
    fragment_kind "$file" >/dev/null || exit 1
    fragment_bullets "$file"
  done <<<"$pending"
)"
refuse_repeats "$last" "$pending"
released=""
if [ -n "$last" ]; then
  released="$(git show "$last:CHANGELOG.md" | awk '/^## / { found = 1 } found')"
fi
manifest="$(manifest_with_version "$version" Cargo.toml)"
lock="$(lock_with_version "$version" Cargo.lock)"
if ! manifest_reads "$version" "$manifest"; then
  echo "Cargo.toml: the version of [package] does not read $version after the rewrite" >&2
  exit 1
fi
if ! lock_reads "$version" "$lock"; then
  echo "Cargo.lock: the version of the {{name}} entry does not read $version after the rewrite" >&2
  exit 1
fi
kept="$(mktemp -d "${TMPDIR:-/tmp}/release-commit.XXXXXX")"
trap 'rm -rf "$kept"' EXIT
cp Cargo.toml Cargo.lock "$kept/"
restore() {
  cp "$kept/Cargo.toml" "$kept/Cargo.lock" .
  echo "$1" >&2
  exit 1
}
printf '%s\n' "$manifest" >Cargo.toml
printf '%s\n' "$lock" >Cargo.lock
built="$(grep -m1 '^version = ' Cargo.toml | cut -d'"' -f2)" || built=""
if [ "$built" != "$version" ]; then
  restore "Cargo.toml: the release build reads the version $built after the rewrite, not $version, so it would refuse the tag"
fi
if command -v cargo >/dev/null 2>&1; then
  package="$(cargo metadata --no-deps --offline --format-version 1 2>/dev/null | root_package "$(pwd -P)")" || package=""
  if [ "$package" != "{{name}} $version" ]; then
    restore "Cargo.toml: cargo does not read the package version $version after the rewrite"
  fi
fi
printf '# Changelog\n\n## v%s (%s)\n%s\n%s' "$version" "$(date -u +%Y-%m-%d)" "${bullets:-- v$version: internal changes only.}" "${released:+$'\n'$released$'\n'}" >CHANGELOG.md
