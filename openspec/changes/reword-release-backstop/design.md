## Context

No catalog member and no `apiVersion` segment changes. The change edits comments and prose in
`.github/workflows/release.yml`, `AGENTS.md`, `Taskfile.yml`, `.tasks/fixtures.sh` and
`src/transformers/role_transformer_fixtures.cue`.

Sources, highest authority first: the owner's walkthrough decision for follow-up w1-03 ("catalog
backstop wording (transient GHCR error; the fix must be release-class)"), the supervisor's wave-2
decision SD14 (fold the `gate-and-tag-fixtures` follow-up on hidden-field prose into this change),
and the wave-2 plan entry `cat-backstop` with its research and critic notes.

State at `origin/main` `daae275` (after catalog_opm#146):

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
  cause and that re-running the job is the recovery.
- `AGENTS.md` says which commit re-opens the release PR after a burned or skipped version.
- Every live statement about `cue vet` and hidden fields matches what was measured.

**Non-Goals:**

- A retry loop around the backstop (optional in the plan entry, not decided by the owner).
- Edits to archived changes.
- A remedy for the release notes after a skipped version (D3).

## Decisions

### D1. Backstop comment: one cause, one recovery

The comment keeps its first sentences and replaces "so this cannot fail" with:

```yaml
      # publishing the tree the gate refused. On the normal path the gate
      # already passed on this commit, so this step can fail only on a
      # transient registry error (the exports resolve core from GHCR). The tag
      # and Release exist by then: re-run this job.
```

"Re-run this job" is enough: `publish-cue` reads `opm_tag_name` and `opm_version` from the
`release-please` job's outputs (`release.yml:197`, `:254`), which "Re-run failed jobs" keeps. Re-running publishes the same
tag; it cuts no new version.

### D2. Recovery after a burned version needs a user-facing commit under `src/`

When the backstop refuses a real failure, the version is burned: tag and Release exist, no GHCR
artifact. release-please then finds that Release (its manifest version matches the tag) and counts
commits from its SHA. With only hidden commits since, it logs "No user facing commits" and opens no
release PR, so the fix never ships. The fix MUST land as a `feat`, `fix`, `perf` or `revert`
commit (the visible types in `release-please-config.json`) that touches `src/` (release-please
ignores commits outside the package path, `AGENTS.md` "Forced version").

The plan entry also offered "or carry Release-As". In this repo that is not an alternative. A
`Release-As:` footer never reaches `main` (`AGENTS.md` "Squash message"), and the `release-as`
config key only picks the version: it still needs a user-facing commit under `src/`. `AGENTS.md`
says so instead of naming Release-As as a way out.

### D3. After a skipped version, the next release PR re-lists history

The plan entry's research said that after the label is removed, "the skipped version's entries
appear only in `CHANGELOG.md`", with the merge commit treated as released. Reading
release-please 17.3.0 (the version `release-please-action` v4.4.1 locks), `src/manifest.ts`
"Collecting release commit SHAs":

1. It looks for a GitHub Release whose tag version equals the manifest version. The skipped
   release PR wrote that version into `.release-please-manifest.json` but was never tagged, so
   none matches.
2. `backfillReleasesFromTags` looks for the tag `opm-v<that version>`; there is none.
3. `needsBootstrap` is then true, and commit collection walks back to `bootstrap-sha`
   (`9e93ecc`, the 0.6.0 release in June 2026), up to the default search depth of 500.
4. The latest release is backfilled from the manifest version with an empty SHA, so the next
   version is still computed from the skipped one.

The next release PR therefore gets the right version, but its notes list every user-facing commit
under `src/` since `bootstrap-sha`, the skipped version's entries included. And because such
commits exist, it opens even when the fix itself is a hidden type. `AGENTS.md` states this
behaviour so an operator expects it. Whether to repair it (hand-editing the release PR's notes,
a `last-release-sha` in the config, or moving `bootstrap-sha` forward) is a decision for the owner
and is left out (open point in the report). This is read from source, not run against a real
release.

### D4. Hidden fields: what `cue vet` checks

Measured facts (cue v0.17.1):

- `cue vet` evaluates the hidden fields of a package it loads as the main instance, so an
  error-class conflict there fails it: `_boom: 1 & 2` in `transformers` failed `cue vet ./...` (j2
  experiment, 2026-10-02), and a golden set to `"WRONG"` failed `cue vet -t fixtures ./...`
  (`gate-and-tag-fixtures` review).
- It does not report a hidden field that stays incomplete, plain or with `-c`: a hidden rule-1
  gate case in core exits 0 under both (wave-1 core review), and 44 of 47 fixtures failed export
  in 2026-09 while vet passed.
- Fixtures sit in `@if(fixtures)` files, so only `cue vet -t fixtures` loads them; `task vet` runs
  both views.

Each of the five sites gets that wording, kept to its local length:

| Site | New claim |
| --- | --- |
| `AGENTS.md:201` (`task vet:fixtures` row) | `cue vet`, `-c` included, fails on a conflict in a hidden field but passes one that stays incomplete; `cue export` forces it concrete |
| `AGENTS.md:300` (Transformer fixtures) | replace "does not descend into hidden fields at all" with the D4 claim; the rest of the bullet already says the two checks are complementary |
| `Taskfile.yml:71-73` (`vet:fixtures` desc) | `cue vet` (including `-c`) passes a hidden field that stays incomplete |
| `.tasks/fixtures.sh:18-20` | `cue vet`, including `-c`, does not report an incomplete hidden field (it does fail on a conflict in one) |
| `role_transformer_fixtures.cue:288-289` | "cue vet skips hidden fields" becomes "cue vet passes an incomplete hidden field" |

Section 2 re-measures both facts in a scratch copy before editing, so the new prose is checked
against cue v0.17.1 on this tree, not only against the earlier reports.

## Research & Decisions

### Where the backstop wording lives after #146

**Context**: The plan entry cited `release.yml:207-209`; the critic said `:227-233`; #146 merged
since.
**Explored**: `grep -n 'cannot fail' .github/workflows/release.yml` at `daae275`.
**Decision**: Edit `:227-233` (unchanged by #146).
**Rationale**: The line numbers the critic gave still hold on current `main`.

### Release-As as an alternative recovery

**Context**: The plan entry offered "a release-class commit (or carry Release-As)".
**Explored**: `AGENTS.md` "Squash message" and "Forced version".
**Decision**: Name only the user-facing commit under `src/` (D2).
**Rationale**: A footer never reaches `main` here, and the config key still needs that commit; the
owner's decision names the release-class commit alone.

### What the next release PR contains after a skip

**Context**: The research claimed the skipped version's entries stay only in `CHANGELOG.md`.
**Explored**: release-please 17.3.0 `src/manifest.ts` (release lookup, `backfillReleasesFromTags`,
bootstrap walk, manifest backfill); `release-please-config.json` (`bootstrap-sha` `9e93ecc`).
**Decision**: State the actual behaviour (D3); leave the remedy to the owner.
**Rationale**: Writing the research claim into `AGENTS.md` would document behaviour release-please
does not have.

## Risks / Trade-offs

- [D3 is read from source, not run] → It is labelled as such in the report. A real skip is rare
  and the gate before release-please makes it rarer; the first one will show the result.
- [A `docs` commit edits a file under `src/`] → It is a comment in an `@if(fixtures)` file, so
  no consumer loads it, and `docs` is hidden, so no release follows.

## Durable decisions

- Backstop failure on the normal path means a transient registry error; re-run `publish-cue`.
  Lands in `AGENTS.md` § Release & publishing (and the `release.yml` comment).
- After a burned version the fix is a `feat`/`fix`/`perf`/`revert` commit touching `src/`, and
  after a skipped version the next release PR's notes re-list everything since `bootstrap-sha`.
  Lands in `AGENTS.md` § Release & publishing.
- `cue vet` fails on a conflict in a hidden field but passes an incomplete one, `-c` included.
  Lands in `AGENTS.md` (Transformer fixtures bullet and the task table).
