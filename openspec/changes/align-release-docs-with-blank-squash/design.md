## Context

The change edits `AGENTS.md`, `openspec/config.yaml`, and the instruction text in `openspec/schemas/catalog-change/schema.yaml` and `templates/proposal.md`. No member file and no `apiVersion` segment is touched. Motivation is in proposal.md.

The sources this text must agree with:

- Workspace `RELEASING.md`, "Owner settings" > "Merge settings": `squash_merge_commit_title` is `PR_TITLE` and `squash_merge_commit_message` is `BLANK`. A breaking change is `!` in the PR title. A forced version is `release-as` in `release-please-config.json`, set by a normal PR and removed by the next PR once that release is cut, because it pins every later release while it stays.
- `RELEASING.md`, "Bump rule": "Never add `!` to catalog_opm's cascade PR, even under `deps-cascade:breaking`. A breaking adoption there is a hand-made major crossing to `opm@v5`."
- `RELEASING.md`, "Title from diff class": under `BLANK`, a `BREAKING CHANGE:` or `Release-As:` line in a commit body does nothing.
- Workspace `.claude/skills/commit/SKILL.md:48-56` and `:64-76` already state the `BLANK` rule, the interim empty-body merge and the `release-as` mechanism. catalog_opm's text should say the same, not a variant.

Stale sites in this repo (worktree at `origin/main` `2232713`):

| Site | Text today | Problem |
| --- | --- | --- |
| `AGENTS.md:254` | `` `feat!:` / `BREAKING CHANGE:` `` → major | The footer never reaches `main` under `BLANK` |
| `AGENTS.md:223` | release-PR merge `gh pr merge <N> --squash --match-head-commit <sha>` | No empty body: under `COMMIT_MESSAGES` the release PR's commit list reaches `main` |
| `AGENTS.md:126` | "a `feat!:` on `opm` bumps the major" | Does not say the `!` must be in the PR title |
| `AGENTS.md:245-258` | no forced-version rule, no cascade `!` rule | The `release-as` path and the cascade exception are undocumented here |
| `openspec/config.yaml:25-28` | same as `AGENTS.md:126` | same |
| `openspec/config.yaml:125-127`, `schema.yaml:31-32`, `templates/proposal.md:28-29` | a proposal states "the release class of each section's commit" | Only the PR title reaches `main`, so a PR whose sections differ needs a title rule |
| `openspec/config.yaml:204-208` | "no body line starting with word( because the squash body reaches release-please" | True only until `BLANK` is applied |

## Goals / Non-Goals

**Goals:**
- Every rule in this repo about breaking changes and forced versions matches `RELEASING.md` "Owner settings" and the workspace commit skill.
- The text holds both before and after the owner applies `BLANK`.

**Non-Goals:**
- Applying the GitHub setting. That is owner-only (`RELEASING.md`, "Owner settings").
- Rewriting archived changes (`openspec/changes/archive/2026-09-30-catalogs-beta-cutover/`, `2026-09-30-adopt-hugo-page-dialect/`, `2026-10-02-retire-k8s-catalog/`). They record what was true then.
- cli, opm-operator and `.github`. Each gets its own change in the same sweep.
- `AGENTS.md:226` (the `RELEASE` stamp). Old `Release-As` footers stay in history (the 2026-09-30 k8s carrier), so its reason still holds.

## Decisions

### D1. The commit-conventions row names the title, not a footer

`AGENTS.md:254` becomes:

```
| `feat!:` (a `!` in the PR title)  | major (bumps the module path too) | yes | removing/renaming a definition, tightening output |
```

A sentence under the table says that the PR title becomes the squash commit's subject (once `PR_TITLE` is applied; until then the Squash message bullet covers it), and is the only text that reaches release-please once the squash message is `BLANK`. D5 adds the title rule.

Alternative: keep `BREAKING CHANGE:` "for repos without BLANK". Rejected, because this repo is one of the releasing repos whose squash message is `BLANK` (`RELEASING.md`, "Merge settings").

### D2. Three rules under "Commit conventions and release impact"

Add these bullets after the table and the rule of thumb:

- **Squash message.** The squash commit carries only the PR title (`squash_merge_commit_message: BLANK`, workspace `RELEASING.md` "Owner settings"). Until the owner applies that setting, merge every PR, release PRs included, with an explicit empty body (`gh pr merge <N> --squash --body ''`, combined with `--match-head-commit <sha>` for a release PR), and keep a one-commit PR's commit subject identical to the PR title (or pass `--subject`), since the title setting (`PR_TITLE`) is also still pending. A `BREAKING CHANGE:` or `Release-As:` footer in a commit or the PR body never takes effect: under `BLANK`, or with the empty-body merge above, it never reaches `main`.
- **Forced version.** Add `"release-as": "X.Y.Z"` to `packages.src` in `release-please-config.json` through a normal PR. Remove it in the next PR once that release is cut, because it pins every later release while it stays. It needs a user-facing commit (`feat`/`fix`/`perf`/`revert`) that touches `src/` to release: release-please ignores commits outside the package path, and with only hidden commits release-please opens no release PR. The opm 4.5.1 docs-bundle release took #122 (set the key), #123 (a `fix(catalog)`), #124 (the release) and #125 (drop the key).
- **Release cascade PRs never carry `!`.** `opm` is a stable 4.x line, so `!` would make release-please propose 5.0.0 while the module path stays `opmodel.dev/catalogs/opm@v4`. The bot never adds it, even under `deps-cascade:breaking`, and a human never retitles a cascade PR to add it. A breaking upstream adoption is a hand-made crossing to `opmodel.dev/catalogs/opm@v5` (`RELEASING.md`, "Bump rule").

The release-PR merge command in "Release & publishing" (`AGENTS.md:223`) gains the empty body: `gh pr merge <N> --squash --body '' --match-head-commit <sha>`. Without it, under `COMMIT_MESSAGES` (live today), the release PR's commit list reaches `main`.

Alternative: put these in `docs/`. Rejected, because `AGENTS.md` is loaded in every session and already owns release classes (`openspec/config.yaml`, "Everything Else Lives in AGENTS.md").

### D3. The stable-line statements say where the `!` goes

In `AGENTS.md:126` and `openspec/config.yaml:25`, "a `feat!:` on `opm` bumps the major" becomes "a `feat!:` PR title on `opm` bumps the major". Nothing else in either sentence changes.

### D4. The `word(` rule keeps its force with a reason that stays true

In `openspec/config.yaml:208`, "because the squash body reaches release-please" becomes "because release-please drops a commit whose body has one, and a squash body reaches `main` whenever a PR is merged without an empty body before `BLANK` is applied".

The rule stays because:

- The repo squashes with `COMMIT_MESSAGES` today (measured below).
- Under `BLANK` the rule costs nothing.

### D5. The PR title carries the highest release class of its commits

Under the table in `AGENTS.md`, after the D1 sentence: "Title a PR with the highest release class among its commits (`feat!` > `feat` > `fix`/`perf`/`revert` > hidden types), with a `!` if any commit breaks."

The OpenSpec guidance that asks a proposal to state each section's release class gains the title: `openspec/config.yaml:125` becomes "State the release class (`feat:` / `fix:` / `feat!:`) of each section's commit and of the PR title (the highest of them; only the title reaches release-please)", and `schema.yaml:31` and `templates/proposal.md:29` say the same.

Why: a change with a `feat!:` section, a `docs:` section and a `chore(openspec): archive` commit otherwise gets a PR titled after one of its hidden commits. With the empty-body merge live today, that PR releases nothing, or releases without the major.

Alternative: name these sites as a follow-up. Rejected, because the interim empty-body merge already drops the section commits, so the gap is live now.

## Research & Decisions

### Current merge settings
**Context**: Is `BLANK` already live in catalog_opm, which decides whether the interim rule is needed?
**Explored**: `gh api repos/open-platform-model/catalog_opm --jq '{t:.squash_merge_commit_title,m:.squash_merge_commit_message}'` on 2026-10-04 returned `{"m":"COMMIT_MESSAGES","t":"COMMIT_OR_PR_TITLE"}`.
**Decision**: State the `BLANK` rule, plus the interim empty-body merge (D2).
**Rationale**: This matches the workspace commit skill (`SKILL.md:48-51`). The text stays correct on the day the owner flips the setting.

### `release-as` without a user-facing commit
**Context**: Does a `release-as` key alone cut a release?
**Explored**: The 2026-10-03 opm 4.5.1 release record in `openspec/changes/archive/2026-10-03-publish-docs-bundle/design.md` ("Rollout record") and `git log`: `29a8bae` (#122, `chore(release)`, set the key), `fbe9bf7` (#123, `fix(catalog)`), `f13ccf1` (#124, release), `1445986` (#125, removed the key).
**Decision**: The forced-version rule says a user-facing commit is still needed (D2).
**Rationale**: This was measured in this repo. Without it the next agent repeats #122 and waits for a release PR that never opens.

## Risks / Trade-offs

- [The owner never applies `BLANK`, so the text describes a setting that is not live] -> D2 carries the interim empty-body merge, which gives the same result on `main`.
- [The wording drifts from the workspace commit skill and from the cli and opm-operator text] -> D2 cites `RELEASING.md` "Owner settings" as the authority instead of restating its reasoning, and uses the skill's wording.
- [An agent reads an archived change and follows its footer recipe] -> The archive is history. `AGENTS.md` is the authority (`AGENTS.md`, Repository Rules: "Authority is this file and `Taskfile.yml`").

## Durable decisions

- A breaking change is `!` in the PR title; the `BREAKING CHANGE:` footer is gone. Lands as an `AGENTS.md` rule (D1, D3).
- The squash message is `BLANK`, and until it is applied, merge every PR (release PRs included) with an empty body and a subject equal to the PR title. Lands as an `AGENTS.md` rule (D2).
- A forced version is `release-as` on `packages.src`, removed by the next PR, and it needs a user-facing commit that touches `src/`. Lands as an `AGENTS.md` rule (D2).
- A cascade PR in this repo never carries `!`. Lands as an `AGENTS.md` rule (D2).
- A PR is titled with the highest release class among its commits, `!` if any breaks. Lands as an `AGENTS.md` rule (D5); the proposal guidance in `openspec/config.yaml`, `schema.yaml` and `templates/proposal.md` asks for it.
- The reason for the `word(` rule (D4): edits `openspec/config.yaml` directly; not a promoted authoring rule, so the archive check does not look for it in `docs/` or `AGENTS.md`.
