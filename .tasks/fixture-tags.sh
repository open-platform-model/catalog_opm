#!/usr/bin/env bash
set -euo pipefail

# See generate-index.sh for the rationale — pin to C so the enumeration order
# below is byte-stable across locales.
export LC_ALL=C

# fixture-tags.sh — keep every fixture of one CUE module behind the fixtures tag.
#
# Fixtures (top-level hidden fields named `_test*`) live in files that open
# with the file attribute `@if(fixtures)` above the package clause, by
# convention `<name>_fixtures.cue` beside the member's own file. A plain build
# — a consumer, an editor, `cue vet ./...` — leaves those files out, and
# `-t fixtures` loads them (`task vet`, `task vet:fixtures`). A `_test*` field
# in an untagged file would be evaluated by every consumer of the package and
# would slip out of the tagged checks' view of where fixtures live.
#
# WHY not a `_test.cue` suffix: the cue CLI has no test mode. `cue vet ./...`
# silently drops `x_test.cue` files, so fixtures there would never be checked.
#
# WHY the attribute line is anchored: `// @if(fixtures)` is a comment and a
# compound such as `@if(fixtures && x)` builds the file under other
# conditions; neither counts as tagged. A trailing `// comment` is allowed.
#
# Usage (run from the repo root):
#   bash .tasks/fixture-tags.sh <module_dir>      # src
#
# Reads text only: no registry, no cue. Exits 0 when every file declaring a
# top-level `_test*` field is tagged, 1 otherwise, naming each untagged file.

MODULE="${1:?Error: module argument required. Usage: bash .tasks/fixture-tags.sh src}"
MODULE="${MODULE%/}"

[[ -f "$MODULE/cue.mod/module.cue" ]] \
    || { echo "Error: $MODULE/cue.mod/module.cue not found (run from the repo root)" >&2; exit 1; }

files=0
bad=0
while IFS= read -r file; do
    files=$((files + 1))
    # The attribute must come before the package clause to be a file attribute.
    if ! awk '
        /^package[[:space:]]/ { exit }
        /^@if\(fixtures\)[[:space:]]*(\/\/.*)?$/ { found = 1; exit }
        END { exit !found }
    ' "$file"; then
        bad=$((bad + 1))
        echo "FAIL: $file declares a top-level _test* field but has no @if(fixtures) line above its package clause" >&2
    fi
done < <(grep -rlE '^_test[A-Za-z0-9_]*[!?]?:' "$MODULE" --include='*.cue' --exclude-dir=cue.mod | sort)

if (( bad > 0 )); then
    echo "FAIL: $MODULE — $bad of $files files with fixtures are not behind the fixtures tag. Move the fields into <name>_fixtures.cue, which opens with @if(fixtures)." >&2
    exit 1
fi

echo "OK: $MODULE — all $files files with fixtures carry @if(fixtures)."
