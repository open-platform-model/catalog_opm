## 1. Spike: confirm the design's unverified assumptions

- [x] 1.1 Build a contract §8 sandbox copy of the tree in a scratch directory (never a `git worktree`, never the real checkout). Text-edit the core `v:` in `src/cue.mod/module.cue` to `v2.0.0-alpha.13`, commit it, then in `src/` with `CUE_REGISTRY='opmodel.dev=ghcr.io/open-platform-model,registry.cue.works'` run `cue mod get opmodel.dev/core@<the tree's core>` and `cue mod tidy`. Confirm `src/cue.mod/module.cue` equals the original byte for byte (k8s entry and layout untouched) (design, spike (a))
- [x] 1.2 In the same copy, confirm `task generate:index:check` passes after a core move to the newest published core (design D4, spike (b))
- [x] 1.3 Confirm with the installed go-task (3.52.0, confirmed by the plan review), and with the newest 3.x release that `setup-task` `version: 3.x` installs, that `task -x` returns 3 from a `bash` cmd that exits 3, and that a YAML anchor on a task-level `vars:` map with an `sh:` var resolves per task (design D1, spike (c)); if the anchor does not work, record that D1 repeats the block per task
- [x] 1.4 Confirm a fresh `git init` copy commits with `git -c user.name=cascade-test -c user.email=cascade-test@localhost` and an empty `HOME` (design D6, spike (d))
- [x] 1.5 Replace the design's "Spike" Research entry with the findings and adjust D1, D4 or D6 if a finding differs
- [x] 1.6 `openspec validate add-deps-cascade-task --strict` and `task check` green, then commit `chore(openspec): record the add-deps-cascade-task spike findings`

## 2. Pin report, class map, stub and the title and body tasks

- [x] 2.1 `.tasks/cascade/classes`: contract §5.3's catalog_opm map verbatim, with a header comment naming the contract section (design D2)
- [x] 2.2 `.tasks/cascade/pins.sh` (mode 0755, `set -euo pipefail`): `WORKTREE` or a git ref; prints the two TSV rows of design D2 in that order; omits a row whose file is missing at the ref or whose `src/cue.mod/module.cue` has no core key (`grep -qF` first, so `set -euo pipefail` never fails on a missing key); exit 1 on a core key with an unparsable `v:` and on a malformed `.opm-cli-version`
- [x] 2.3 `.tasks/cascade/testdata/stub-resolve.sh` (mode 0755): the contract §7 stub byte for byte; `sha256sum` prints `970130f7d55c07f5b86d4f5b6f392330427ff923eb34f93553656bcd4b893d9c`
- [x] 2.4 `Taskfile.yml`: add the `## Release cascade` group after `deps:release-check` with the shared resolver anchor and the tasks `deps:cascade:title` and `deps:cascade:body` (design D1)
- [x] 2.5 `.tasks/cascade/pins.sh WORKTREE` and `.tasks/cascade/pins.sh HEAD` print the same two rows on the clean tree; `shellcheck .tasks/cascade/pins.sh` is clean; `CASCADE_RESOLVER=/nonexistent/cascade-resolve.sh task -x deps:cascade:title` fails on the precondition message, and `CASCADE_RESOLVER=relative/path task -x deps:cascade:title` fails with "CASCADE_RESOLVER must be absolute" (both independent of whether a sibling `.github` checkout has the resolver)
- [x] 2.6 `AGENTS.md`: the § Repository Layout `.tasks/` line (`:164`) names `cascade/` and says `testdata/stub-resolve.sh` is the contract stub, never edited in place; § Build And Dev Commands gains rows for `deps:cascade:title` and `deps:cascade:body` (design, Durable decisions)
- [x] 2.7 `task check` green, then commit `ci(cascade): add the cascade pin report, class map and title and body tasks`

## 3. `task deps:cascade`

- [x] 3.1 `.tasks/cascade/cascade.sh` (mode 0755): clean start, state directory, `check-files`, registries, phase A (`is-frozen` per pin, `newest` with `--expect` from `CASCADE_EXPECT`, and when core moves `language-of` against `branch-publish.yml`'s `CUE_VERSION` plus `is-frozen src/cue.mod/module.cue <key>` for every other dep key), phase C (core by `cue mod get opmodel.dev/core@<v>` and one `cue mod tidy` in `src/`; a frozen key raised by `tidy` is exit 1, an unfrozen one a warning; then `.opm-cli-version` last), and the result by `git status` or snapshot (design D3, D5; contract §5.2)
- [x] 3.2 `Taskfile.yml`: add `deps:cascade` with the anchor, the env and the precondition (design D1)
- [x] 3.3 `shellcheck .tasks/cascade/*.sh` is clean. `grep -nE '\|\| *true|2>/dev/null *\|\||set \+e' .tasks/cascade/cascade.sh` prints nothing. In a contract §8 sandbox copy of the tree (the section 3 files are not committed yet, so the real checkout would hit the clean-start refusal), against the stub with a hand-built table of the tree's own versions, `task -x deps:cascade` exits 3 and leaves the copy's `git status --porcelain` empty; in the real checkout, `CASCADE_ALLOW_DIRTY=1` with the same table exits 3 and leaves `git status --porcelain` unchanged
- [x] 3.4 `AGENTS.md`: a § Build And Dev Commands row for `deps:cascade` (what it moves, exit codes, `task -x`); amend the `.opm-cli-version` bullet in § Release & publishing (`:227`) to name `task deps:cascade` as the second writer of it and of the core pin, say that until the Phase 5 rewire the workspace root `task deps:pins:opm-cli` and `task deps:update` ignore `.cascade-hold` and `.cascade-frozen` and that root `deps:update` also moves `cue.dev/x/k8s.io@v0`, list what the task never touches, and point to workspace `RELEASING.md` "Bump rule" for the no-`!` rule (design, Durable decisions)
- [x] 3.5 `.gitignore`: add `.claude/worktrees/`, so the clean-start check (contract §5.2 rule 1) never refuses in a checkout that holds worktrees on a machine without that line in `.git/info/exclude`
- [x] 3.6 `task check` green, then commit `ci(cascade): add task deps:cascade`

## 4. Tests and CI

- [x] 4.1 `.tasks/cascade/testdata/older.tsv` (core `v2.0.0-alpha.13`, opm CLI `v1.0.0-beta.4`) and `.tasks/cascade/testdata/s1-calls.txt` (the normalized S1 call list) (design D6)
- [x] 4.2 `.tasks/cascade/test.sh` (mode 0755): the stub checksum and `pins.sh` agreement checks, then S1, S3, S6 (`offline`) and S2, S4, S5 (`all`), each in a contract §8 sandbox with a `trap` cleanup, the stub tables built at test time, `CASCADE_BASE` a SHA, `CASCADE_TODAY=2026-10-03`, and the git identity flags of design D6; prints `PASS`/`FAIL` per scenario and exits 0 or 1
- [x] 4.3 `Taskfile.yml`: add `deps:cascade:test` (design D1)
- [x] 4.4 `.github/workflows/ci.yml`, job `ci`: add the step `Test the cascade task (offline)` after `Verify every fixture is behind the fixtures tag`, running `task -x deps:cascade:test` with `CASCADE_TEST_SET: offline` and no resolver var (design D7; contract v1.1 C7)
- [x] 4.5 `.github/workflows/cascade-task.yml`: job `Cascade task (network)` as design D7, with the `.github` checkout at `path: org-github` and `CASCADE_RESOLVER_REAL` set to the checked-out resolver
- [x] 4.6 Locally: `CASCADE_TEST_SET=offline task -x deps:cascade:test` exits 0 with no network; `task -x deps:cascade:test` exits 0 with every scenario `PASS`, and S5 runs with `CASCADE_RESOLVER_REAL` set to the merged `.github` resolver's `cascade-resolve.sh` (until `.github` `add-cascade-resolver` merges, its branch worktree's `cascade-resolve.sh`); `git status --porcelain` is unchanged by the run
- [x] 4.7 `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7 .github/workflows/*.yml` exits 0; `shellcheck .tasks/cascade/*.sh` is clean
- [x] 4.8 `AGENTS.md` § Build And Dev Commands: a row for `deps:cascade:test` (sets, where each runs) (design, Durable decisions)
- [x] 4.9 `task check` green, then commit `ci(cascade): test deps:cascade offline in CI and on the network weekly`

## 5. Archive

- [ ] 5.1 Run `openspec verify` for `add-deps-cascade-task` (the `opsx:verify` skill) and confirm every Durable decision is landed in `AGENTS.md`
- [ ] 5.2 Archive the change on this branch with `--skip-specs`, so the archive rides the implementing PR; never push to main (owner decision 2026-10-01, workspace `RELEASING.md`, Owner settings)
- [ ] 5.3 `openspec validate --all --strict` green, then commit `chore(openspec): archive add-deps-cascade-task`
