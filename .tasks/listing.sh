#!/usr/bin/env bash
set -euo pipefail

# See generate-index.sh for the rationale — pin to C so sort order is
# byte-stable across locales (the diff below compares sorted sets).
export LC_ALL=C

# listing.sh — enforce the listing rule for one CUE module.
#
# Every contract member filed under <module>/<kind>/<apiVersion>/ — and every
# transformer filed flat under <module>/transformers/ — MUST be a key of that
# module's catalog.cue #<kind> map, and every key MUST name a member
# (enhancement 0015 D1; AGENTS.md, Working Style, Listing). Core checks that a
# listed member is well-formed; it cannot check that the list is complete,
# which is what this gate adds.
#
# Two sets per kind (resources, traits, blueprints, transformers):
#   expected — the fqn each member AUTHORS: every `fqn:` line under the kind
#              directory, with `\(id.kindPrefix.<kind>)` substituted from the
#              identity package's RegistryPath and `\(id.Version)` from its
#              Version. A file may hold several members; a kind directory that
#              does not exist expects nothing.
#   listed   — the keys of the catalog's #<kind> map, read through cue. An
#              absent map is empty under core's pattern constraint.
#
# WHY the version substitution: a transformer's key is build-scoped
# (`…/transformers/<name>@<version>`), so its authored fqn interpolates
# id.Version while a contract member's carries its own apiVersion literally.
# Version is read through cue rather than grepped: opm commits a plain string,
# k8s a defaulted disjunction, and only the evaluator resolves both.
# Sorted and diffed; a non-empty diff fails naming the missing (`<`) and
# extra (`>`) keys.
#
# Usage (run from the repo root):
#   bash .tasks/listing.sh <module>          # opm | k8s
#
# Exits 0 when every kind agrees, 1 otherwise.

MODULE="${1:?Error: module argument required. Usage: bash .tasks/listing.sh opm}"
MODULE="${MODULE%/}"

[[ -f "$MODULE/catalog.cue" ]] \
    || { echo "Error: $MODULE/catalog.cue not found (run from the repo root)" >&2; exit 1; }

registry="$(grep -oE '^RegistryPath: +"[^"]+"' "$MODULE/identity/identity.cue" | sed -E 's/^RegistryPath: +"([^"]+)"/\1/')"
[[ -n "$registry" ]] \
    || { echo "Error: RegistryPath not found in $MODULE/identity/identity.cue" >&2; exit 1; }

version="$(cd "$MODULE" && cue export -e Version ./identity | tr -d '"')"
[[ -n "$version" ]] \
    || { echo "Error: Version not resolvable from $MODULE/identity/" >&2; exit 1; }

rc=0
for kind in resources traits blueprints transformers; do
    expected=""
    if [[ -d "$MODULE/$kind" ]]; then
        expected="$(grep -rhoE 'fqn: +"\\\(id\.kindPrefix\.'"$kind"'\)/[^"]+"' "$MODULE/$kind" --include='*.cue' \
            | sed -E 's|^fqn: +"\\\(id\.kindPrefix\.'"$kind"'\)|'"$registry/$kind"'|; s|"$||' \
            | sed "s|\\\\(id\.Version)|$version|" \
            | sort -u)"
    fi

    listed="$(cd "$MODULE" && cue export -e "[for k, _ in #$kind {k}]" ./ \
        | tr -d '[]",' | sed 's/^ *//' | sed '/^$/d' | sort -u)"

    if diff_out="$(diff <(printf '%s\n' "$expected" | sed '/^$/d') <(printf '%s\n' "$listed" | sed '/^$/d'))"; then
        count="$(printf '%s\n' "$listed" | sed '/^$/d' | wc -l | tr -d ' ')"
        echo "OK: $MODULE #$kind lists every member ($count)."
    else
        echo "FAIL: $MODULE #$kind disagrees with $MODULE/$kind/ (< authored but not listed, > listed but not authored):" >&2
        echo "$diff_out" | grep -E '^[<>]' >&2 || true
        rc=1
    fi
done

exit $rc
