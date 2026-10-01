## Why

The release cascade (workspace `RELEASING.md`, sections "The cascade" and "Gates") will have a bot
open one rolling `deps/cascade` PR in this repo whenever core or the opm CLI releases. Three
things in this repo are not ready for that bot. Nothing stops a release PR from shipping a
catalog that pins a dev core build. Every bot push to a non-main branch would publish dev catalogs
to GHCR. The opm CLI pin lives inside three workflow files, which the bot cannot edit without the
GitHub **Workflows** permission (workspace `RELEASING.md`, section "Owner settings"). This change
fixes all three before the cascade exists, so that later changes can rely on them.

## What Changes

- **G1 release-pin gate** (workspace `RELEASING.md`, section "Gates"). The required
  `Validate catalog` job in `.github/workflows/ci.yml:22-23` gains one step. It runs only when
  `${{ github.head_ref || github.ref_name }}` starts with `release-please--`: the release PR CI
  arrives as a `pull_request` run, or as the `workflow_dispatch` run that `release.yml:117-126`
  starts on the release branch (where `head_ref` is empty). It fails when either catalog's
  `cue.mod/module.cue` pins a `-0.dev.` version, or when a `cue.mod/local-module.cue` is tracked
  in either catalog. The check is a new Taskfile task, `task deps:release-check`, so it can also be
  run locally.
- **Branch publish skips `deps/**`.** `branch-publish.yml:4-6` ignores only `main` today. It
  will also ignore `deps/**`, so cascade bot pushes never publish `-0.dev.` catalogs to GHCR.
  Feature and release branches still publish as before.
- **The opm CLI pin moves into a file.** Remove the workflow-level `OPM_CLI_VERSION` from
  `ci.yml:18-19`, `release.yml:15-17` and `branch-publish.yml:23-25`. A new repo-root file,
  `.opm-cli-version`, holds one line with the opm CLI tag. Every job that installs the CLI reads
  it into `$GITHUB_ENV` before its `Install opm` step. That is four jobs: `ci`, `publish`,
  `release-please` and `publish-cue`. The move keeps the value at `v1.0.0-beta.2`.
- **Bump the opm CLI from `v1.0.0-beta.2` to `v1.0.0-beta.4`** as its own `ci(deps)` commit.
  This is the first bump that goes through the new file.
- `AGENTS.md` § Release & publishing records the file, the gate and the `deps/**` exclusion.

**Not in this change** (later phases in workspace `RELEASING.md`, section "Rollout and changes"):
splitting "Verify the published build" out of `publish-cue`, the notify job, the cascade
receiver, `deps:cascade`, `.cascade-frozen` and `.cascade-hold`.

## Before / After

No catalog member changes. The CUE that G1 judges is the dependency block of
`opm/cue.mod/module.cue:8-16` and `k8s/cue.mod/module.cue:8-12`. Neither file changes. G1 only
reads them.

**Before** (any pin passes on a release PR)

```cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-0.dev.1790000000.gabc1234" // nothing refuses this
```

**After** (`task deps:release-check` on a `release-please--*` ref)

```cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-beta.1"                     // passes
deps: "opmodel.dev/core@v2": v: "v2.0.0-0.dev.1790000000.gabc1234" // G1 fails the required check
// and any tracked opm/cue.mod/local-module.cue or k8s/cue.mod/local-module.cue fails it too
```

The CI shape (YAML, not CUE, because no CUE member is involved):

```yaml
# Before: ci.yml:19, release.yml:17, branch-publish.yml:25
env:
  OPM_CLI_VERSION: 'v1.0.0-beta.2'
# After: .opm-cli-version at the repo root contains the single line  v1.0.0-beta.4
#        and each CLI-installing job runs, before "Install opm":
- name: Read the pinned opm CLI version
  run: |
    grep -qxE 'v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?' .opm-cli-version
    echo "OPM_CLI_VERSION=$(cat .opm-cli-version)" >> "$GITHUB_ENV"
```

## Impact

- **Published catalogs: none.** No file under `opm/` or `k8s/` changes, so both catalogs stay
  byte-identical. Every section is a non-releasing commit type (`ci:`, `ci(deps):`).
  Nothing advances `opm` (stable line) or `k8s` (beta line).
- **modules fleet, subscribing platforms, cli fixtures:** nothing to do.
- **Workspace `task deps:pins:opm-cli`** (`.tasks/deps/opm-cli.sh:22-28`) edits
  `OPM_CLI_VERSION: '...'` inside `catalog_opm/.github/workflows/*.yml`. After this change no
  workflow carries that literal, and the script's `grep -q ... || continue` would silently skip
  catalog_opm. The workspace branch `docs/release-cascade` teaches it to write
  `.opm-cli-version`, and must merge first.
- **Release PRs:** the dispatched CI run on a release branch now also runs G1. A release PR whose
  tree carries a dev core pin or a local replacement cannot pass the required check.
- **Dev catalogs:** branches named `deps/**` no longer get `-0.dev.` tags on GHCR. Nobody uses
  such branches today.

**Depends on / gates:**

- Depends on: workspace `docs/release-cascade`. Its `.tasks/deps/opm-cli.sh` must read and write
  `.opm-cli-version` before this change merges. Otherwise the next `task deps:pins:opm-cli` run
  silently skips this repo.
- Gates: catalog_opm `add-deps-cascade-task` (a later phase). Its release-tool bump writes
  `.opm-cli-version` and relies on the `deps/**` exclusion.
- Gates: catalog_opm `join-release-cascade` (a later phase). The receiver pushes `deps/cascade`
  and needs G1 present.
- The OpenSpec archive commit rides this change's PR; nothing is pushed to `main` afterwards
  (workspace `RELEASING.md`, section "Owner settings").
- Peers (same phase, independent): library `prepare-release-cascade`, opm-operator
  `prepare-release-cascade`, cli `prepare-release-cascade`. Each adds G1 in its own repo. There is
  no ordering between them.

## Enhancement

None. The design lives in workspace `RELEASING.md` (sections "Gates", "Pin classes" and
"Cascade files"). No enhancement backs it, so there is no `enhancement.yaml`.
