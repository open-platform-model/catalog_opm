## Why

Two pieces of prose in this repo claim more than is true.

**The release backstop.** `publish-cue` re-runs `task vet:fixtures` on the checked-out tag before
it publishes (design of the archived `gate-and-tag-fixtures`, supervisor amendment of 2026-10-03).
The comment above that step in `.github/workflows/release.yml` (lines 227-233 at `daae275`) ends
"On the normal path the gate already passed on this commit, so this cannot fail." It can: the
fixture exports resolve `opmodel.dev/core` from GHCR and `cue.dev/x/k8s.io` from
`registry.cue.works`, so a transient registry error fails the step after release-please has
already pushed the tag and created the GitHub Release. Nothing tells the operator to re-run the
job, or what a second failure means. `AGENTS.md` § Release & publishing (line 230) describes the
label-removal recovery and says "the next release PR carries the fix", but not that release-please
opens a release PR only for a user-facing commit under `src/`, and not what that next release PR
proposes. The owner decided the follow-up (walkthrough follow-up w1-03): name the transient
registry failure, and say the fix must be a release-class commit.

**What `cue vet` checks in hidden fields.** Five places say `cue vet`, "including `-c`", does not
check hidden fields, or "does not descend into hidden fields at all". That is half true. `cue vet`
evaluates the hidden fields of the package it vets, so an error-class conflict there fails it
(measured in the j2 experiment with `_boom: 1 & 2`, and already admitted in the same `AGENTS.md`
bullet). What it does not report is a hidden field that stays incomplete, with or without `-c`.
That gap is why `task vet:fixtures` exports each fixture. The supervisor folded this wave-1
follow-up of `gate-and-tag-fixtures` into this change (SD14).

## What Changes

- **`.github/workflows/release.yml`**: the backstop comment says the step can fail on the normal
  path only on a transient registry error, that the tag and Release then already exist, and that
  the recovery is to re-run the job. It also says the first error line under each FAIL names the
  cause, and that a re-run failing on a fixture rather than the registry means the version is
  burned, pointing to `AGENTS.md`. No step changes.
- **`AGENTS.md` § Release & publishing**: the same transient-error sentence, and the recovery rule
  after a failed gate or a failed backstop. The fix always lands as a user-facing commit
  (`feat`/`fix`/`perf`/`revert`) that touches `src/`. After a burned version release-please
  otherwise opens no release PR; the `release-as` key only chooses the version and needs that
  commit too. After a skipped version (label removed), the next release PR proposes a major bump
  (5.0.0 today, on a module whose path is major v4) and its notes re-list everything since `bootstrap-sha`; the
  bullet says it must not be merged as proposed unless the fix PR set `last-release-sha` to the skipped merge commit. The text states each rule itself and cites no
  design decision number.
- **Hidden-field prose**: `AGENTS.md` (the `task vet:fixtures` row and the Transformer fixtures
  bullet), `Taskfile.yml` (`vet:fixtures` description), `.tasks/fixtures.sh` (the "WHY cue
  export" comment) and `src/transformers/role_transformer_fixtures.cue` (the comment above
  `_testUnboundClusterRoleSpec`) say what was measured: vet fails on a conflict in a hidden
  field of the package it vets, but passes one that stays incomplete, `-c` included.

Not in this change:

- A retry loop around `task vet:fixtures` in `publish-cue`. The plan entry lists it as optional;
  the owner decided wording only.
- The archived `2026-10-03-gate-and-tag-fixtures/design.md` keeps its "cannot fail" text. The
  archive is a record; `AGENTS.md` carries the correction.
- Any workflow behaviour change. The gate comment in the `release-please` job gains only the
  registry-versus-fixture rule and the `last-release-sha` skip remedy (supervisor triage SD20).

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is prose.

**Before** (`release.yml`, `publish-cue`)

```yaml
      # ... Checking the tag
      # here burns that version (tag and Release, no GHCR artifact) instead of
      # publishing the tree the gate refused. On the normal path the gate
      # already passed on this commit, so this cannot fail.
```

**After**

```yaml
      # ... Checking the tag
      # here burns that version (tag and Release, no GHCR artifact) instead of
      # publishing the tree the gate refused. On the normal path the gate
      # already passed on this commit, so this step can fail only on a
      # transient registry error (core from GHCR, cue.dev/x/k8s.io from
      # registry.cue.works). The tag and Release exist by then: re-run this
      # job. The first error line under each FAIL names the cause. If the
      # re-run fails on a fixture rather than the registry, the version is
      # burned; see AGENTS.md, Release & publishing (the fix must be a
      # feat/fix/perf/revert commit under src/).
```

**Before** (`AGENTS.md`, Transformer fixtures bullet)

```text
`cue vet`, including `cue vet -c`, does not descend into hidden fields at all
```

**After**

```text
`cue vet` evaluates the hidden fields of the package it vets and fails on an error-class
conflict in one, but passes one that stays incomplete, with or without `-c`
```

## Impact

- **Published catalog: none in behaviour.** The only file under `src/` that changes is a comment
  in `role_transformer_fixtures.cue`, a file tagged with the `fixtures` if build attribute. No
  member, no constraint and no `apiVersion` segment changes. Section 1 commits as `ci(release)`,
  section 2 as `docs`, both hidden types, so `opm` does not advance. PR title:
  `ci: reword the release backstop`.
- **modules fleet, subscribing platforms, cli fixtures under `testing.opmodel.dev`:** nothing to
  do.
- **Release operators:** a red `publish-cue` on the backstop step now says to re-run and how to
  tell a registry error from a burned version, and `AGENTS.md` says which commit re-opens the
  release PR and that the release PR after a skip must not be merged as proposed unless the fix PR set `last-release-sha` to the skipped merge commit.
- **Serialization:** builds on catalog_opm#146 (`ci: harden the release workflows`, merged as
  `daae275`), which also edits `release.yml`. `origin/main` has since moved to `344ad4f`
  (catalog_opm#151); its hunks in `release.yml` and `AGENTS.md` do not overlap this change, and a
  rebase was refused by a hook in this session, so the branch stays on `daae275` until PR time.
  The open release PR #145 (opm 4.7.0) belongs to other sessions and is not touched.

## Enhancement

None. The source is the kernel-plan beta.1 walkthrough (follow-up w1-03, owner decision) and the
supervisor's wave-2 decision SD14; no enhancement backs it, so there is no `enhancement.yaml`.
