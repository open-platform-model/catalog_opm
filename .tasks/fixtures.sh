#!/usr/bin/env bash
set -euo pipefail

# See generate-index.sh for the rationale — pin to C so the enumeration order
# below is byte-stable across locales.
export LC_ALL=C

# fixtures.sh — check every RENDERED-OUTPUT fixture of one CUE module.
#
# A rendered-output fixture is a hidden field declared as the `.output` of a
# transformer's `#transform`:
#
#     _test<Name>: (#<Transformer>.#transform & { … }).output
#
# Its golden literal is unified onto the same field, so the literal only
# compares something when the field actually evaluates to a concrete value.
#
# WHY cue export and not cue vet: `cue vet` — including `cue vet -c` — does not
# check hidden fields, and an incomplete value is not an error, so a fixture
# whose inputs no longer make the output concrete passes vet while comparing
# nothing. Measured 2026-09-15 (cue v0.17.1, core v2.0.0-alpha.9): 44 of the 47
# rendered-output fixtures in opm/transformers/ failed export while `cue vet
# ./...` exited 0. `cue export -e <field>` forces concreteness and is what makes
# the golden literals load-bearing. See AGENTS.md, Working Style.
#
# WHY only this declaration form: sweeping every hidden `_test*` field reports
# ~92 failures in opm, most of them component fixtures (`_test*Component`) whose
# attached primitives carry schemas and are non-concrete BY DESIGN. A gate with
# 90 known-acceptable failures is a gate nobody reads. The selector keys on the
# `#transform` form a fixture must already use to render anything, not on a
# naming convention, so renaming a fixture keeps it covered.
#
# Usage (run from the repo root):
#   bash .tasks/fixtures.sh <module>          # opm | k8s
#
# Reports each failure as `<file>: <field>` plus CUE's own first error line.
# Exits 0 when every fixture evaluates, 1 otherwise. A module with no
# transformers/ directory has nothing to check and exits 0.

MODULE="${1:?Error: module argument required. Usage: bash .tasks/fixtures.sh opm}"
MODULE="${MODULE%/}"

[[ -f "$MODULE/cue.mod/module.cue" ]] \
    || { echo "Error: $MODULE/cue.mod/module.cue not found (run from the repo root)" >&2; exit 1; }

if [[ ! -d "$MODULE/transformers" ]]; then
    echo "OK: $MODULE has no transformers/ directory — no rendered-output fixtures."
    exit 0
fi

# `<file>\t<field>` per fixture, in file order. The field name is everything
# before the first colon; the guard is the `(#X.#transform & {` that follows.
fixtures="$(grep -rhnE '^_test[A-Za-z0-9_]*:[[:space:]]*\(#[A-Za-z0-9_]+\.#transform[[:space:]]*&[[:space:]]*\{' \
    "$MODULE/transformers" --include='*.cue' -H \
    | sed -E 's|^'"$MODULE"'/transformers/([^:]+):[0-9]+:(_test[A-Za-z0-9_]*):.*$|\1\t\2|' \
    || true)"

if [[ -z "$fixtures" ]]; then
    echo "OK: $MODULE/transformers has no rendered-output fixtures."
    exit 0
fi

total=0
failed=0
while IFS=$'\t' read -r file field; do
    [[ -n "$field" ]] || continue
    total=$((total + 1))
    if err="$(cd "$MODULE" && cue export -e "$field" ./transformers 2>&1 >/dev/null)"; then
        continue
    fi
    failed=$((failed + 1))
    echo "FAIL: $MODULE/transformers/$file: $field" >&2
    printf '%s\n' "$err" | sed -n '1p' | sed 's/^/    /' >&2
done <<< "$fixtures"

if (( failed > 0 )); then
    echo "FAIL: $MODULE — $failed of $total rendered-output fixtures do not evaluate." >&2
    exit 1
fi

echo "OK: $MODULE — all $total rendered-output fixtures evaluate."
