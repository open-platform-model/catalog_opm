#!/usr/bin/env bash
# task deps:cascade:test: run deps:cascade in sandbox copies of the tree against the contract
# stub (Phase 2 cascade contract §8; design D6). Nothing touches the real checkout.
#
#   CASCADE_TEST_SET=offline   the checks, S1 no-op, S3 resolver error, S6 dirty tree, and S7
#                              the edit-phase guards with a fake cue (no network)
#   CASCADE_TEST_SET=all       also S2 older pins, S4 frozen (GHCR or a warm CUE cache) and,
#                              when CASCADE_RESOLVER_REAL names the real resolver, S5 title and body
#
# Prints PASS/FAIL per check and scenario; exit 0 when all pass, 1 otherwise.
set -euo pipefail

die() { printf 'deps:cascade:test: %s\n' "$1" >&2; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(git -C "$HERE" rev-parse --show-toplevel)
STUB=$HERE/testdata/stub-resolve.sh
STUB_SUM=970130f7d55c07f5b86d4f5b6f392330427ff923eb34f93553656bcd4b893d9c
OLDER=$HERE/testdata/older.tsv
S1_CALLS=$HERE/testdata/s1-calls.txt

CORE_FILE=src/cue.mod/module.cue
CORE_KEY=opmodel.dev/core@v2
CLI_FILE=.opm-cli-version
CLI_KEY=github.com/open-platform-model/cli

SET=${CASCADE_TEST_SET:-all}
case "$SET" in offline | all) ;; *) die "CASCADE_TEST_SET must be offline or all, not $SET" ;; esac

# A caller's cascade env must not leak into a scenario.
unset CASCADE_RESOLVER CASCADE_ALLOW_DIRTY CASCADE_EXPECT CASCADE_SOURCE CASCADE_TAGS CASCADE_NOTES_FILE \
  CASCADE_WARNINGS CASCADE_STUB_TABLE CASCADE_STUB_LOG CASCADE_BASE
export CASCADE_TODAY=2026-10-03

GIT=(git -c user.name=cascade-test -c user.email=cascade-test@localhost -c init.defaultBranch=main)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fails=0
pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; fails=$((fails + 1)); }

# sandbox NAME: a committed copy of the tree at $WORK/NAME/r (contract §8 steps 1 and 2).
sandbox() {
  local d="$WORK/$1/r"
  mkdir -p "$d"
  (cd "$TOP" && git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - | tar -xf - -C "$d")
  (cd "$d" && "${GIT[@]}" init -q && "${GIT[@]}" add -A && "${GIT[@]}" commit -q -m base)
  printf '%s\n' "$d"
}

# commit_setup DIR: commit the scenario's setup edits and print the setup SHA (step 3 and 4).
commit_setup() {
  (cd "$1" && "${GIT[@]}" add -A && "${GIT[@]}" commit -q --allow-empty -m setup && git rev-parse HEAD)
}

# run_cascade DIR TABLE BASE NAME: run task -x deps:cascade in DIR against the stub; sets RC,
# and keeps the output in $WORK/NAME.out and the stub log in $WORK/NAME.log.
run_cascade() {
  RC=0
  (cd "$1" && CASCADE_RESOLVER="$STUB" CASCADE_STUB_TABLE="$2" CASCADE_BASE="$3" \
    CASCADE_STUB_LOG="$WORK/$4.log" task -x deps:cascade) >"$WORK/$4.out" 2>&1 || RC=$?
}

# show NAME: print a scenario's output, for a failure.
show() { sed 's/^/    | /' "$WORK/$1.out"; }

status_of() { git -C "$1" status --porcelain --untracked-files=all; }

# pin_at DIR KEY: the version pins.sh reports for KEY in DIR's working tree.
pin_at() { (cd "$1" && .tasks/cascade/pins.sh WORKTREE) | awk -F'\t' -v k="$2" '$1 == k { print $4 }'; }

# older_of KEY: the older.tsv version for KEY.
older_of() { awk -F'\t' -v k="$1" '!/^#/ && $1 == k { print $2 }' "$OLDER"; }

# set_older DIR: move every pin in DIR to its older.tsv version (text edits, as a stale tree).
set_older() {
  local core cli
  core=$(older_of "$CORE_KEY")
  cli=$(older_of "$CLI_KEY")
  sed -i "/\"opmodel.dev\/core@v2\"/,/}/ s/v: \"[^\"]*\"/v: \"$core\"/" "$1/$CORE_FILE"
  printf '%s\n' "$cli" >"$1/$CLI_FILE"
}

# ---- Checks before the scenarios -------------------------------------------------------

sum=$(sha256sum "$STUB" | cut -d' ' -f1)
if [ "$sum" = "$STUB_SUM" ]; then
  pass "stub checksum"
else
  fail "stub checksum" "$STUB has sha256 $sum, not the contract §7 $STUB_SUM; copy the stub again, never edit it"
fi

ref=$(sandbox ref)
if diff <(cd "$ref" && .tasks/cascade/pins.sh WORKTREE) <(cd "$ref" && .tasks/cascade/pins.sh HEAD) >"$WORK/pins.diff"; then
  pass "pins.sh WORKTREE and HEAD agree"
else
  fail "pins.sh WORKTREE and HEAD agree" "$(cat "$WORK/pins.diff")"
fi

# The current stub rows, from the unmodified tree; built here, never committed (contract §8).
CUR_CORE=$(pin_at "$ref" "$CORE_KEY")
CUR_CLI=$(pin_at "$ref" "$CLI_KEY")
[ -n "$CUR_CORE" ] && [ -n "$CUR_CLI" ] || die "pins.sh did not report both pins of the tree"
TABLE=$WORK/table.tsv
printf 'newest\tcue\t%s\t%s\nnewest\topm-cli\t-\t%s\n' "$CORE_KEY" "$CUR_CORE" "$CUR_CLI" >"$TABLE"

older_ok=1
for key in "$CORE_KEY" "$CLI_KEY"; do
  old=$(older_of "$key")
  tree=$(pin_at "$ref" "$key")
  if [ -z "$old" ] || [ "$(CASCADE_STUB_TABLE="$TABLE" "$STUB" semver-cmp "$old" "$tree")" != -1 ]; then
    fail "older.tsv" "\`older.tsv\` \`$key\` \`${old:-(missing)}\` is not older than the tree's \`$tree\`; pick an older published version"
    older_ok=0
  fi
done
if [ "$older_ok" = 1 ]; then pass "older.tsv is older than the tree"; fi

# ---- S1 no-op --------------------------------------------------------------------------
d=$(sandbox s1)
base=$(cd "$d" && git rev-parse HEAD)
run_cascade "$d" "$TABLE" "$base" s1
calls=$(sed -E 's/v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?/V/g' "$WORK/s1.log" | LC_ALL=C sort)
bad_newest=$(awk '/^newest / && !(/ --current / && / --repo-root /)' "$WORK/s1.log")
if [ "$RC" != 3 ]; then
  fail S1 "exit $RC, expected 3"; show s1
elif [ -n "$(status_of "$d")" ]; then
  fail S1 "the tree changed: $(status_of "$d")"
elif [ "$calls" != "$(cat "$S1_CALLS")" ]; then
  fail S1 "the resolver calls differ from testdata/s1-calls.txt: $(diff <(printf '%s\n' "$calls") "$S1_CALLS" || true)"
elif [ -n "$bad_newest" ]; then
  fail S1 "a newest call lacks --current or --repo-root: $bad_newest"
else
  pass "S1 no-op"
fi

# ---- S3 resolver error (the first pin resolved is core) --------------------------------
d=$(sandbox s3)
base=$(cd "$d" && git rev-parse HEAD)
awk -F'\t' -v OFS='\t' -v k="$CORE_KEY" '$1 == "newest" && $3 == k { $4 = "ERROR" } { print }' \
  "$TABLE" >"$WORK/s3.tsv"
run_cascade "$d" "$WORK/s3.tsv" "$base" s3
if [ "$RC" = 0 ] || [ "$RC" = 3 ]; then
  fail S3 "exit $RC, expected an error"; show s3
elif [ -n "$(status_of "$d")" ]; then
  fail S3 "the tree changed: $(status_of "$d")"
else
  pass "S3 resolver error (exit $RC)"
fi

# ---- S6 dirty tree ---------------------------------------------------------------------
d=$(sandbox s6)
base=$(cd "$d" && git rev-parse HEAD)
printf 'dirty\n' >"$d/cascade-test-untracked"
run_cascade "$d" "$TABLE" "$base" s6
if [ "$RC" != 1 ]; then
  fail S6 "exit $RC, expected 1"; show s6
elif [ "$(status_of "$d")" != "?? cascade-test-untracked" ]; then
  fail S6 "something else changed: $(status_of "$d")"
else
  pass "S6 dirty tree"
fi

# ---- S7 edit-phase guards (a fake cue first on PATH, so still offline) -------------------
# Not a contract §8 scenario: it covers the paths only a real move reaches, the
# language.version warning, CASCADE_EXPECT passed on as --expect, a tidy that raises a
# frozen key (exit 1) or an unfrozen one (a warning), and a tidy that touches
# language.version (exit 1).
mkdir -p "$WORK/bin"
cat >"$WORK/bin/cue" <<'FAKE'
#!/usr/bin/env bash
# Fake cue for S7, run in src/: get sets core's v:, tidy does what FAKE_CUE_TIDY says.
set -euo pipefail
f=cue.mod/module.cue
case "$1 $2" in
  "mod get") sed -i "/\"opmodel.dev\/core@v2\"/,/}/ s/v: \"[^\"]*\"/v: \"${3#*@}\"/" "$f" ;;
  "mod tidy")
    case "${FAKE_CUE_TIDY:-}" in
      raise-k8s) sed -i '/"cue.dev\/x\/k8s.io@v0"/,/}/ s/v:\([[:space:]]*\)"[^"]*"/v:\1"v0.99.0"/' "$f" ;;
      lang) sed -i '/^language:/,/^}/ s/version: "[^"]*"/version: "v0.99.0"/' "$f" ;;
    esac ;;
  *) echo "fake cue: unexpected call: $*" >&2; exit 2 ;;
esac
FAKE
chmod +x "$WORK/bin/cue"
K8S_KEY=cue.dev/x/k8s.io@v0
S7_TABLE=$WORK/s7.tsv
{ cat "$TABLE"; printf 'language-of\t%s\t%s\tv0.99.0\n' "$CORE_KEY" "$CUR_CORE"; } >"$S7_TABLE"

# s7_run NAME TIDY FREEZE_K8S: an older tree, then deps:cascade with the fake cue.
s7_run() {
  local d setup
  d=$(sandbox "$1")
  set_older "$d"
  if [ "$3" = 1 ]; then
    printf 'frozen:\n  - path: %s\n    pins: [%s]\n    reason: deps:cascade:test S7\n' "$CORE_FILE" "$K8S_KEY" >"$d/.cascade-frozen"
  fi
  setup=$(commit_setup "$d")
  PATH="$WORK/bin:$PATH" FAKE_CUE_TIDY="$2" CASCADE_EXPECT="$CORE_KEY=$CUR_CORE" \
    run_cascade "$d" "$S7_TABLE" "$setup" "$1"
  S7_DIR=$d
}

s7_run s7-warn raise-k8s 0
w="$S7_DIR/.git/cascade/warnings"
if [ "$RC" != 0 ]; then
  fail "S7 warnings" "exit $RC, expected 0"; show s7-warn
elif [ "$(pin_at "$S7_DIR" "$CORE_KEY")" != "$CUR_CORE" ] || [ "$(pin_at "$S7_DIR" "$CLI_KEY")" != "$CUR_CLI" ]; then
  fail "S7 warnings" "the pins did not move to $CUR_CORE and $CUR_CLI"
elif ! grep -q "^$CORE_KEY"$'\t'".*language.version \`v0.99.0\`" "$w"; then
  fail "S7 warnings" "no language.version warning: $(cat "$w")"
elif ! grep -q "^$K8S_KEY"$'\t'".*raised" "$w"; then
  fail "S7 warnings" "no warning for the raised $K8S_KEY: $(cat "$w")"
elif ! grep -q "^newest cue $CORE_KEY .*--expect $CUR_CORE" "$WORK/s7-warn.log"; then
  fail "S7 warnings" "CASCADE_EXPECT did not reach newest as --expect: $(cat "$WORK/s7-warn.log")"
else
  pass "S7 language and tidy warnings, --expect"
fi

s7_run s7-frozen raise-k8s 1
if [ "$RC" != 1 ] || ! grep -q "moved frozen $K8S_KEY" "$WORK/s7-frozen.out"; then
  fail "S7 frozen raise" "exit $RC, expected 1 naming the frozen $K8S_KEY"; show s7-frozen
else
  pass "S7 tidy raising a frozen key stops the task"
fi

s7_run s7-lang lang 0
if [ "$RC" != 1 ] || ! grep -q "changed language.version" "$WORK/s7-lang.out"; then
  fail "S7 language.version" "exit $RC, expected 1 naming language.version"; show s7-lang
else
  pass "S7 tidy touching language.version stops the task"
fi

if [ "$SET" = offline ]; then
  [ "$fails" = 0 ] || exit 1
  exit 0
fi

# ---- S2 older pins ---------------------------------------------------------------------
# catalog_opm has no version-advance module, so the golden list of paths allowed to differ
# from the original tree is empty: the run must restore the tree exactly.
s2=$(sandbox s2)
orig=$(cd "$s2" && git rev-parse HEAD)
set_older "$s2"
s2_setup=$(commit_setup "$s2")
run_cascade "$s2" "$TABLE" "$s2_setup" s2
s2_ok=0
if [ "$RC" != 0 ]; then
  fail S2 "exit $RC, expected 0"; show s2
elif [ -n "$(cd "$s2" && git diff --name-only "$orig")$(cd "$s2" && git ls-files --others --exclude-standard)" ]; then
  fail S2 "the tree differs from the original: $(cd "$s2" && git diff --stat "$orig")"
else
  (cd "$s2" && "${GIT[@]}" add -A && "${GIT[@]}" commit -q -m cascade)
  run_cascade "$s2" "$TABLE" "$s2_setup" s2-again
  if [ "$RC" != 3 ]; then
    fail S2 "the second run exited $RC, expected 3"; show s2-again
  elif [ -n "$(status_of "$s2")" ] || [ -n "$(cd "$s2" && git diff --name-only "$orig" -- src/identity)" ]; then
    fail S2 "the second run changed the tree or the identity: $(status_of "$s2")"
  else
    pass "S2 older pins (and a second run exits 3)"
    s2_ok=1
  fi
fi

# ---- S4 frozen -------------------------------------------------------------------------
# Freezes src/cue.mod/module.cue, the only cue.mod file the task edits, for every OPM key it
# pins (core), appended to the repo's own .cascade-frozen when there is one (design D6).
d=$(sandbox s4)
set_older "$d"
if [ ! -f "$d/.cascade-frozen" ]; then printf 'frozen:\n' >"$d/.cascade-frozen"; fi
printf '  - path: %s\n    pins: [%s]\n    reason: deps:cascade:test S4\n' "$CORE_FILE" "$CORE_KEY" >>"$d/.cascade-frozen"
setup=$(commit_setup "$d")
run_cascade "$d" "$TABLE" "$setup" s4
if [ "$RC" != 0 ]; then
  fail S4 "exit $RC, expected 0"; show s4
elif ! (cd "$d" && git diff --quiet "$setup" -- "$CORE_FILE"); then
  fail S4 "the frozen $CORE_FILE changed: $(cd "$d" && git diff "$setup" -- "$CORE_FILE")"
elif [ "$(pin_at "$d" "$CLI_KEY")" != "$CUR_CLI" ]; then
  fail S4 "the opm CLI did not move to $CUR_CLI"
else
  pass "S4 frozen"
fi

# ---- S5 title and body (real resolver, after S2) ---------------------------------------
if [ -z "${CASCADE_RESOLVER_REAL:-}" ]; then
  printf 'SKIP S5: CASCADE_RESOLVER_REAL is not set\n'
elif [ ! -x "$CASCADE_RESOLVER_REAL" ]; then
  fail S5 "CASCADE_RESOLVER_REAL is not executable: $CASCADE_RESOLVER_REAL"
elif [ "$s2_ok" != 1 ]; then
  fail S5 "needs S2 to pass first"
else
  want="fix(deps): bump core to $CUR_CORE and opm CLI to $CUR_CLI"
  RC=0
  title=$(cd "$s2" && CASCADE_RESOLVER="$CASCADE_RESOLVER_REAL" CASCADE_BASE="$s2_setup" \
    task -x deps:cascade:title 2>"$WORK/s5-title.out") || RC=$?
  body_rc=0
  (cd "$s2" && CASCADE_RESOLVER="$CASCADE_RESOLVER_REAL" CASCADE_BASE="$s2_setup" \
    task -x deps:cascade:body >"$WORK/s5-body.md" 2>"$WORK/s5-body.out") || body_rc=$?
  body="$WORK/s5-body.md"
  if [ "$RC" != 0 ] || [ "$title" != "$want" ]; then
    fail S5 "title exit $RC, got \"$title\", expected \"$want\""; show s5-title
  elif [ "$body_rc" != 0 ]; then
    fail S5 "body exit $body_rc"; show s5-body
  elif ! grep -qxF "<!-- cascade-title: $want -->" "$body" || ! grep -q '^<!-- cascade-notes: ' "$body"; then
    fail S5 "the body lacks a cascade-title or cascade-notes marker"
  elif [ "$(grep -cE '^\| (core|opm CLI) \(`' "$body")" != 2 ] || [ "$(grep -c '^| ' "$body")" != 4 ]; then
    fail S5 "the body's moved-pins table does not hold exactly the two pins"
  elif grep -q 'need-human-review' "$body"; then
    fail S5 "the body carries need-human-review, which is library only"
  elif [ "$(grep '^## ' "$body" | tail -n1)" != "## Notes" ]; then
    fail S5 "## Notes is not the last section"
  else
    pass "S5 title and body"
  fi
fi

[ "$fails" = 0 ] || exit 1
exit 0
