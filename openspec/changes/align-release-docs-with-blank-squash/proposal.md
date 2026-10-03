## Why

On 2026-10-02 the owner set the squash message for the five releasing repos to `BLANK` (workspace `RELEASING.md`, "Owner settings", "Merge settings"). Under `BLANK` a squash commit carries only the PR title, so a `BREAKING CHANGE:` or `Release-As:` footer never reaches `main`. Breaking is `!` in the PR title. A forced version is a `release-as` key in `release-please-config.json`, set by a normal PR and removed by the next PR once that release is cut.

catalog_opm's own guidance still teaches the footer model. An agent that follows it writes a footer that does nothing, or skips the `!` that would have carried the break. This change aligns the text before the cascade bot (Phase 3) starts opening PRs here.

## What Changes

Text only. No CUE, workflow or config value changes.

- `AGENTS.md:254`, "Commit conventions and release impact": the row `` `feat!:` / `BREAKING CHANGE:` `` becomes `` `feat!:` `` (a `!` in the PR title), with a note that the PR title is all the squash commit carries.
- `AGENTS.md`, same section: add three rules.
  - The squash message is `BLANK`. Until the owner applies that setting (today the repo still squashes with `COMMIT_MESSAGES`, `COMMIT_OR_PR_TITLE`), merge with an explicit empty body.
  - A forced version is a `release-as` key on the `src` package in `release-please-config.json`, landed by a normal PR and removed by the next PR once that release is cut. `release-as` alone does not release: it needs a user-facing commit (measured with #122 to #125, opm 4.5.1).
  - A release cascade PR here never carries `!`, even under `deps-cascade:breaking` (`RELEASING.md`, "Bump rule"). `opm` is a stable 4.x line, so `!` would make release-please propose 5.0.0 while the module path stays `opmodel.dev/catalogs/opm@v4`. A breaking adoption is a hand-made crossing to `@v5`.
- `AGENTS.md:126`, the stable-line bullet: say the `!` goes in the PR title.
- `openspec/config.yaml:25-28`, Principle I: the same title clarification.
- `openspec/config.yaml:204-208`, the apply guidance: the reason given for the `word(` rule ("the squash body reaches release-please") holds only until `BLANK` is applied. Restate it so that it stays true either way. The rule itself stays.
- Unchanged:
  - `AGENTS.md:226`, the `RELEASE` stamp bullet. Old `Release-As` footers are still in history, for example the 2026-09-30 k8s carrier, so the reason it gives still holds.
  - `release-please-config.json`. It has no `release-as` key.

No main specs change: this repo's schema has no specs artifact (`.openspec.yaml` `skip_specs: true`).

## Before / After

No catalog member changes. The review surface is the commit-conventions row:

```
Before: | `feat!:` / `BREAKING CHANGE:` | major (bumps the module path too) | yes | ... |
After:  | `feat!:` (`!` in the PR title) | major (bumps the module path too) | yes | ... |
```

## Impact

- Downstream consumers (`modules` fleet, subscribing platforms, `cli` fixtures): none. Nothing published changes.
- Release class: every section commits as `docs(...)`. `docs` is hidden in `release-please-config.json`, so no release is cut.
- Depends on: none. This changes no task, so it does not wait for `.github` `add-cascade-resolver`. It documents the owner decision (`RELEASING.md`, "Owner settings") and holds both before and after the owner applies `BLANK`.
- Related: the same sweep in cli and opm-operator, and the `.github` README and mention-guard comments. Each is its own change.
