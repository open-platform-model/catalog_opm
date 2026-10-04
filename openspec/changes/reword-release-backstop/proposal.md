## Why

Two pieces of prose in this repo claim more than is true.

**The release backstop.** `publish-cue` re-runs `task vet:fixtures` on the checked-out tag before
it publishes (design of the archived `gate-and-tag-fixtures`, supervisor amendment of 2026-10-03).
The comment above that step in `.github/workflows/release.yml` (lines 227-233 at `daae275`) ends
"On the normal path the gate already passed on this commit, so this cannot fail." It can: the
fixture exports resolve `opmodel.dev/core` from GHCR, so a transient registry error fails the step
after release-please has already pushed the tag and created the GitHub Release. Nothing tells the
operator to re-run the job. `AGENTS.md` § Release & publishing (line 230) describes the
label-removal recovery and says "the next release PR carries the fix", but not that release-please
opens a release PR only for a user-facing commit under `src/`. A hidden-type fix after a burned
version therefore opens nothing. The owner decided the follow-up (walkthrough follow-up w1-03):
name the transient GHCR failure, and say the fix must be a release-class commit.

**What `cue vet` checks in hidden fields.** Five places say `cue vet`, "including `-c`", does not
check hidden fields, or "does not descend into hidden fields at all". That is half true. When
`cue vet` loads a package as the main instance it evaluates its hidden fields, so an error-class
conflict there fails it (measured in the j2 experiment with `_boom: 1 & 2`, and already admitted
in the same `AGENTS.md` bullet). What it does not report is a hidden field that stays
incomplete, with or without `-c`. That gap is why `task vet:fixtures` exports each fixture. The
supervisor folded this wave-1 follow-up of `gate-and-tag-fixtures` into this change (SD14).

## What Changes

- **`.github/workflows/release.yml`**: the backstop comment says the step can fail on the normal
  path only on a transient registry error, that the tag and Release then already exist, and that
  the recovery is to re-run the job. No step changes.
- **`AGENTS.md` § Release & publishing**: the same transient-error sentence, and the recovery rule
  after a burned or skipped version. The fix lands as a user-facing commit
  (`feat`/`fix`/`perf`/`revert`) that touches `src/`, or release-please opens no release PR after
  a burned version. The `release-as` key only chooses the version and needs that commit too. The
  bullet also says what the next release PR's notes contain after a skipped version (design D3).
- **Hidden-field prose**: `AGENTS.md` (the `task vet:fixtures` row and the Transformer fixtures
  bullet), `Taskfile.yml` (`vet:fixtures` description), `.tasks/fixtures.sh` (the "WHY cue
  export" comment) and `src/transformers/role_transformer_fixtures.cue` (the comment above
  `_testUnboundClusterRoleSpec`) say what was measured: vet fails on a conflict in a hidden
  field, but passes one that stays incomplete, `-c` included.

Not in this change:

- A retry loop around `task vet:fixtures` in `publish-cue`. The plan entry lists it as optional;
  the owner decided wording only.
- The archived `2026-10-03-gate-and-tag-fixtures/design.md` keeps its "cannot fail" text. The
  archive is a record; `AGENTS.md` carries the correction.
- Repairing the changelog of the release PR after a skipped version (design D3). This change
  states the behaviour; choosing a remedy is the owner's call.
- The gate step in the `release-please` job: it runs before any tag, so a transient failure there
  costs only a re-run, and its comment makes no false claim.

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
      # transient registry error (the exports resolve core from GHCR). The tag
      # and Release exist by then: re-run this job.
```

**Before** (`AGENTS.md`, Transformer fixtures bullet)

```text
`cue vet`, including `cue vet -c`, does not descend into hidden fields at all
```

**After**

```text
`cue vet` evaluates a hidden field and fails on an error-class conflict in it, but passes a
hidden field that stays incomplete, with or without `-c`
```

## Impact

- **Published catalog: none in behaviour.** The only file under `src/` that changes is a comment
  in `role_transformer_fixtures.cue`, an `@if(fixtures)` file. No member, no constraint and no
  `apiVersion` segment changes. Section 1 commits as `ci(release)`, section 2 as `docs`, both
  hidden types, so `opm` does not advance. PR title: `ci: reword the release backstop`.
- **modules fleet, subscribing platforms, cli fixtures under `testing.opmodel.dev`:** nothing to
  do.
- **Release operators:** a red `publish-cue` on the backstop step now says to re-run, and
  `AGENTS.md` says which commit type re-opens the release PR after a burned version.
- **Serialization:** builds on catalog_opm#146 (`ci: harden the release workflows`, merged as
  `daae275`), which also edits `release.yml`. The open release PR #145 (opm 4.7.0) belongs to
  other sessions and is not touched.

## Enhancement

None. The source is the kernel-plan beta.1 walkthrough (follow-up w1-03, owner decision) and the
supervisor's wave-2 decision SD14; no enhancement backs it, so there is no `enhancement.yaml`.
