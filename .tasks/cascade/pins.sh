#!/usr/bin/env bash
# Report catalog_opm's upstream pins at a ref (Phase 2 cascade contract §4.1, §6.1).
#
# Usage: pins.sh WORKTREE|<git ref>
#   WORKTREE reads the files on disk; anything else is a git ref read with `git show`.
#
# Prints one TSV line per pin, core first:
#   <pin-key> <display> <class> <version> <labels>
# A pin whose file (or, for core, whose key) is missing at the ref is omitted.
# Exit 0, or 1 on error (unknown ref, unparsable version).
set -euo pipefail

die() { printf 'pins.sh: %s\n' "$1" >&2; exit 1; }

[ $# -eq 1 ] || die "usage: pins.sh WORKTREE|<git ref>"
ref="$1"
top=$(git rev-parse --show-toplevel)
cd "$top"

CORE_FILE=src/cue.mod/module.cue
CORE_KEY=opmodel.dev/core@v2
CLI_FILE=.opm-cli-version
CLI_KEY=github.com/open-platform-model/cli
# Contract §2.2: a valid version.
SEMVER='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'
# The shape CI accepts for .opm-cli-version (ci.yml, "Read the pinned opm CLI version").
CLI_SHAPE='^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$'

if [ "$ref" != WORKTREE ]; then
  git rev-parse -q --verify "$ref^{commit}" >/dev/null || die "unknown ref: $ref"
fi

# has FILE: exit 0 when FILE exists at the ref.
has() {
  if [ "$ref" = WORKTREE ]; then
    [ -f "$1" ]
  else
    [ -n "$(git ls-tree --name-only "$ref" -- "$1")" ]
  fi
}

# content FILE: print FILE at the ref.
content() {
  if [ "$ref" = WORKTREE ]; then cat "$1"; else git show "$ref:$1"; fi
}

if has "$CORE_FILE"; then
  mod=$(content "$CORE_FILE")
  if grep -qF "\"$CORE_KEY\"" <<<"$mod"; then
    v=$(grep -FA5 "\"$CORE_KEY\"" <<<"$mod" | grep -m1 -oP 'v:\s*"\K[^"]+') \
      || die "$CORE_FILE at $ref: no v: under \"$CORE_KEY\""
    [[ "$v" =~ $SEMVER ]] || die "$CORE_FILE at $ref: \"$CORE_KEY\" pins a malformed version: $v"
    printf '%s\t%s\t%s\t%s\t%s\n' "$CORE_KEY" core shipped "$v" ""
  fi
fi

if has "$CLI_FILE"; then
  cli=$(content "$CLI_FILE")
  [[ "$cli" =~ $CLI_SHAPE ]] || die "$CLI_FILE at $ref is not one line holding a CLI tag: $cli"
  printf '%s\t%s\t%s\t%s\t%s\n' "$CLI_KEY" "opm CLI" release-tool "$cli" ""
fi
