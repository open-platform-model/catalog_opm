#!/usr/bin/env bash
set -euo pipefail

# See generate-index.sh for the rationale: pin to C so output order is
# byte-stable across locales.
export LC_ALL=C

# description-check.sh — refuse a catalog member without a description.
#
# Every member listed in one of the module's catalog maps (#resources,
# #traits, #blueprints and #transformers) MUST carry a non-blank
# `metadata.description`. It is the member's one-line summary: the published
# catalog reference (the catalog-opm docs bundle) leads every entry with it
# (workspace STYLE.md, "Site Pages"), and it agrees with the first sentence
# of the member's doc comment (AGENTS.md, Working Style, Descriptions).
#
# WHY a gate and not a schema constraint: core declares the field optional on
# primitives (`description?: string`), and a member is a definition, so a
# constraint added to the catalog maps would ship inside the published
# artifact and still could not see an absent field without failing every
# consumer's evaluation. One small evaluation per module lists the offenders
# instead, the same way listing.sh reads the maps.
#
# Usage (run from the repo root):
#   bash .tasks/description-check.sh <module_dir>    # src
#
# Exits 0 when every listed member has a description, 1 otherwise.

MODULE="${1:?Error: module argument required. Usage: bash .tasks/description-check.sh src}"
MODULE="${MODULE%/}"

[[ -f "$MODULE/catalog.cue" ]] \
    || { echo "Error: $MODULE/catalog.cue not found (run from the repo root)" >&2; exit 1; }

# A member fails when its description is absent, not a string, or blank: the
# unification with a non-blank pattern is bottom in all three cases.
missing="$(cd "$MODULE" && cue export --out text -e '
    strings.Join([
        for kind in ["resources", "traits", "blueprints", "transformers"]
        for fqn, m in {
            if kind == "resources" {#resources}
            if kind == "traits" {#traits}
            if kind == "blueprints" {#blueprints}
            if kind == "transformers" {#transformers}
        }
        if (m.metadata.description & =~"[^[:space:]]") == _|_ {"\(kind)\t\(fqn)"},
    ], "\n")' ./ 2>&1)" || { echo "FAIL: $MODULE: could not evaluate the catalog maps:" >&2; echo "$missing" >&2; exit 1; }

if [[ -n "$missing" ]]; then
    echo "FAIL: $MODULE members without a metadata.description (kind, fqn):" >&2
    printf '%s\n' "$missing" | sort >&2
    exit 1
fi

count="$(cd "$MODULE" && cue export -e 'len(#resources) + len(#traits) + len(#blueprints) + len(#transformers)' ./)"
echo "OK: every $MODULE member has a description ($count)."
