#!/usr/bin/env bash
# Runs the pre-commit hook inside a throwaway repository and checks the stamp.
set -euo pipefail

hook="$(cd "$(dirname "$0")" && pwd)/pre-commit"
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT

fail() { echo "FAIL: $1"; exit 1; }

write_skill() {
  mkdir -p "$repo/workflow/skills/$1"
  printf -- "---\nname: %s\nmetadata:\n  author: x\n%s---\nbody\n" "$1" "$2" \
    > "$repo/workflow/skills/$1/SKILL.md"
}

version_of() {
  grep '^  version: ' "$repo/workflow/skills/$1/SKILL.md" | awk '{print $2}'
}

setup_repo() {
  git -C "$repo" init -q
  git -C "$repo" config user.email t@t; git -C "$repo" config user.name t
  git -C "$repo" config core.hooksPath "$(dirname "$hook")"
  write_skill one "  version: old\n"
  write_skill two ""
  git -C "$repo" add -A && git -C "$repo" commit -qm base
}

test_stamps_staged_only() {
  local base; base=$(git -C "$repo" rev-parse --short HEAD)
  echo change >> "$repo/workflow/skills/one/SKILL.md"
  git -C "$repo" add -A && git -C "$repo" commit -qm change
  [ "$(version_of one)" = "$base" ] || fail "one not stamped with $base"
  [ -z "$(version_of two)" ] || fail "two stamped without change"
}

test_adds_missing_line() {
  local base; base=$(git -C "$repo" rev-parse --short HEAD)
  echo change >> "$repo/workflow/skills/two/SKILL.md"
  git -C "$repo" add -A && git -C "$repo" commit -qm change
  [ "$(version_of two)" = "$base" ] || fail "two missing version line"
  git -C "$repo" diff --quiet HEAD || fail "stamp left the tree dirty"
}

setup_repo
test_stamps_staged_only
test_adds_missing_line
echo "ok"
