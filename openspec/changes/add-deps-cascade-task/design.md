## Context

This change touches no catalog member, no file under `src/` and no `apiVersion` segment. It adds
tooling under `.tasks/cascade/`, four Taskfile tasks, one CI step, one new workflow and
`AGENTS.md` rows. Sources: workspace `RELEASING.md` (sections "The cascade", "What each repo's
task moves", "Gates", "Cascade files", "Rollout and changes") and the Phase 2 cascade contract
(`/var/home/emil/.cache/claude-tmp/claude-1000/-var-home-emil-dev-open-platform-model/2ee0ca8e-268c-4b20-8bd9-b5e4f0d96717/scratchpad/p2-cascade-contract.md`,
"contract §N" below).

State on `main` (2232713) that the design relies on:

- `src/cue.mod/module.cue:8-16`: two deps. `cue.dev/x/k8s.io@v0` `v0.12.0` (`:9-12`, third-party,
  coupled to `KUBERNETES_VERSION` at `Taskfile.yml:10-13` and the generated
  `src/schemas/kinds/table.cue`) and `opmodel.dev/core@v2` `v2.0.0-beta.1` (`:13-15`). Newest
  published core is `v2.0.0-beta.2`.
- `.opm-cli-version`: `v1.0.0-beta.7` (moved by #132). CI checks its shape with
  `grep -qxE 'v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?'` (`ci.yml:30-33`).
- `.cascade-frozen` and `.cascade-hold` do not exist; a missing file means an empty one
  (workspace `RELEASING.md`, section "Cascade files").
- `Taskfile.yml`: `MODULE_DIR: src` (`:9`); `tidy` (`:83-87`); `generate:index:check` (`:96-110`);
  `deps:release-check` (G1, `:192-211`) under `## Release`; `check` (`:215-227`). No task reads
  a global `sh:` var.
- `.tasks/generate-index.sh` reads only the `module:` line of `cue.mod/module.cue` (`:29-35`) and
  the CUE sources; the dependency block never reaches `src/INDEX.md`.
- `ci.yml`: the required job `ci`, name `Validate catalog` (`:20-21`), installs Task (`:40-43`)
  and runs the offline `vet:fixtures:tagged` (`:61-63`) before the GHCR login (`:65-66`).
- `branch-publish.yml:24`: `CUE_VERSION: 'v0.17.1'`, the repo's pinned CUE version (contract
  §5.2 rule 10 names this file for catalog_opm).
- `release-please-config.json`: one package `src`, component `opm`; `ci`, `chore`, `docs`, `test`
  are hidden and do not release.
- Two other `module.cue` trees exist in a checkout (`.build/`, `.claude/worktrees/*/`), so the task
  must never glob.

## Goals / Non-Goals

**Goals:**

- `task -x deps:cascade` moves core in `src/` and `.opm-cli-version` to the newest published
  versions the shared resolver names, and exits 0 (tree changed), 3 (nothing to do) or anything
  else (error), never swallowing a failure.
- A second run on its own output exits 3 and changes nothing.
- `deps:cascade:title` and `deps:cascade:body` produce the cascade PR title and body through the
  shared resolver, with this repo's `pins.sh` and `classes`.
- An offline test set guards the task in the required job; a network set proves the real diff.

**Non-Goals:**

- Committing, branching, pushing, labelling or opening a PR. That is the Phase 3 receiver
  (catalog_opm `join-release-cascade`).
- Computing `deps-cascade:breaking` (Phase 3, contract §9.8).
- Moving `cue.dev/x/k8s.io@v0`, `KUBERNETES_VERSION`, `language.version`, `CUE_VERSION`, the docs-kit
  pins or anything under `.github/` (contract §5.2 rule 14; workspace `RELEASING.md`, section
  "Pin classes": third-party pins are out of scope).
- Crossing to `opmodel.dev/core@v3`; the resolver only warns "new major available".
- Bringing `main` current. The supervisor's catch-up PR does that (contract §8).

## Decisions

### D1. Four tasks under `## Release cascade`, resolver found at task level

The four tasks go into `Taskfile.yml` right after `deps:release-check`, in a new
`## Release cascade` group. They share one YAML anchor for the resolver var (contract §3); no
global `vars:` entry is added, so no other task runs `git rev-parse`.

```yaml
  ## Release cascade
  #
  # The repo's half of the release cascade (workspace RELEASING.md, "The cascade";
  # Phase 2 cascade contract §5). Run every one with `task -x` to see the real
  # exit code: 0 moved, 3 nothing to do, anything else an error.

  deps:cascade:
    desc: Move core in src/ and .opm-cli-version to the newest published versions (working tree only)
    vars: &cascade_resolver
      CASCADE_RESOLVER_PATH:
        sh: |
          if [ -n "${CASCADE_RESOLVER:-}" ]; then
            case "$CASCADE_RESOLVER" in /*) ;; *) echo "CASCADE_RESOLVER must be absolute" >&2; exit 1 ;; esac
            printf '%s\n' "$CASCADE_RESOLVER"; exit 0
          fi
          common=$(git rev-parse --path-format=absolute --git-common-dir) || exit 1
          printf '%s\n' "$(dirname "$common")/../.github/.github/scripts/cascade/cascade-resolve.sh"
    env: &cascade_env
      CASCADE_RESOLVER: '{{.CASCADE_RESOLVER_PATH}}'
    preconditions: &cascade_pre
      - sh: test -x '{{.CASCADE_RESOLVER_PATH}}'
        msg: "cascade resolver not found: check out open-platform-model/.github beside this repo, or set CASCADE_RESOLVER"
    cmds:
      - bash .tasks/cascade/cascade.sh

  deps:cascade:title:
    desc: Print the cascade PR title computed from the diff against the base (exit 3 when there is no diff)
    vars: *cascade_resolver
    env: *cascade_env
    preconditions: *cascade_pre
    cmds:
      - '"$CASCADE_RESOLVER" title --classes .tasks/cascade/classes --pins .tasks/cascade/pins.sh'

  deps:cascade:body:
    desc: Print the cascade PR body (moved pins, triggering releases, warnings, Notes)
    vars: *cascade_resolver
    env: *cascade_env
    preconditions: *cascade_pre
    cmds:
      - '"$CASCADE_RESOLVER" body --classes .tasks/cascade/classes --pins .tasks/cascade/pins.sh'

  deps:cascade:test:
    desc: Test deps:cascade in sandbox copies against the contract stub (CASCADE_TEST_SET=offline|all)
    cmds:
      - bash .tasks/cascade/test.sh
```

`deps:cascade:test` takes neither the resolver var nor the precondition: each scenario exports
`CASCADE_RESOLVER` as the stub itself, and only S5 needs the real resolver (through
`CASCADE_RESOLVER_REAL`), so the offline set runs where no `.github` checkout exists. Whether a
YAML anchor on `vars:` survives go-task's own templating is checked in the spike (section 1); if
it does not, the block is repeated per task.

### D2. `pins.sh` reports two pins; `classes` is the contract map verbatim

`.tasks/cascade/pins.sh <WORKTREE|ref>` prints, in this order:

```text
opmodel.dev/core@v2	core	shipped	<v>	
github.com/open-platform-model/cli	opm CLI	release-tool	<v>	
```

- core is read from `src/cue.mod/module.cue` (on disk, or `git show <ref>:src/cue.mod/module.cue`)
  with the workspace idiom `grep -FA5 '"opmodel.dev/core@v2"' | grep -oP 'v:\s*"\K[^"]+' | head -n1`.
- the opm CLI is the single line of `.opm-cli-version`; a value that fails the CI shape regex is
  exit 1.
- A file missing at that ref omits its row (contract §4.1). No row carries a label:
  `need-human-review` is library only.

`.tasks/cascade/classes` is contract §5.3, verbatim:

```text
release-tool .opm-cli-version
shipped src/
```

There is no `test` row: the `@if(fixtures)` files live under `src/` and ship, so
`test(fixtures)` can never be this repo's title. Any other path falls through to `shipped`.

### D3. `cascade.sh`: resolve everything, then edit; no tool phase

`.tasks/cascade/cascade.sh` follows contract §5.2. In order:

1. **Clean start** (rule 1): refuse with exit 1 when `git status --porcelain --untracked-files=all`
   is non-empty, unless `CASCADE_ALLOW_DIRTY=1`, which records the contract's `snapshot`.
2. **State** (rule 2): `STATE=$(git rev-parse --git-dir)/cascade`, truncate `$STATE/warnings`,
   export `CASCADE_WARNINGS`.
3. **Steering files** (rule 3): `"$CASCADE_RESOLVER" check-files --repo-root .`.
4. **Registries** (rule 4): export `CUE_REGISTRY` and `OPM_REGISTRY` as
   `opmodel.dev=ghcr.io/open-platform-model,registry.cue.works`. catalog_opm resolves no
   `testing.opmodel.dev` fixture, so no prefix is added.
5. **Phase A, resolve** (rule 5), per pin, core first:
   - `is-frozen src/cue.mod/module.cue opmodel.dev/core@v2` (resp. `is-frozen .opm-cli-version
     github.com/open-platform-model/cli`): exit 0 skips the pin without resolving it, exit 3
     continues, anything else exits the task;
   - `newest cue opmodel.dev/core@v2 --current <v> --repo-root .` and
     `newest opm-cli --current <v> --repo-root .`, each with `--expect <v>` only when
     `CASCADE_EXPECT` carries `<pin-key>=<v>`; a `case` on the exit: 0 records the target,
     3 leaves the pin, anything else exits the task with that code;
   - when core will move: `language-of opmodel.dev/core@v2 <target>`, compared with
     `semver-cmp` against `CUE_VERSION` read from `.github/workflows/branch-publish.yml`
     (rule 10, D5). Newer upstream: a warning. Exit 3: no warning. Unreadable `CUE_VERSION`:
     a warning with key `-`.

   The hold is applied inside the resolver's `newest` (contract §2.8), so the task never calls
   `hold` itself. The `is-frozen` calls sit in phase A because they decide what phase C edits
   and only read; an error there leaves the tree untouched, like any phase A error.
6. **Phase B, tools:** none. catalog_opm has no version-advance module (no fixture module of its
   own, and `src/identity/identity.cue` belongs to `release.yml`), so no opm binary is prepared.
7. **Phase C, edit** (rule 12: shipped first, `.opm-cli-version` last):
   - core: record the `v:` of `cue.dev/x/k8s.io@v0`; in `src/`, `cue mod get
     opmodel.dev/core@<target>` then `cue mod tidy`, once; re-read the k8s `v:` and warn
     (`cue.dev/x/k8s.io@v0`: "tidy raised ...") if it changed, never reverting (rule 6). The
     only path named is `src/cue.mod/module.cue`.
   - opm CLI: `printf '%s\n' "<target>" > .opm-cli-version`.
8. **Result** (rule 13): exit 0 when `git status --porcelain --untracked-files=all` is non-empty
   (or the snapshot differs under `CASCADE_ALLOW_DIRTY=1`), else exit 3.

`set -euo pipefail` throughout; no `|| true`, no `2>/dev/null ||` fallback and no `set +e` around
a resolver or `cue` call. Frozen re-check after `tidy` (rule 8) is trivial here: the only OPM key in
the module is the one being moved, and a frozen core never reaches phase C.

### D4. No `INDEX.md` regeneration

Contract §6.1 says to regenerate `src/INDEX.md` if `generate:index:check` would fail after a core
move. `.tasks/generate-index.sh:29-35` reads only the `module:` line of `cue.mod/module.cue`, so a
dependency move cannot stale the index. The task therefore never runs `generate:index`. The spike
confirms it with `task generate:index:check` on a moved tree; if that ever fails, the cascade PR's
`Validate catalog` run shows it.

### D5. `language.version` is compared with `branch-publish.yml`'s `CUE_VERSION`

The pinned CUE version is `CUE_VERSION: 'v0.17.1'` at `.github/workflows/branch-publish.yml:24`,
read with `grep -oP "^\s*CUE_VERSION:\s*'\K[^']+"`. `ci.yml:38` installs the same `v0.17.1` inline;
the env is the single named source (contract §5.2 rule 10). The task reads the file and never
edits it.

### D6. Tests: contract §8 with catalog_opm's data

`.tasks/cascade/test.sh` implements contract §8 as written. catalog_opm's data:

- `testdata/older.tsv`: `opmodel.dev/core@v2` `v2.0.0-alpha.13` and
  `github.com/open-platform-model/cli` `v1.0.0-beta.4`, both published. No `pin-of` row: catalog_opm
  has no consistent set (contract §6.1).
- Current stub rows: `newest cue opmodel.dev/core@v2 <tree core>` and `newest opm-cli - <tree cli>`.
  No `published` rows (no version-advance module).
- `testdata/s1-calls.txt`: the normalized S1 call list: `check-files`, the two `is-frozen` calls and
  the two `newest` calls (no `language-of`, because nothing moves).
- S3 sets core's `newest` row to `ERROR` (core is the first pin resolved).
- S2's golden version-advance list is empty: after the run the copy equals the original tree.
- S4 freezes `src/cue.mod/module.cue` for `opmodel.dev/core@v2` (the only `cue.mod` file the task
  edits, as contract §8 notes); core stays at the older version byte for byte and the opm CLI still
  moves, exit 0.
- S5, with `CASCADE_RESOLVER_REAL` set after S2: the title is
  `fix(deps): bump core to <tree core> and opm CLI to <tree cli>` and the body holds both markers,
  two table rows, no `need-human-review`, and `## Notes` last.
- Sandbox commits use `git -c user.name=cascade-test -c user.email=cascade-test@localhost`, so a CI
  runner without a git identity can run them.

### D7. CI placement

- **Offline set** (required): a step `Test the cascade task (offline)` in `Validate catalog`, right
  after `Verify every fixture is behind the fixtures tag` (`ci.yml:61-63`) and before the GHCR
  login, running `task -x deps:cascade:test` with `CASCADE_TEST_SET: offline`. It needs `git`,
  `bash` and `yq` (ubuntu-latest ships mikefarah yq v4); no registry.
- **Network set** (not required): new `.github/workflows/cascade-task.yml`, job
  `Cascade task (network)`, `timeout-minutes: 20`, `permissions: contents: read`; triggers
  `pull_request` with paths `.tasks/cascade/**`, `Taskfile.yml` and the workflow file,
  `workflow_dispatch`, and a weekly `schedule`. Steps: checkout (the SHA `ci.yml:25` pins), a second
  checkout of `open-platform-model/.github` at `ref: main`, `path: org-github`,
  `persist-credentials: false`; setup-cue `v0.17.1` and setup-task (the SHAs `ci.yml:36,41` pin);
  then `task -x deps:cascade:test` with
  `CASCADE_RESOLVER_REAL: ${{ github.workspace }}/org-github/.github/scripts/cascade/cascade-resolve.sh`.
  catalog_opm has no `.tasks/*.yaml`, so that contract path is left out.

## Research & Decisions

### Which contract §9 choices apply here

**Context**: contract §9 asks each change to record the supervisor's choices it inherits.
**Explored**: contract §9.1 to §9.13 against catalog_opm's two pins.
**Decision**: these apply, unchanged:
- Phase 2 cascade contract §9.1: title and body come from the resolver (`deps:cascade:title` and
  `deps:cascade:body` are wrappers).
- Phase 2 cascade contract §9.2: retry budget and `--expect` wait live in the resolver; the task
  only forwards `--expect` from `CASCADE_EXPECT`.
- Phase 2 cascade contract §9.3: prereleases count only while the pin is a prerelease. core
  (`v2.0.0-beta.1`) and the opm CLI (`v1.0.0-beta.7`) are both on beta lines today.
- Phase 2 cascade contract §9.4: versions are `v`-prefixed everywhere; both pins are already
  stored that way, so no `v` is added or stripped.
- Phase 2 cascade contract §9.7: the Phase 2 gate is met after the supervisor's catch-up PR
  (tier 1, before library). Today it would move core `v2.0.0-beta.1` to `v2.0.0-beta.2`.
- Phase 2 cascade contract §9.8: no `deps-cascade:breaking` here.
- Phase 2 cascade contract §9.9: every caller runs `task -x`.
- Phase 2 cascade contract §9.12: offline set in `Validate catalog`, network set in
  `cascade-task.yml`.
- Phase 2 cascade contract §9.13: Notes are neutralized by the resolver's `body`.

These do not apply: §9.5 (cli docs bundle), §9.6 (fixture consumers), §9.10 (core ahead of a
catalog's pin; catalog_opm is core's direct consumer) and §9.11 (a core hold holding a catalog).
**Rationale**: catalog_opm is core's direct consumer with no consistent set and no fixture modules
of its own (contract §6.1).

### Spike: assumptions to confirm before the task is written

**Context**: four claims in this design are read from files or the contract, not run.
**Explored**: pending, section 1 of tasks.md.
**Decision**: confirm, in a contract §8 sandbox copy:
(a) `cue mod get opmodel.dev/core@<exact>` plus `cue mod tidy` in `src/` rewrites only the core `v:`
and leaves the k8s entry and the file layout byte-identical; (b) `task generate:index:check` passes
on the moved tree (D4); (c) the installed go-task and the CI `setup-task` `3.x` both pass an
`exit 3` through with `-x`, and a YAML anchor on `vars:` with an `sh:` var works per task (D1);
(d) `git commit` in a fresh `git init` needs the identity flags of D6.
**Rationale**: Mergeable Sections makes section 1 a spike whenever design.md carries an unverified
assumption. The findings replace this entry.

## Risks / Trade-offs

- [The opm CLI moves before core is published to the catalog's consumers] -> Both are one PR; the
  title is `fix(deps)` whenever `src/` moved and `ci(deps)` otherwise (resolver §4.3). A lone CLI
  bump never releases.
- [A new core release breaks the catalog (`vet`, `vet:fixtures`, the publish dry-run)] -> The task
  only edits; `Validate catalog` on the cascade PR runs every gate. A human fixes it on
  `deps/cascade` or adds a `.cascade-hold` entry with a reason and an expiry.
- [`cue mod tidy` raises `cue.dev/x/k8s.io@v0` because a newer core requires it] -> A warning in the
  body, never a revert. The reviewer then also runs `task generate:kinds` and moves
  `KUBERNETES_VERSION` (AGENTS.md § Dependencies), by hand.
- [Two writers of `.opm-cli-version` until Phase 5 (this task and workspace
  `task deps:pins:opm-cli`)] -> Both write the same one-line file from the same "newest release whose
  assets download" rule, so their results agree.
- [The network set depends on GHCR, registry.cue.works and GitHub downloads] -> It is not a required
  check; the offline set in the required job needs no network.
- [The resolver is not merged when this change is implemented] -> Sections 1 to 3 and the offline
  set use the contract §7 stub only. S5 and a manual `deps:cascade:title` run wait for `.github`
  `add-cascade-resolver`, and this PR merges after it.
- [The stub drifts from the contract] -> `test.sh` asserts its sha256 equals contract §7's
  `970130f7d55c07f5b86d4f5b6f392330427ff923eb34f93553656bcd4b893d9c`.

## Durable decisions

- The four cascade tasks, what `deps:cascade` moves and never touches, and that every caller runs
  `task -x`: `AGENTS.md` § Build And Dev Commands (four rows) and a § Release & publishing bullet.
- `.opm-cli-version` and the core pin have a second writer, `task deps:cascade`, beside the
  workspace root tasks: `AGENTS.md` § Release & publishing (amend the `.opm-cli-version` bullet at
  `AGENTS.md:227`).
- `.tasks/cascade/` holds the cascade scripts, and `testdata/stub-resolve.sh` is the contract stub,
  never edited in place: `AGENTS.md` § Repository Layout (the `.tasks/` line, `AGENTS.md:164`).
- The cascade never gives catalog_opm a `!` title; a core major crossing is a hand-made PR to
  `opm@v5`: stays with workspace `RELEASING.md` (section "Bump rule"); `AGENTS.md` links to it from
  the bullet above.
- D4 (no INDEX regeneration), D5 (the `CUE_VERSION` source) and D6 (test data): stay with the
  change; the scripts carry them as comments.
