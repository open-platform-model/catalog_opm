#!/usr/bin/env bash
set -euo pipefail

# openspec-check.sh — check the "Durable decisions" section of every active change.
#
# openspec/config.yaml (operations.archive.guidance) says an archived change is never the
# only home of an authoring rule. This script is the check behind that rule. For each
# openspec/changes/<name>/design.md (the archive is not read):
#
#   1. the "## Durable decisions" section must exist;
#   2. if it is not "None.", it must name a target: a path under docs/ or AGENTS.md, or the
#      words "stays with the change";
#   3. every docs/... path it names in backticks must exist in the tree.
#
# Run from the repo root, or pass the root as the first argument.

export LC_ALL=C

root="${1:-.}"
fail=0

shopt -s nullglob
for design in "$root"/openspec/changes/*/design.md; do
  change="$(basename "$(dirname "$design")")"
  [ "$change" = "archive" ] && continue

  section="$(awk '/^## Durable decisions/{f=1;next} /^## /{f=0} f' "$design")"
  if ! grep -q '^## Durable decisions' "$design"; then
    echo "openspec-check: $change: design.md has no '## Durable decisions' section" >&2
    fail=1
    continue
  fi

  # First non-blank line starting with "None" means nothing is promoted.
  first="$(printf '%s\n' "$section" | grep -v '^[[:space:]]*$' | head -n1 || true)"
  case "$first" in
    None.*|None\ *) continue ;;
    "") echo "openspec-check: $change: 'Durable decisions' is empty; write 'None.' or name a target" >&2
        fail=1
        continue ;;
  esac

  if ! printf '%s\n' "$section" | grep -q -E 'AGENTS\.md|docs/|stays with the change'; then
    echo "openspec-check: $change: 'Durable decisions' names no target (docs/<note>.md, AGENTS.md or 'stays with the change')" >&2
    fail=1
  fi

  while IFS= read -r path; do
    case "$path" in
      *'<'*) continue ;;  # a placeholder such as docs/<note>.md
    esac
    if [ ! -e "$root/$path" ]; then
      echo "openspec-check: $change: 'Durable decisions' names $path, which does not exist" >&2
      fail=1
    fi
  done < <(printf '%s\n' "$section" | grep -o -E '`docs/[^`]+`' | tr -d '`' | sort -u || true)
done

exit "$fail"
