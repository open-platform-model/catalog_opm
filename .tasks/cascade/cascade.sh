#!/usr/bin/env bash
# task deps:cascade for catalog_opm: move the repo's two upstream pins in the working tree.
#
#   core     opmodel.dev/core@v2                 src/cue.mod/module.cue   shipped
#   opm CLI  github.com/open-platform-model/cli  .opm-cli-version         release-tool
#
# Phase 2 cascade contract §5.2 and §6.1; workspace RELEASING.md, "What each repo's task
# moves". Exit 0 when the working tree changed, 3 when there was nothing to do, anything
# else on error. Never commits, branches or pushes. Run it as `task -x deps:cascade`,
# which finds the resolver and exports CASCADE_RESOLVER.
#
# It never names cue.dev/x/k8s.io@v0 (a tidy that raises it is a warning, never a revert),
# never globs for module.cue (.build/ and .claude/worktrees/ hold others), and never touches
# src/identity/identity.cue, src/RELEASE, the release-please files, .opm-docs-version,
# .cascade-hold, .cascade-frozen, language.version or anything under .github/.
#
# No src/INDEX.md regeneration: .tasks/generate-index.sh reads only the module: line of
# cue.mod/module.cue, so a dependency move cannot stale it (design D4).
set -euo pipefail

die() { printf 'deps:cascade: %s\n' "$1" >&2; exit "${2:-1}"; }
note() { printf 'deps:cascade: %s\n' "$1" >&2; }

[ -n "${CASCADE_RESOLVER:-}" ] || die "CASCADE_RESOLVER is not set; run task -x deps:cascade"
R=$CASCADE_RESOLVER

cd "$(git rev-parse --show-toplevel)"

CORE_FILE=src/cue.mod/module.cue
CORE_KEY=opmodel.dev/core@v2
CORE_MOD=opmodel.dev/core
CLI_FILE=.opm-cli-version
CLI_KEY=github.com/open-platform-model/cli
# The repo's pinned CUE version for the language.version check (contract §5.2 rule 10;
# design D5). Read only, never edited.
CUE_VERSION_FILE=.github/workflows/branch-publish.yml

# Rule 1: the snapshot a CASCADE_ALLOW_DIRTY=1 run is judged by (contract §5.2).
snapshot() {
  { git status --porcelain --untracked-files=all
    git diff HEAD --binary
    git ls-files -z --others --exclude-standard | xargs -0 -r sha256sum
  } | sha256sum
}

# ---- Rule 1: clean start ---------------------------------------------------------------
allow_dirty=0
start=""
if [ "${CASCADE_ALLOW_DIRTY:-}" = 1 ]; then
  allow_dirty=1
  start=$(snapshot)
elif [ -n "$(git status --porcelain --untracked-files=all)" ]; then
  die "the working tree is not clean; commit or stash first, or set CASCADE_ALLOW_DIRTY=1"
fi

# ---- Rule 2: state directory and warnings ----------------------------------------------
STATE="$(git rev-parse --absolute-git-dir)/cascade"
mkdir -p "$STATE"
: >"$STATE/warnings"
export CASCADE_WARNINGS="$STATE/warnings"

# warn KEY MESSAGE: one "<pin-key>\t<message>" line for the PR body (key "-" for none).
warn() {
  printf '%s\t%s\n' "$1" "$2" >>"$CASCADE_WARNINGS"
  note "warning: $2"
}

# ---- Rule 3: the steering files --------------------------------------------------------
"$R" check-files --repo-root .

# ---- Rule 4: registries, never inherited -----------------------------------------------
export CUE_REGISTRY='opmodel.dev=ghcr.io/open-platform-model,registry.cue.works'
export OPM_REGISTRY="$CUE_REGISTRY"

# ---- Resolver helpers ------------------------------------------------------------------

# expect_for KEY: the version CASCADE_EXPECT names for KEY ("<pin-key>=<v> ..."), if any.
expect_for() {
  local w
  for w in ${CASCADE_EXPECT:-}; do
    if [ "${w%%=*}" = "$1" ]; then
      printf '%s\n' "${w#*=}"
      return 0
    fi
  done
  return 0
}

# is_frozen PATH KEY: 0 frozen, 1 not frozen; any other resolver answer stops the task.
is_frozen() {
  local rc=0
  "$R" is-frozen "$1" "$2" --repo-root . || rc=$?
  case "$rc" in
    0) return 0 ;;
    3) return 1 ;;
    *) die "resolver is-frozen $1 $2 failed (exit $rc)" "$rc" ;;
  esac
}

# resolve KEY KIND COORD CURRENT: print the target when the pin should move, nothing when
# it stays; any other resolver answer stops the task with that code (rule 5).
resolve() {
  local key="$1" kind="$2" coord="$3" cur="$4" exp out rc=0
  local args=(newest "$kind")
  if [ -n "$coord" ]; then args+=("$coord"); fi
  args+=(--current "$cur" --repo-root .)
  exp=$(expect_for "$key")
  if [ -n "$exp" ]; then args+=(--expect "$exp"); fi
  out=$("$R" "${args[@]}") || rc=$?
  case "$rc" in
    0) printf '%s\n' "$out" ;;
    3) ;;
    *) die "resolver newest $kind $coord failed (exit $rc)" "$rc" ;;
  esac
}

# key_v KEY: the v: of KEY in src/cue.mod/module.cue, or "(absent)".
key_v() {
  local v
  if v=$(grep -FA5 "\"$1\"" "$CORE_FILE" | grep -m1 -oP 'v:\s*"\K[^"]+'); then
    printf '%s\n' "$v"
  else
    printf '%s\n' "(absent)"
  fi
}

# dep_keys: every key of the deps: block of src/cue.mod/module.cue except core.
dep_keys() {
  awk -v core="$CORE_KEY" '
    /^deps: \{$/ { d = 1; next }
    d && /^\}$/ { d = 0 }
    d && /^[ \t]*"[^"]+":[ \t]*\{/ { split($0, a, "\""); if (a[2] != core) print a[2] }
  ' "$CORE_FILE"
}

# ---- Current pins ----------------------------------------------------------------------
pins=$(.tasks/cascade/pins.sh WORKTREE)
core_cur=$(awk -F'\t' -v k="$CORE_KEY" '$1 == k { print $4 }' <<<"$pins")
cli_cur=$(awk -F'\t' -v k="$CLI_KEY" '$1 == k { print $4 }' <<<"$pins")
[ -n "$core_cur" ] || die "$CORE_FILE pins no $CORE_KEY"
[ -n "$cli_cur" ] || die "$CLI_FILE is missing"

# ---- Phase A: resolve every target before any edit (rule 5) ----------------------------
core_to=""
others=()
frozen_others=()
if is_frozen "$CORE_FILE" "$CORE_KEY"; then
  note "$CORE_KEY is frozen in $CORE_FILE; left at $core_cur"
else
  core_to=$(resolve "$CORE_KEY" cue "$CORE_KEY" "$core_cur")
fi

if [ -n "$core_to" ]; then
  # Rule 10: compare the new core's language.version with the pinned CUE version.
  pinned=""
  if [ -f "$CUE_VERSION_FILE" ]; then
    pinned=$(grep -m1 -oP "^\s*CUE_VERSION:\s*'\K[^']+" "$CUE_VERSION_FILE") || pinned=""
  fi
  if [ -z "$pinned" ]; then
    warn - "cannot read the pinned \`CUE_VERSION\` from \`$CUE_VERSION_FILE\`; language.version not checked"
  else
    rc=0
    lang=$("$R" language-of "$CORE_KEY" "$core_to") || rc=$?
    case "$rc" in
      0)
        if [ "$("$R" semver-cmp "$lang" "$pinned")" = 1 ]; then
          warn "$CORE_KEY" "core \`$core_to\` declares language.version \`$lang\`, newer than the pinned CUE \`$pinned\` in \`$CUE_VERSION_FILE\`"
        fi ;;
      3) ;;
      *) die "resolver language-of $CORE_KEY $core_to failed (exit $rc)" "$rc" ;;
    esac
  fi

  # Rule 8: keys frozen for this file that a core move could raise by MVS.
  mapfile -t others < <(dep_keys)
  for k in "${others[@]}"; do
    if is_frozen "$CORE_FILE" "$k"; then frozen_others+=("$k"); fi
  done
fi

cli_to=""
if is_frozen "$CLI_FILE" "$CLI_KEY"; then
  note "$CLI_KEY is frozen in $CLI_FILE; left at $cli_cur"
else
  cli_to=$(resolve "$CLI_KEY" opm-cli "" "$cli_cur")
fi

# ---- Phase B: tools. None: catalog_opm has no version-advance module. --------------------

# ---- Phase C: edit, shipped first and .opm-cli-version last (rule 12) ------------------
if [ -n "$core_to" ]; then
  declare -A before=()
  for k in "${others[@]}"; do before[$k]=$(key_v "$k"); done

  # Rule 6: an explicit version, one get and one tidy, in src/ only.
  (
    cd src
    cue mod get "$CORE_MOD@$core_to"
    cue mod tidy
  )
  now=$(key_v "$CORE_KEY")
  [ "$now" = "$core_to" ] || die "$CORE_FILE: core is $now after cue mod get, expected $core_to"
  note "core: $core_cur -> $core_to"

  for k in "${others[@]}"; do
    after=$(key_v "$k")
    [ "$after" != "${before[$k]}" ] || continue
    for f in "${frozen_others[@]}"; do
      if [ "$f" = "$k" ]; then
        die "$CORE_FILE: cue mod tidy moved frozen $k from ${before[$k]} to $after; freeze the whole module, or hold the upstream"
      fi
    done
    msg="\`cue mod tidy\` raised \`$k\` from \`${before[$k]}\` to \`$after\` in \`$CORE_FILE\`"
    if [ "$k" = cue.dev/x/k8s.io@v0 ]; then
      msg="$msg; move \`KUBERNETES_VERSION\` and run \`task generate:kinds\` by hand"
    fi
    warn "$k" "$msg"
  done
fi

if [ -n "$cli_to" ]; then
  printf '%s\n' "$cli_to" >"$CLI_FILE"
  note "opm CLI: $cli_cur -> $cli_to"
fi

# ---- Rule 13: the result ---------------------------------------------------------------
if [ "$allow_dirty" = 1 ]; then
  if [ "$(snapshot)" != "$start" ]; then exit 0; fi
  exit 3
fi
if [ -n "$(git status --porcelain --untracked-files=all)" ]; then exit 0; fi
exit 3
