## Why

The release cascade (workspace `RELEASING.md`, section "The cascade") has a receiver in each repo
run that repo's own `task deps:cascade`, which moves the repo's upstream pins and exits 0 (files
changed), 3 (nothing to do) or anything else (error). catalog_opm has no such task. Its two
upstream pins, core in `src/cue.mod/module.cue:13-15` and the opm CLI in `.opm-cli-version`, are
moved today by hand or by the workspace root `task deps:update` and `task deps:pins:opm-cli`.
The root `deps:update:modules` loop names every dep, `cue.dev/x/k8s.io@v0` included, so it cannot
be the cascade's engine (workspace `Taskfile.yml:63-116`, the `deps` list at `:79`). Phase 2 of the rollout (workspace
`RELEASING.md`, section "Rollout and changes") adds the task to each of the four consumer repos,
against one shared resolver in `.github`. This change is catalog_opm's part.

## What Changes

The binding interface is the Phase 2 cascade contract (version 1, kept durably in `open-platform-model/.github` as
`openspec/changes/add-cascade-resolver/contract.md`, which moves under `openspec/changes/archive/`
when that change is archived; cited below as
"contract §N"). Where it and workspace `RELEASING.md` disagree, `RELEASING.md` wins.

- **Four new Taskfile tasks** (contract §5.1): `deps:cascade`, `deps:cascade:title`,
  `deps:cascade:body` and `deps:cascade:test`. They find the resolver through the env
  `CASCADE_RESOLVER` or the sibling `.github` checkout (contract §3), declared at task level,
  never as a global var.
- **`deps:cascade` moves exactly two pins** (workspace `RELEASING.md`, section "What each repo's
  task moves"; contract §6.1):
  - core (`opmodel.dev/core@v2`, shipped class) to `newest cue opmodel.dev/core@v2`, written by
    `cue mod get opmodel.dev/core@<v>` then `cue mod tidy`, in `src/` only;
  - the opm CLI (`.opm-cli-version`, release-tool class) to `newest opm-cli`, written as one line.
  It never names `cue.dev/x/k8s.io@v0`, never touches `src/identity/identity.cue`, `src/RELEASE`,
  the release-please files, `.opm-docs-version`, `language.version` or anything under `.github/`,
  and honours `.cascade-frozen` and `.cascade-hold` (both absent today, which means empty).
- **New files under `.tasks/cascade/`:** `cascade.sh` (the task), `pins.sh` (reports the two
  pins at a ref), `classes` (the path-class map, verbatim from contract §5.3), `test.sh`, and
  `testdata/{stub-resolve.sh,older.tsv,s1-calls.txt}`. `stub-resolve.sh` is the contract §7 stub,
  byte for byte.
- **Tests** (contract §8): the offline set (stub checksum, `pins.sh` agreement, S1 no-op, S3 error,
  S6 dirty tree) becomes a step in the required `Validate catalog` job (`ci.yml:20-23`). The
  network set (S2 older pins, S4 frozen, S5 title and body against the real resolver) runs in a new,
  non-required workflow `.github/workflows/cascade-task.yml`.
- **`AGENTS.md`** gains the four tasks in § Build And Dev Commands, the `.tasks/cascade/` entry
  in § Repository Layout, and a § Release & publishing bullet saying `deps:cascade` is the second
  writer of `.opm-cli-version` and the core pin.

**Not in this change:** the receive workflow, the notify job and the `deps/cascade` branch logic
(catalog_opm `join-release-cascade`, Phase 3); the label `deps-cascade:breaking` (computed in
Phase 3, contract §9.8); the catch-up PR that brings `main` current before the Phase 2 gate is
judged (opened by the supervisor, contract §8); any change to the workspace root `.tasks/deps/`
scripts (rewired in Phase 5).

## Before / After

No catalog member changes, so there is no CUE member to show. The CUE the task writes is the core
entry of `src/cue.mod/module.cue`; nothing else in the file moves.

**Before** (`src/cue.mod/module.cue:8-16` on `main`, moved by hand)

```cue
deps: {
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.12.0"
		default: true
	}
	"opmodel.dev/core@v2": {
		v: "v2.0.0-beta.1"
	}
}
```

**After** (`task -x deps:cascade` when GHCR serves core `v2.0.0-beta.2`; exit 0)

```cue
deps: {
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.12.0" // never named; a tidy that raises it is a warning, not a revert
		default: true
	}
	"opmodel.dev/core@v2": {
		v: "v2.0.0-beta.2" // newest published in @v2; never @v3, never backwards
	}
}
// .opm-cli-version: one line, the newest cli release whose tarball and checksums.txt download
// A second run on that tree exits 3 and changes nothing.
```

## Impact

- **Published catalog: none.** No file under `src/` changes in this change. Every section commit is
  a non-releasing type (`ci(cascade)`, `chore(openspec)`), so `opm` (stable 4.x line) does not
  advance and no member moves to a new `apiVersion` segment. The PR title is
  `ci(cascade): add the deps:cascade tasks` (contract §10).
- **The cascade PRs the task later feeds** are typed by the resolver from the diff: `fix(deps)`
  when `src/` moved, `ci(deps)` when only `.opm-cli-version` moved, never `!` (workspace
  `RELEASING.md`, section "Bump rule": a catalog major crossing is hand-made).
- **modules fleet, subscribing platforms, cli fixtures under `testing.opmodel.dev`:** nothing to do.
  They see a catalog release only when a later cascade PR moves core and a human merges it.
- **Workspace root tasks** keep writing these pins until the Phase 5 rewire, and they do not
  follow the cascade's rules: `task deps:pins:opm-cli` (`.tasks/deps/opm-cli.sh`) writes whatever
  `latest-tag.sh` returns and never reads `.cascade-hold` or `.cascade-frozen`, and
  `task deps:update` (`deps:update:modules`, workspace `Taskfile.yml:63-116`) also moves core and
  `cue.dev/x/k8s.io@v0` in `src/`, with errors swallowed by `|| true`. `AGENTS.md` says so (task
  3.4); a human running them bypasses holds and frozen entries.
- **CI:** `Validate catalog` gains one offline step (seconds, no registry). The new network job is
  not a required check, so a GHCR blip never blocks an unrelated PR.

**Depends on / gates:**

- Depends on: `.github` `add-cascade-resolver` **merged first**. This PR merges only after it, once
  S5 (title and body) and the title and body tasks pass against the merged resolver (contract §10).
  Until then sections 1 to 3 and the offline set run against the stub.
- Depends on: catalog_opm `prepare-release-cascade` (merged, archived
  `openspec/changes/archive/2026-10-02-prepare-release-cascade`): `.opm-cli-version` and the
  `deps/**` branch-publish exclusion.
- Gates: catalog_opm `join-release-cascade` (Phase 3), whose receiver runs `task -x deps:cascade`.
- Gates: workspace Phase 5 rewire of `task deps:update`.
- Gates: the Phase 2 exit gate for catalog_opm, judged after the supervisor's catch-up PR
  (contract §8, tier 1, before library).
- Peers (same phase, independent): library, opm-operator and cli `add-deps-cascade-task`.

## Enhancement

None. The design lives in workspace `RELEASING.md` (sections "The cascade", "What each repo's
task moves", "Cascade files") and the Phase 2 cascade contract. No enhancement backs it, so there
is no `enhancement.yaml`.
