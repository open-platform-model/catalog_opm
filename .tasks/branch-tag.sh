#!/usr/bin/env bash
set -euo pipefail

# branch-tag.sh — print the branch-publish tag for HEAD.
#
# Output format:
#   v<MAJOR>.<MINOR>.<PATCH>-0.dev.<commit_ct>.g<short_sha>
#
# The leading `0.` is what keeps a branch build below every release on the same
# base — see "Choose the channel base" below.
#
# Inputs (all derived from the commit object and the repo state — no clocks,
# no environment, no network):
#   MAJOR        from <module_dir>/cue.mod/module.cue ("opmodel.dev/catalogs/opm@vN")
#   base         base version of the highest release for this major, stable or
#                prerelease, so the branch build shares the release channel's
#                base and can be ranked below it. Falls back to MAJOR.0.0 when
#                the major carries no release of any kind yet (e.g. immediately
#                after a major bump).
#   commit_ct    `git show -s --format=%ct HEAD` — committer Unix seconds,
#                baked into the SHA hash so it is identical wherever this
#                runs for a given commit
#   short_sha    seven hex characters of HEAD, prefixed with 'g'
#
# Refuses to run on the main branch, and refuses to run with a dirty worktree
# (a dirty tree would lie about the SHA the consumer ends up with).
#
# Usage (from the repo root):
#   bash .tasks/branch-tag.sh "$(pwd)/opm" "opm-"
#
# Arguments:
#   module_dir   the CUE module directory (this repo publishes opm/ and k8s/)
#   tag_prefix   release-please component prefix on this module's git tags
#                ("opm-", "k8s-"). Used ONLY to find this module's existing
#                releases; the tag printed is always the bare version form,
#                because `opm catalog version set` consumes it.
#
# The prefix is REQUIRED and is not allowed to fall back to bare `vX.Y.Z`
# tags: this repo's bare tags belong to the pre-split single-module line, and
# a v1.* bare tag from the old opm catalog would otherwise be mistaken for a
# release of the k8s catalog, which is also major v1.

CUE_RELDIR="${1:?Error: module_dir argument required. Usage: bash .tasks/branch-tag.sh \"\$(pwd)/opm\" \"opm-\"}"
CUE_DIR="${CUE_RELDIR%/}"
TAG_PREFIX="${2:?Error: tag_prefix argument required (e.g. \"opm-\")}"

# ── Fail fast: validate required paths exist ──────────────────────────────────

[[ -d "$CUE_DIR" ]] \
    || { echo "Error: not a directory: $CUE_DIR" >&2; exit 1; }
[[ -f "$CUE_DIR/cue.mod/module.cue" ]] \
    || { echo "Error: missing $CUE_DIR/cue.mod/module.cue" >&2; exit 1; }

cd "$CUE_DIR"

# ── Guardrails ────────────────────────────────────────────────────────────────

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "main" ]]; then
  echo "Error: refuse to compute a branch tag on main — use the release-please flow." >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: worktree is dirty — commit or stash before computing a branch tag." >&2
  echo "       (a dirty tree would publish a tag that does not match any SHA)" >&2
  exit 3
fi

# ── Parse MAJOR from cue.mod/module.cue ───────────────────────────────────────

module_line=$(grep -E '^module:' cue.mod/module.cue | head -1)
major=$(printf '%s' "$module_line" | grep -oE '@v[0-9]+' | tr -d '@v' || true)

if [[ -z "${major:-}" ]]; then
  echo "Error: could not parse major version from $CUE_DIR/cue.mod/module.cue" >&2
  echo "       expected a line like: module: \"opmodel.dev/catalogs/opm@vN\"" >&2
  exit 4
fi

# ── Choose the channel base ───────────────────────────────────────────────────
#
# The invariant: a branch build must never outrank a release, under ANY query
# — `@vN`, `@vN.M`, or an explicit range that admits prereleases. Anything less
# silently hands consumers an unreleased branch commit.
#
# Protecting only `@vN` is not enough. Go/CUE resolution drops prereleases from
# `@vN` when a stable version exists, which tempts the "put dev on the NEXT
# minor" design. Two things defeat it:
#
#   1. With no stable release for the major (a long `-alpha.N` line, which is
#      where this module lives), `@vN` has nothing to prefer and must pick the
#      highest prerelease. `1.1.0-dev.*` beats `1.0.0-alpha.3` on the base
#      version alone, before prerelease identifiers are even consulted — so
#      moving to the next minor makes it strictly worse, not better.
#   2. Explicit range subscriptions (the opm-operator's platform registry
#      filters) admit prereleases deliberately. They are unaffected by the
#      `@vN` stable-preference rule, so a next-minor dev build wins them
#      whenever that minor has no release of its own yet.
#
# So the branch build shares the base of the highest existing release and is
# ranked below it there. SemVer 2.0 §11.4.3 is the lever: a numeric identifier
# always ranks below an alphanumeric one at the same position. Leading the
# prerelease with `0` puts every branch build under every named channel:
#
#   v1.0.0-0.dev.<ct>.g<sha>  <  v1.0.0-alpha.1  <  v1.0.0
#
# One rule, every phase, every query kind. Branch builds stay reachable by
# exact pin. (`0` is a valid numeric identifier — SemVer prohibits LEADING
# zeroes, e.g. `01`, which the registry rejects outright.)

# Highest release base for this major — stable or prerelease, whichever ranks
# higher. Bases are extracted BEFORE sorting so prerelease identifiers cannot
# perturb the ordering (and so `sort -V`, which is not SemVer-aware about
# prerelease precedence, only ever sees plain X.Y.Z).
base=$(git tag -l "${TAG_PREFIX}v${major}.*" \
  | grep -E "^${TAG_PREFIX}v${major}\.[0-9]+\.[0-9]+(-|$)" \
  | sed -E "s/^${TAG_PREFIX}v([0-9]+\.[0-9]+\.[0-9]+).*/\\1/" \
  | sort -V | tail -1 || true)

# No release of any kind yet for this major. Legitimate for a module whose
# first release has not landed, and legitimate right after a vN→vN+1 bump —
# but it is also what a wrong TAG_PREFIX looks like, and that failure would
# otherwise be silent, so say so on stderr. The emitted tag stays valid
# either way: it leads with `0.`, so it ranks below every named channel on
# the same base.
if [[ -z "$base" ]]; then
  base="${major}.0.0"
  echo "Note: no ${TAG_PREFIX}v${major}.* tag found — basing this build on ${base}." >&2
  echo "      (expected for a module with no release yet; check TAG_PREFIX otherwise)" >&2
fi

# ── Read commit identity ──────────────────────────────────────────────────────

sha_full=$(git rev-parse HEAD)
sha_short=$(git rev-parse --short=7 "$sha_full")
ct=$(git show -s --format=%ct "$sha_full")

# ── Emit ──────────────────────────────────────────────────────────────────────

printf 'v%s-0.dev.%s.g%s\n' "$base" "$ct" "$sha_short"
