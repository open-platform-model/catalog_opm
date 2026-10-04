## Why

The release cascade security pass (2026-10-04, owner decisions 28 to 31) found that catalog_opm's
workflows lean on repository defaults that are about to change, and hold more than they use:

- `RELEASE_APP_PRIVATE_KEY`, the key of the only App that may create release tags, is an org
  secret that any workflow on any branch can read. Owner decision 29 moves it into a main-only
  Environment `release` (the supervisor created it; until the owner moves the secret there, a job
  in that Environment still falls back to the org secret). The one job that reads the key must
  declare `environment: release` first.
- Owner decision 30 flips the repo's default `GITHUB_TOKEN` to read-only and stops Actions from
  approving PRs. `ci.yml` declares no `permissions:` at all and today gets a write-all token while
  it runs the PR's own tree (including the bot's `deps/cascade` PR). `release.yml` grants
  `contents`, `pull-requests`, `packages` and `actions` write to every job at workflow level, so
  the release-please job holds `packages: write` and `pull-requests: write` it never uses, and
  `pull-requests: write` is what would let a workflow approve a PR once approvals are required.
- `branch-publish.yml` restores the Go module cache (setup-go's default) in a job that holds
  `packages: write` and publishes, and it publishes a dev build of every `release-please--*` head,
  which nobody consumes.
- No CODEOWNERS exists, so owner decision 28's code-owner review has nothing to bind to, and no
  Dependabot config watches the SHA-pinned actions.

## What Changes

- **`release.yml`**: top-level `permissions: {}`. `release-please` gets `environment: release` (the
  only job that reads `RELEASE_APP_PRIVATE_KEY`) and `contents: read`, `packages: read` (the GHCR
  login of the fixture gate) and `actions: write` (`gh workflow run ci.yml`); everything it writes
  to git or PRs goes through the App token. `publish-cue` gets `contents: read` and
  `packages: write`. `publish-cue` and `verify-published` check out with
  `persist-credentials: false`. `verify-published`, `publish-docs` and `notify-downstream` keep
  their grants.
- **`ci.yml`**: top-level `permissions: {}`; the `Validate catalog` job gets `contents: read` and
  `packages: read`; its checkout uses `persist-credentials: false`.
- **`branch-publish.yml`**: top-level `permissions: {}`; the job gets `contents: read` and
  `packages: write`. `release-please--**` and `dependabot/**` join `deps/**` in
  `branches-ignore`. setup-go gets `cache: false`. The checkout uses
  `persist-credentials: false`.
- **`cascade-task.yml`**: the repo checkout uses `persist-credentials: false`. Its permissions are
  already explicit and read-only.
- **`.github/CODEOWNERS`**: the plan's six-line spec, minus `/.cascade-frozen` (no such file here)
  and `/hack/` (no such directory).
- **`.github/dependabot.yml`**: the `github-actions` ecosystem, weekly, seven-day cooldown, `ci`
  prefix, ignoring `open-platform-model/docs-kit*` and `open-platform-model/.github*` (both move
  by hand).
- **`AGENTS.md`** § Release & publishing: the `release` Environment, the per-job permission rule,
  the no-cache rule for publishing jobs, the branch-publish exclusion, and Dependabot.

Not touched (wave 2 of the security pass): `deps-cascade.yml`, `cascade-gates.yml`,
`.tasks/cascade/wiring-check.sh` and the `.github` pin. `docs.yml` already declares
`permissions: {}` and per-job grants, and docs-kit's `publish.yml` already runs setup-go with
`cache: false`.

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is the
permission and trigger YAML.

**Before**

```yaml
# release.yml
permissions: {contents: write, pull-requests: write, packages: write, actions: write}
jobs:
  release-please: {}          # reads secrets.RELEASE_APP_PRIVATE_KEY, no environment
  publish-cue: {}             # inherits all four writes
# ci.yml: no permissions key (repo default: write-all)
# branch-publish.yml
on: {push: {branches-ignore: [main, 'deps/**']}}
permissions: {contents: read, packages: write}
#   setup-go: cache default (true)
# no .github/CODEOWNERS, no .github/dependabot.yml
```

**After**

```yaml
# release.yml
permissions: {}
jobs:
  release-please:
    environment: release
    permissions: {contents: read, packages: read, actions: write}
  publish-cue:
    permissions: {contents: read, packages: write}
# ci.yml
permissions: {}
jobs: {ci: {permissions: {contents: read, packages: read}}}
# branch-publish.yml
on: {push: {branches-ignore: [main, 'deps/**', 'release-please--**', 'dependabot/**']}}
permissions: {}
jobs: {publish: {permissions: {contents: read, packages: write}}}
#   setup-go: cache: false
# + .github/CODEOWNERS, + .github/dependabot.yml (github-actions)
```

## Impact

- **Published catalog: none.** No file under `src/` changes and no member moves to a new
  `apiVersion` segment. Every commit is `ci`, `docs` or `chore`, all hidden, so `opm` does not
  advance. PR title: `ci: harden the release workflows`.
- **modules fleet, subscribing platforms, cli fixtures:** nothing to do.
- **Release runs:** the release-please job now waits on the `release` Environment's branch policy
  (`main`, which it always runs on) and records a deployment. The key keeps working through the
  org-secret fallback until the owner moves it.
- **Dev builds:** a `release-please--*` push no longer publishes an `opm` `-0.dev.` tag.
- **Repo settings (supervisor, after merge):** with every workflow declaring its grants, the
  default token can flip to read-only and SHA pinning can become required without breaking a run.
- **Reviews:** with CODEOWNERS in place, the `main` ruleset's code-owner review (owner decision
  28) binds `.github/`, `.tasks/`, `Taskfile.yml` and the release-please files.

## Enhancement

None. The source is the supervisor's security-pass plan and owner decisions 28 to 31; no
enhancement backs it, so there is no `enhancement.yaml`.
