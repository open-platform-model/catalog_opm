#!/usr/bin/env bash
set -euo pipefail

# openspec-check-test.sh — test openspec-check.sh on sandbox trees. Each case builds one
# active change and states whether the check must pass (0) or fail (1).

here="$(cd "$(dirname "$0")" && pwd)"
check="$here/openspec-check.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
n=0
bad=0

# run_case <name> <expected exit> <design.md text>; the tree also holds docs/real.md and references/real.md.
run_case() {
  local name="$1" want="$2" text="$3" dir="$tmp/case$n"
  n=$((n + 1))
  mkdir -p "$dir/openspec/changes/c" "$dir/docs" "$dir/references"
  : > "$dir/docs/real.md"
  : > "$dir/references/real.md"
  printf '%s\n' "$text" > "$dir/openspec/changes/c/design.md"
  local got=0
  bash "$check" "$dir" >/dev/null 2>&1 || got=$?
  if [ "$got" != "$want" ]; then
    echo "openspec-check-test: FAIL $name: want exit $want, got $got" >&2
    bad=1
  fi
}

run_case "missing section" 1 $'## Context\n\nx'
run_case "unfilled template (comment only)" 1 $'## Durable decisions\n\n<!-- Every decision, and where it lands:\n     docs/<note>.md, a references/<topic>.md rule, or "stays with the change". Write "None." if empty. -->'
run_case "None." 0 $'## Durable decisions\n\nNone.'
run_case "stays with the change" 0 $'## Durable decisions\n\n- A pitfall. It stays with the change.'
run_case "existing path in backticks" 0 $'## Durable decisions\n\n- Lands in `docs/real.md`.'
run_case "missing path in backticks" 1 $'## Durable decisions\n\n- Lands in `docs/missing.md`.'
run_case "existing path without backticks" 0 $'## Durable decisions\n\n- Lands in docs/real.md.'
run_case "missing path without backticks" 1 $'## Durable decisions\n\n- Lands in docs/missing.md, later.'
run_case "existing reference path" 0 $'## Durable decisions\n\n- Lands in `references/real.md`.'
run_case "missing reference path" 1 $'## Durable decisions\n\n- Lands in `references/missing.md`.'
run_case "no target named" 1 $'## Durable decisions\n\n- A rule that matters.'

if [ "$bad" = 0 ]; then
  echo "OK: openspec-check.sh passes its $n cases."
fi
exit "$bad"
