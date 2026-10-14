# Release, publishing and commit types

Covers how the catalog is released and published: release-please, the identity version, the `publish-cue` job, failed and skipped versions, forced versions, branch builds, job credentials, and the commit and PR-title types that drive a release. The cascade notify and receive jobs, the cascade pin and `.opm-cli-version` are in a separate file.

## Release flow

- Tags are `opm-vX.Y.Z`, the release branch is `release-please--branches--main--components--opm`, and the changelog is the root `CHANGELOG.md`.
- Other tags stay: the retired `k8s` module's `k8s-vX.Y.Z` and the older bare `vX.Y.Z` (an earlier line of the catalog). Only `opm-v*` tags are releases of this module.
- release-please (`release.yml`, release type `simple`) opens and updates the release PR. The same workflow then runs `opm catalog version set` on that release branch, so the PR carries the next `identity.Version`. The `chore: advance opm identity.Version to <v>` commit holds the identity file alone. The write needs no registry. Merging the PR tags the component and creates the GitHub Release.
- The `publish-cue` job, gated on release-please's `src--release_created`, runs `opm catalog publish ./src --version <version>` against `ghcr.io/open-platform-model`. It runs in the workflow run that the human merge triggers, which avoids GitHub's `GITHUB_TOKEN` tag-trigger suppression. `--version` is an assertion against the version the release PR wrote: a mismatch refuses, it never overwrites.
- After the push, the separate `verify-published` job runs `opm catalog registry check --compat` on the pushed build. It is an aid, not a gate (enhancement 0011, a published catalog can be verified out of band). It runs only when `publish-cue`'s `published` output is `true`, a finding fails only that job, and it is never a `needs` of `publish-docs` or of the notify job. Keep it out of `publish-cue`: a failing step there after the push would hide that the module shipped.
- `ci.yml` runs the publish gates as a dry run on every PR (`opm catalog publish ./src --dry-run`). Already-published as the only refusal is tolerated, because outside a release the committed version is usually live. The tolerance keys on a refusal count, so never concatenate its output with another run's.
- `src/RELEASE` is one line, `<version> # x-release-please-version`, rewritten by release-please through `extra-files`.

## Failed gate, burned version, skipped version

- Before release-please runs, the `release-please` job runs `task vet:fixtures` on the pushed `main` commit. The release PR already passed it, but branch protection is not strict and an admin can merge past the check. The step sits before the release-please action because that action pushes the tag: a failure stops the job before any tag or Release exists, and a broken `main` also stops the release PR from updating.
- The first error line under each `FAIL` names the cause. On a registry fetch error, re-run the job. Remove the label only when a fixture itself fails. A registry error and a conflict can end in the same "N of N" summary.
- When a fixture fails the gate on a release PR's merge commit, remove the `autorelease: pending` label from that merged PR before the fix lands. release-please tags the merge commit of the merged release PR, not `HEAD`, so otherwise the run on the fix tags the broken tree. With the label gone that version is skipped.
- As a backstop, `publish-cue` runs `task vet:fixtures` on the checked-out tag before publishing. A missed label then burns the version (tag and Release, no GHCR artifact) instead of publishing the refused tree. On the normal path the gate already passed, so the backstop fails only on a transient registry error (core from GHCR, `cue.dev/x/k8s.io` from `registry.cue.works`) after the tag and Release exist. Re-run the `publish-cue` job: it publishes the same tag. Only when a fixture itself fails is the version burned.
- After a failed gate or a failed backstop, the fix lands as a `feat`, `fix`, `perf` or `revert` commit that touches `src/`. After a burned version release-please finds that Release and counts commits from it, so with only hidden commits since it opens no release PR. The `release-as` key only chooses the version and needs that commit too.
- After a skipped version, the fix PR also sets `"last-release-sha"` (top level of `release-please-config.json`) to the skipped release PR's merge commit. The PR after the next release drops it, like a forced version. Without it release-please finds no Release or tag for the manifest version and walks back to `bootstrap-sha` (the 0.6.0 release). The next release PR then proposes a major bump from the breaking commits under `src/` since then (a skipped 4.7.0 would be followed by a proposed 5.0.0, on a module whose path is major v4) and re-lists every user-facing commit since 0.6.0.
- release-please checks `last-release-sha` before `bootstrap-sha`. This is read from release-please v17.3.0's `src/manifest.ts` and has not been seen in a real release: check the proposed version before you merge that release PR. A burned version needs no key, because its Release exists.

## Branch builds, credentials and caches

- `branch-publish.yml` publishes a `-dev` pre-release for non-main branches, except the bot branches `deps/**` (cascade), `release-please--**` (release heads) and `dependabot/**` (action bumps). Their bot-written trees must not run under its `packages: write` token before review.
- The job runs `task check`, then `.tasks/branch-tag.sh src opm-` derives the deterministic version, `opm catalog version set` stamps it into the runner's working tree (never a commit), and `opm catalog publish ./src` pushes. The tag prefix is the component, never the directory.
- Runs are serialized per branch: a `concurrency` group that queues and never cancels. A publish whose only refusal is that its own dev tag is already published passes, because the tag names its commit.
- `secrets.RELEASE_APP_PRIVATE_KEY` is read only by the `release-please` job, which declares `environment: release` (deploys from `main` only). Never read it in another job or without that Environment (owner decisions 29 and 30).
- Every workflow declares top-level `permissions:` (`{}`, or `contents: read` where every job only reads). Each job that needs more grants it itself, traced to a step. `release-please` holds `contents: read`, `packages: read` (GHCR login for the fixture gate) and `actions: write` (`gh workflow run ci.yml`), because its git and PR writes use the App token. `publish-cue` and `branch-publish` hold `contents: read` and `packages: write`. `Validate catalog` holds `contents: read` and `packages: read`. The repo default token is read-only, so a job that forgets a grant fails.
- Every checkout sets `persist-credentials: false`. The identity advance, the one push, passes the App token to its own `git fetch` and `git push` as a per-command `http.extraheader` and unsets it before opm runs.
- `.github/CODEOWNERS` names the one maintainer for `.github/`, `.tasks/`, `Taskfile*.yml` and the release-please files. Owner decision 28 has the `main` ruleset require a code owner's review there; it is switched off while OPM is in beta.
- `.github/dependabot.yml` bumps the SHA-pinned actions weekly as `ci` PRs, proposes no release younger than seven days (`cooldown`), and ignores `open-platform-model/docs-kit*` (moves with `.opm-docs-version`) and `open-platform-model/.github*` (moves by the cascade pin PR).
- The G1 release-pin gate (`task deps:release-check`) runs inside the required `Validate catalog` job when `github.head_ref || github.ref_name` starts with `release-please--`. That covers the `pull_request` run and the run `release.yml` dispatches onto the release branch, where `head_ref` is empty. It is a step, never its own job: a job skipped by its `if:` reports as passing.
- `Validate catalog` runs `task vet:fixtures`, so the release PR's dispatched run gates the release commit on rendered output as well as on `task vet`.

## Commit and PR-title types

| Type | Bump | In changelog | Use for |
| --- | --- | --- | --- |
| `feat:` | minor | yes | a new resource, trait, blueprint or transformer; a new field |
| `fix:` | patch | yes | a wrong constraint; broken transform output |
| `perf:` | patch | yes | evaluation cost |
| `feat!:` (a `!` in the PR title) | major, and the module path | yes | removing or renaming a definition; tightening output |
| `refactor:`, `docs:`, `style:`, `chore:`, `test:`, `ci:`, `build:` | none | hidden | moves, comments, tooling: no published change |

- Rule of thumb: if the published catalog is byte-identical before and after, it is not a `feat:` or a `fix:`.
- The squash commit carries only the PR title (`squash_merge_commit_message: BLANK`, workspace `RELEASING.md`, "Owner settings"). Title a PR with the highest release class among its commits (`feat!` > `feat` > `fix`, `perf`, `revert` > hidden types), with a `!` if any commit breaks. Exception: a cascade PR, below.
- Until the owner applies the `BLANK` setting, merge every PR, release PRs included, with an explicit empty body (`gh pr merge <N> --squash --body ''`, plus `--match-head-commit <sha>` for a release PR). Keep a one-commit PR's subject identical to the PR title, or pass `--subject`, because the `PR_TITLE` setting is also pending. A `BREAKING CHANGE:` or `Release-As:` footer never takes effect: under `BLANK`, or with the empty-body merge, it never reaches `main`.
- Forced version: add `"release-as": "X.Y.Z"` to `packages.src` in `release-please-config.json` through a normal PR. Remove it in the next PR once that release is cut, because it pins every later release while it stays. It needs a user-facing commit that touches `src/`: release-please ignores commits outside the package path, and with only hidden commits it opens no release PR. The opm 4.5.1 docs-bundle release took #122 (set the key), #123 (a `fix(catalog)`), #124 (the release) and #125 (drop the key).
- A release cascade PR never carries `!`. `opm` is a stable 4.x line, so `!` would make release-please propose 5.0.0 while the module path stays `opmodel.dev/catalogs/opm@v4`. The bot never adds it, even under `deps-cascade:breaking`, and a human never retitles a cascade PR to add it. A breaking upstream adoption is a hand-made crossing to `opmodel.dev/catalogs/opm@v5` (workspace `RELEASING.md`, "Bump rule").
- `opm` is stable: a `feat!:` title bumps the major and with it the module path. This is the sanctioned way to correct a `v1betaN` member in place when the `v1beta(N+1)` route would leave the broken shape published under the old segment (enhancement 0010, a contract is keyed by its own API version). It is not a licence to skip that route when a clean new segment is available. A core beta break that would force an `opm` major needs owner sign-off before it lands.

## Pitfalls

- Running the workspace `deps:update` or `deps:pins:opm-cli` and calling it a cascade: it ignores `.cascade-hold` and `.cascade-frozen`.
- Leaving `autorelease: pending` on a merged release PR after a failed fixture gate: the fix run tags the broken tree.
- Fixing a burned or skipped version with a hidden commit: no release PR opens. The fix touches `src/` as `feat`, `fix`, `perf` or `revert`.
- Leaving `release-as` or `last-release-sha` in the config after the release is cut: it pins every later release.

## Check before you finish

- [ ] The PR title is the highest release class of its commits, and a cascade PR has no `!`.
- [ ] A change to a release workflow keeps `permissions:`, `persist-credentials: false` and `cache: false` where they were.
- [ ] A fix for a burned or skipped version touches `src/` as a releasing type.
- [ ] `task check` passes, and `task cascade:wiring:check` passes after a workflow edit.
