## Context

No catalog member and no `apiVersion` segment changes. The change edits comments and prose in
`.github/workflows/release.yml`, `AGENTS.md`, `Taskfile.yml`, `.tasks/fixtures.sh` and
`src/transformers/role_transformer_fixtures.cue`.

Sources, highest authority first: the owner's walkthrough decision for follow-up w1-03 ("catalog
backstop wording (transient GHCR error; the fix must be release-class)"), the supervisor's wave-2
decision SD14 (fold the `gate-and-tag-fixtures` follow-up on hidden-field prose into this change),
and the wave-2 plan entry `cat-backstop` with its research and critic notes, and the plan review
of this change.

State at `origin/main` `daae275` (after catalog_opm#146). `origin/main` has since moved to
`344ad4f` (catalog_opm#151, the cascade pin); it edits `release.yml:373` and other `AGENTS.md`
lines, and every line cited below is unchanged there.

- `release.yml:227-233`: the backstop comment in `publish-cue` ends "so this cannot fail".
  `:244-245` runs `task vet:fixtures` on the tag. The plan entry pointed at `:207-209`; the critic
  corrected it, and #146 did not move the block.
- `release.yml:62-72` and `:87-88`: the gate in the `release-please` job, before the action that
  pushes the tag. Its comment is accurate and stays.
- `AGENTS.md:230`: the release-path bullet, ending in the label-removal recovery and the backstop.
- `AGENTS.md:201`, `:300`, `Taskfile.yml:71-73`, `.tasks/fixtures.sh:18-20`,
  `src/transformers/role_transformer_fixtures.cue:288-289`: the hidden-field claim.
  `docs/site/extending/write-a-transformer.md:37` was already corrected by `gate-and-tag-fixtures`.

## Goals / Non-Goals

**Goals:**

- A reader of a red backstop step knows that a transient registry error is the only normal-path
  cause, that re-running the job is the recovery, and what a second failure on a fixture means.
- `AGENTS.md` says which commit re-opens the release PR after a failed gate or backstop, and that
  the release PR after a skipped version must not be merged as proposed.
- Every live statement about `cue vet` and hidden fields matches what was measured.

**Non-Goals:**

- A retry loop around the backstop (optional in the plan entry, not decided by the owner).
- Edits to archived changes.
- A remedy for the release PR after a skipped version (D3): an open question for the owner.

## Decisions

### D1. Backstop comment: one cause, one recovery, and how to tell them apart

The comment keeps its first sentences and replaces "so this cannot fail" with:

```yaml
      # publishing the tree the gate refused. On the normal path the gate
      # already passed on this commit, so this step can fail only on a
      # transient registry error (core from GHCR, cue.dev/x/k8s.io from
      # registry.cue.works). The tag and Release exist by then: re-run this
      # job. The first error line under each FAIL names the cause. If the
      # re-run fails on a fixture rather than the registry, the version is
      # burned; see AGENTS.md, Release & publishing (the fix must be a
      # feat/fix/perf/revert commit under src/).
```

"Re-run this job" is enough: `publish-cue` reads `opm_tag_name` and `opm_version` from the
`release-please` job's outputs (`release.yml:197`, `:254`), which "Re-run failed jobs" keeps.
Re-running publishes the same tag; it cuts no new version. Both causes end in the same summary
line (`.tasks/fixtures.sh:82`, "N of N rendered-output fixtures do not evaluate"); only the first
error line printed under each FAIL (`.tasks/fixtures.sh:77-78`) separates a registry error from a
conflict, so the comment points the reader there. Both registries matter:
`src/cue.mod/module.cue` depends on `cue.dev/x/k8s.io`, which resolves from `registry.cue.works`.

### D2. The fix after a failed gate or backstop is always a user-facing commit under `src/`

The owner's rule (w1-03) is unconditional, and this change states it that way: after a failed gate
or a failed backstop, the fix lands as a `feat`, `fix`, `perf` or `revert` commit (the visible
types in `release-please-config.json`) that touches `src/` (release-please ignores commits outside
the package path, `AGENTS.md` "Forced version").

On the burned path it is also mechanically required. Tag and Release exist, no GHCR artifact;
release-please finds that Release (its manifest version matches the tag) and counts commits from
its SHA. With only hidden commits since, it logs "No user facing commits" and opens no release PR,
so the fix never ships.

On the skipped path a hidden-type fix would open a release PR, but only through the bootstrap walk
in D3, which proposes a wrong version. `AGENTS.md` does not document reliance on that walk.

The plan entry also offered "or carry Release-As". In this repo that is not an alternative. A
`Release-As:` footer never reaches `main` (`AGENTS.md` "Squash message"), and the `release-as`
config key only picks the version: it still needs a user-facing commit under `src/`. `AGENTS.md`
says so instead of naming Release-As as a way out.

### D3. After a skipped version, the next release PR proposes a major bump

The plan entry's research said that after the label is removed, "the skipped version's entries
appear only in `CHANGELOG.md`", with the merge commit treated as released. Reading
release-please 17.3.0 (the version `release-please-action` v4.4.1 locks), `src/manifest.ts`
"Collecting release commit SHAs":

1. It looks for a GitHub Release whose tag version equals the manifest version. The skipped
   release PR wrote that version into `.release-please-manifest.json` but was never tagged, so
   none matches.
2. `backfillReleasesFromTags` looks for the tag `opm-v<that version>`; there is none.
3. `needsBootstrap` is then true (`manifest.ts:611`), and commit collection walks back to
   `bootstrap-sha` (`9e93ecc`, the 0.6.0 release in June 2026, `manifest.ts:660`).
4. The latest release is backfilled from the manifest version with an empty SHA, and
   `commitsAfterSha(..., undefined)` keeps every collected commit (`manifest.ts:1808-1817`).

Since `9e93ecc` five `feat!:` commits touch `src/`: `c0cd3ec`, `38ae2f1`, `8a5c484`, `eab9b12` and
`e92248f`. The next release PR therefore proposes a major bump from the skipped version (5.0.0
from 4.7.0 today), on a module whose import path is major v4, and its notes re-list every
user-facing commit under `src/` since 0.6.0. This is the same failure class `AGENTS.md` records
for the `RELEASE` stamp (the bogus "release opm 2.0.0" PR after `opm-v3.0.0`). The `Release-As`
footers since `9e93ecc` (`37d2771`, `089c2dd`, `75d61f8`) touch nothing under `src/`, so they are
not resurrected.

`AGENTS.md` states this so an operator does not merge that PR: it must not be merged as proposed
until a remedy is applied. The remedy is not decided. The plan review recommends the repo's
"Forced version" set-then-drop pattern with `last-release-sha` (checked before the bootstrap
branch, `manifest.ts:655`) set to the skipped release PR's merge commit, dropped after the next
release; alternatives are `release-as` with hand-edited notes, or moving `bootstrap-sha` forward
after every release. That choice is the owner's and is an open question in the report;
`AGENTS.md` says the remedy needs a maintainer decision. This is read from source, not run
against a real release.

### D4. Hidden fields: what `cue vet` checks

Measured facts (cue v0.17.1):

- `cue vet` evaluates the hidden fields of the package it vets (loaded as the main instance), so
  an error-class conflict there fails it: `_boom: 1 & 2` in `transformers` failed `cue vet ./...`
  (j2 experiment, 2026-10-02), and a golden set to `"WRONG"` failed `cue vet -t fixtures ./...`
  (`gate-and-tag-fixtures` review). Hidden fields of an imported package stay lazy when only its
  definitions are referenced (j2), hence the scope.
- It does not report a hidden field that stays incomplete, plain or with `-c`: a hidden rule-1
  gate case in core exits 0 under both (wave-1 core review), and 44 of 47 fixtures failed export
  in 2026-09 while vet passed.
- Fixtures sit in files tagged with the `fixtures` if build attribute, so only
  `cue vet -t fixtures` loads them; `task vet` runs both views.

Each of the five sites gets that wording, kept to its local length:

| Site | New claim |
| --- | --- |
| `AGENTS.md:201` (`task vet:fixtures` row) | `cue vet`, `-c` included, fails on a conflict in a hidden field but passes one that stays incomplete; `cue export` forces it concrete |
| `AGENTS.md:300` (Transformer fixtures) | replace "does not descend into hidden fields at all" with the D4 claim, scoped to the package vet loads; the rest of the bullet already says the two checks are complementary |
| `Taskfile.yml:71-73` (`vet:fixtures` desc) | `cue vet` (including `-c`) passes a hidden field that stays incomplete |
| `.tasks/fixtures.sh:18-20` | `cue vet`, including `-c`, does not report an incomplete hidden field (it does fail on a conflict in one) |
| `role_transformer_fixtures.cue:288-289` | "cue vet skips hidden fields" becomes "cue vet passes an incomplete hidden field" |

Section 2 re-measures both facts in a scratch copy before editing, so the new prose is checked
against cue v0.17.1 on this tree, not only against the earlier reports.

Re-measured 2026-10-04 (cue v0.17.1, core v2.0.0-beta.1), matching the claims above: the golden
`data: mesh` of `_testConfigMapNamingTransformer` set to `"WRONG"` failed
`cue vet -t fixtures ./...` (exit 1, conflicting values) while plain `cue vet ./...` exited 0 (the
tagged file is left out); an added `_testZZIncomplete` (the configmap `#transform` without
`#moduleInstance` and `#context`) passed `cue vet -t fixtures ./...` and
`cue vet -c -t fixtures ./transformers` (exit 0) and failed
`cue export -t fixtures -e _testZZIncomplete ./transformers` (exit 1, `#moduleInstance` incomplete).

## Research & Decisions

### Where the backstop wording lives after #146

**Context**: The plan entry cited `release.yml:207-209`; the critic said `:227-233`; #146 merged
since.
**Explored**: `grep -n 'cannot fail' .github/workflows/release.yml` at `daae275`.
**Decision**: Edit `:227-233` (unchanged by #146 and by #151).
**Rationale**: The line numbers the critic gave still hold on current `main`.

### Release-As as an alternative recovery

**Context**: The plan entry offered "a release-class commit (or carry Release-As)".
**Explored**: `AGENTS.md` "Squash message" and "Forced version".
**Decision**: Name only the user-facing commit under `src/` (D2).
**Rationale**: A footer never reaches `main` here, and the config key still needs that commit; the
owner's decision names the release-class commit alone.

### What the next release PR contains after a skip

**Context**: The research claimed the skipped version's entries stay only in `CHANGELOG.md`; the
first draft of this design claimed the version stays right. The plan review showed both wrong.
**Explored**: release-please 17.3.0 `src/manifest.ts` (release lookup, `backfillReleasesFromTags`,
bootstrap walk, `commitsAfterSha`); `release-please-config.json` (`bootstrap-sha` `9e93ecc`);
`git log 9e93ecc.. -- src/` for breaking commits.
**Decision**: State the actual behaviour and forbid merging the PR as proposed (D3); leave the
remedy to the owner.
**Rationale**: Writing either earlier claim into `AGENTS.md` would tell an operator a dangerous
release PR is safe to merge.

## Risks / Trade-offs

- [D3 is read from source, not run] → It is labelled as such in the report. A real skip is rare
  and the gate before release-please makes it rarer; the first one will show the result, and the
  `AGENTS.md` text errs toward not merging.
- [`AGENTS.md` names no remedy for a skip] → An operator who skips a version must wait for a
  maintainer decision. Accepted until the owner picks one.
- [A `docs` commit edits a file under `src/`] → It is a comment in a file tagged with the
  `fixtures` if build attribute, so no consumer loads it, and `docs` is hidden, so no release
  follows.

## Durable decisions

- Backstop failure on the normal path means a transient registry error; re-run `publish-cue`; a
  re-run that fails on a fixture means the version is burned. Lands in `AGENTS.md` § Release &
  publishing (and the `release.yml` comment).
- After a failed gate or backstop the fix is always a `feat`/`fix`/`perf`/`revert` commit touching
  `src/`. After a skipped version the next release PR proposes a major bump and re-lists history
  since `bootstrap-sha`, and must not be merged as proposed. Lands in `AGENTS.md` § Release &
  publishing.
- `cue vet` fails on a conflict in a hidden field of the package it vets but passes an incomplete
  one, `-c` included. Lands in `AGENTS.md` (Transformer fixtures bullet and the task table).
