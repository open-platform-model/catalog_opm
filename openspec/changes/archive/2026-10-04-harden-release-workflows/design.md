## Context

No catalog member, no file under `src/` and no `apiVersion` segment changes. The change edits
`.github/workflows/release.yml`, `ci.yml`, `branch-publish.yml` and `cascade-task.yml`, adds
`.github/CODEOWNERS` and `.github/dependabot.yml`, and amends `AGENTS.md`.

Sources, highest authority first: owner decisions 28 to 31 (security pass, 2026-10-04), the
supervisor's security-pass plan ("W1-<repo> harden-release-workflows"), and the audit's review
verdicts (N4, GOV-2, GOV-3, GOV-4, PUB-3 and the missed items "Release App key is an org secret"
and "Required CI jobs run PR-tree code with an implicit write-all GITHUB_TOKEN").

State on `main` (3288406):

- `release.yml` grants `contents`, `pull-requests`, `packages` and `actions` write at workflow
  level. `release-please` reads `secrets.RELEASE_APP_PRIVATE_KEY` with no `environment:`.
- `ci.yml` has no `permissions:` key; the repo default is write.
- `branch-publish.yml` grants `contents: read`, `packages: write` at workflow level, skips `main`
  and `deps/**`, and runs `actions/setup-go` with its default `cache: true`.
- `docs.yml`, `cascade-task.yml`, `cascade-gates.yml` and `deps-cascade.yml` already declare
  explicit permissions.

## Goals / Non-Goals

**Goals:**

- Every workflow declares its token; no job relies on the repo default, so the default can flip to
  read-only (owner decision 30) with no run breaking.
- Each job holds only what its steps use.
- The one reader of `RELEASE_APP_PRIVATE_KEY` runs in Environment `release` (owner decision 29).
- No job that publishes restores an Actions cache.
- No write token reaches code from a `deps/cascade` or `release-please--*` head before review.
- CODEOWNERS exists for the code-owner review rule (owner decision 28).

**Non-Goals:**

- `deps-cascade.yml`, `cascade-gates.yml`, `.tasks/cascade/wiring-check.sh` and the `.github` pin
  (wave 2). The in-tree wiring check needs no edit for this change: it looks only at
  `CASCADE_APP_PRIVATE_KEY`, Environment `cascade` and release.yml's workflow `env`.
- Narrowing the release App token itself (`permission-*` inputs on create-github-app-token).
  Not in the plan; release-please's label and PR calls would have to be enumerated first.
- Repo settings, rulesets, Environments and secrets (supervisor and owner).

## Decisions

### D1. release.yml: `permissions: {}` at the top, grants per job

| Job | Grant | Used by |
| --- | --- | --- |
| `release-please` | `contents: read`, `packages: read`, `actions: write`; `environment: release` | GHCR login for `task vet:fixtures` (`packages: read`); `gh workflow run ci.yml` with `GITHUB_TOKEN` (`actions: write`). The checkout, the identity push and release-please all use the App token, so `GITHUB_TOKEN` needs no `contents: write` or `pull-requests: write`. |
| `publish-cue` | `contents: read`, `packages: write` | tag checkout; GHCR login and `opm catalog publish` |
| `verify-published` | unchanged: `contents: read`, `packages: read` | |
| `publish-docs` | unchanged: `contents: read`, `packages: write`, `id-token: write` | docs-kit `publish.yml` release mode |
| `notify-downstream` | unchanged: `contents: read`, `environment: cascade` | |

Every checkout sets `persist-credentials: false`. The release App is the strongest credential in
the system (audit GOV-2), so its token does not sit in `.git/config` while `task vet:fixtures`,
release-please and the downloaded opm run. "Advance identity.Version", the one step that pushes,
gets the token through `env:`, hands it to its own `git fetch` and `git push` as a per-command
`http.extraheader` (masked), and unsets it before `opm catalog version set` runs.

### D2. ci.yml: `permissions: {}`, the job gets `contents: read`, `packages: read`

`Validate catalog` reads the repo and logs in to GHCR to resolve core. Nothing in it writes. Its
checkout sets `persist-credentials: false`; no task or `.tasks/` script runs `git fetch`, `git
push` or `gh` (checked by grep), so nothing needs the credential.

### D3. branch-publish.yml: grants on the job, bot heads skipped, no cache

The job keeps `contents: read` and `packages: write` (it publishes), moved from workflow level to
job level under `permissions: {}`. `release-please--**` and `dependabot/**` join
`branches-ignore`: both heads are bot-written, nobody consumes their dev tags, and skipping them
keeps `packages: write` away from those trees before a human reads them (plan item 4; `deps/**`
was already skipped). Dependabot's push runs get a read-only token by default, but a workflow's
`permissions:` key raises it, so without the skip each action bump (D6) would run the new action
SHA and `task check` and then publish with a GHCR write token, unreviewed. `actions/setup-go`
gets `cache: false`: the job publishes, and a restored Go cache is an input nobody verifies
(plan item 3). The checkout sets `persist-credentials: false`; `branch-tag.sh` reads tags from
the full-history checkout and never fetches.

Other branches still get `packages: write` while `task check` runs their tree: that is the
workflow's purpose (dev builds of feature branches) and only a write collaborator can push one.

### D4. cascade-task.yml: `persist-credentials: false` on the repo checkout

Its token is already `contents: read`. The resolver checkout already sets it.

### D5. CODEOWNERS

```
# Changes here need a code owner's review (main ruleset).
/.github/                       @emil-jacero @orvis98
/.tasks/                        @emil-jacero @orvis98
/Taskfile*.yml                  @emil-jacero @orvis98
/release-please-config.json     @emil-jacero @orvis98
/.release-please-manifest.json  @emil-jacero @orvis98
```

`/.cascade-frozen` is left out (no such file; the plan adds only existing paths). `/hack/` is left
out (no such directory).

### D6. Dependabot for github-actions

Weekly, prefix `ci` (a hidden type here, so a bump releases nothing), with a seven-day
`cooldown` so a just-published (possibly compromised) action release is not proposed at once
(audit GOV-4 fix notes). Ignored:
`open-platform-model/docs-kit*` (moves with `.opm-docs-version`, `task docs:pins:check`) and
`open-platform-model/.github*` (moves only by the `ci(deps)` pin PR). Same shape as library, cli
and opm-operator, except that those have no cooldown yet.

## Research & Decisions

### Which steps use GITHUB_TOKEN

**Context**: the default token goes read-only after merge, so every write must be declared.
**Explored**: every `secrets.GITHUB_TOKEN`, `github.token`, `GH_TOKEN`, `gh ` and `git push` in
`.github/workflows/` and `.tasks/`, `Taskfile.yml`.
**Decision**: the grants in D1 to D4.
**Rationale**: the writes are `gh workflow run` (release-please, `actions: write`) and the GHCR
pushes (`publish-cue`, `branch-publish`, docs-kit's publish). Everything else reads.

### Caches

**Context**: plan item 3, no Actions cache in a workflow that publishes.
**Explored**: `setup-go`, `actions/cache`, `cache-from`/`cache-to` in every workflow, and docs-kit
`publish.yml` at the pinned `v0.6.0`.
**Decision**: only `branch-publish.yml:67` restored a cache. `ci.yml` keeps setup-go's cache: it
publishes nothing and holds no write grant after D2. docs-kit already sets `cache: false`.

## Risks / Trade-offs

- [The `release` Environment's branch policy refuses a run] → `release.yml` runs only on pushes
  to `main`, which the policy (`main`) allows.
- [A grant is missing and a run fails after the default flips] → each grant is traced to a step
  in D1 to D4; actionlint checks the permission names. The first push to `main` after merge is
  the real proof. If `packages: read` is missing, the fixture gate's GHCR login fails before
  release-please runs, so no tag or release exists and a re-run after the fix is safe. If
  `actions: write` is missing, `gh workflow run ci.yml` in "Trigger required CI on the release
  PR" gets a 403 that its `|| echo` swallows: the job stays green and logs "no open release
  branch", but the release PR's required `Validate catalog` check never starts. The symptom is a
  release PR stuck on a pending check; a maintainer dispatches `ci.yml` on the release branch by
  hand until the grant is fixed.
  A missing `packages: write` fails `publish-cue` after the tag exists; re-running that job
  publishes the tagged tree.
- [CODEOWNERS with two owners means an admin's own PR needs the other's review] → owner decision
  28 accepts it; admins keep the pull-request bypass.

## Durable decisions

- Every workflow declares `permissions:`; publishing and key-holding jobs get per-job grants;
  `RELEASE_APP_PRIVATE_KEY` is read only in a job with `environment: release`; publishing jobs
  restore no Actions cache; branch-publish skips `release-please--**` and `dependabot/**`; Dependabot covers
  github-actions with a seven-day cooldown and the two ignores. Lands in `AGENTS.md` § Release & publishing.
