## Why

The release cascade (workspace `RELEASING.md`, "The cascade") has two halves per repo. Phase 2
gave catalog_opm the first half, `task -x deps:cascade` (archived
`openspec/changes/archive/2026-10-04-add-deps-cascade-task`). Nothing calls it yet, and nothing
tells library, opm-operator or cli when a catalog release reaches GHCR. Phase 3 ("Rollout and
changes") wires each repo to the cascade code in `open-platform-model/.github`: two composite
actions (`cascade-notify`, `cascade-publish`) and two reusable workflows (`cascade-receive.yml`,
`cascade-gates.yml`), merged as `.github` PR 9 (squash `2376ffa`). This change is catalog_opm's
part.

catalog_opm has a hazard the other repos lack. `publish-cue` ended with "Verify the published
build", a non-gating check that fails the job after the module is already on GHCR. A notify job
that `needs: publish-cue` would then never dispatch for a release that really shipped.
`RELEASING.md` ("Notify after publish") therefore requires this change to move verification into
its own job first.

The binding interface is the Phase 3 wiring contract (version 3.1), archived in `.github` at
`openspec/changes/archive/2026-10-04-add-release-cascade-workflows/contract.md` (changelogs 3.1.1
and 3.1.2; cited as "wiring §N"), with the supervisor's addendum for the five join changes (the
`release.yml` env allow-list and the `runs-on` assertion of the wiring check). It builds on the
Phase 2 contract (`.github`
`openspec/changes/archive/2026-10-04-add-cascade-resolver/contract.md`, "P2 §N"). Where either
disagrees with `RELEASING.md` or an owner decision, those win, and the conflict goes to the
supervisor (wiring, "Sources"). This change was first built to contract version 2 (a reusable
notify workflow, callers at `@main`); the sandbox cycle's E1 result and owner decision 24 replaced
that shape, and the branch is rebuilt to version 3.1 (wiring §10.1).

## What Changes

- **Split `verify-published` out of `publish-cue`** (wiring §4.5, catalog_opm). The step "Verify
  the published build" leaves `publish-cue`, so that job ends at "Publish CUE catalog". A new job
  `verify-published`, named `Verify the published build`, runs
  `needs: [release-please, publish-cue]` and
  `if: needs.publish-cue.outputs.published == 'true'` with `permissions: {contents: read,
  packages: read}` and `timeout-minutes: 15`. Its steps are the tag checkout, "Read the pinned opm
  CLI version", "Install opm", "Login to GHCR" and the unchanged verify step. It stays an aid, not
  a gate (0011:D7): a finding fails only this job. The fixture gate on the tag stays in
  `publish-cue` before the publish. `publish-docs` keeps its `if:`; only its comment changes.
- **Add the caller-owned `notify-downstream` job** (wiring §4.3, §4.6 catalog_opm): `needs:
  [release-please, publish-cue]`, the condition
  `${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}`,
  `runs-on: ubuntu-latest`, `environment: cascade`, `timeout-minutes: 20`,
  `permissions: {contents: read}`, and one step that runs the pinned `cascade-notify` action with
  `tag: ${{ needs.release-please.outputs.opm_tag_name }}`, `client-id` and `private-key`. The
  action sends one `upstream-released` dispatch each to library, opm-operator and cli
  (wiring §3.1). Notify never depends on `verify-published` or `publish-docs`.
- **Add the receiver `.github/workflows/deps-cascade.yml`** (wiring §5, §5.2 catalog_opm). It runs
  on `repository_dispatch` (`upstream-released`), the daily sweep `17 5 * * *` and
  `workflow_dispatch` (`dry_run`, `gates_only`), with the §5 concurrency expression. Its `cascade`
  job calls the pinned `cascade-receive.yml` (compute and gates, no secret) with
  `dry-run: ${{ inputs.dry_run == true || vars.CASCADE_DRY_RUN != 'false' }}`, `setup-go: false`
  and `cue-version: v0.17.1`. Its caller-owned `publish` job declares `environment: cascade` and
  runs the pinned `cascade-publish` action with the same `dry-run` expression,
  `labels-managed: false`, `client-id` and `private-key`. The receiver accepts payloads from core
  and cli only (wiring §3.2) and is live only when `CASCADE_DRY_RUN` is exactly `false`; the
  action refuses to mint otherwise, whatever the `if:` says.
- **Add the per-PR gates caller `.github/workflows/cascade-gates.yml`** (wiring §8.3) on
  `pull_request_target` (`opened`, `reopened`, `synchronize`). It posts `cascade/freshness` (G2)
  and `cascade/settled` (G3) as `n/a` on non-release PRs. On the release PR it dispatches a
  gates-only receiver run. The mode comes from `CASCADE_G2_MODE` and `CASCADE_G3_MODE`, `warn`
  by default (owner decisions 11, 12).
- **Pin every cascade reference to one `.github` `main` SHA** (owner decision 24 for the actions,
  the supervisor's extension for the workflows and the resolver; wiring §2.4): the four `uses:`
  lines and the `ref:` of the resolver checkout in `cascade-task.yml`, five references, all
  `2376ffae4bfc665f327d51581350dea694c01504 # .github main`. A `.github` change reaches this repo
  only through a `ci(deps): pin the cascade to .github <sha7>` PR. catalog_opm has no
  `.github/dependabot.yml`, so there is no Dependabot ignore to add.
- **Check the wiring in CI on every PR** (wiring §10.1 item 6, with the addendum): a
  `.tasks/cascade/wiring-check.sh` run by `task cascade:wiring:check`, a step of `ci.yml`'s
  required job `Validate catalog` and a member of the aggregate `task check`. It asserts the exact
  shape of the two key-holding jobs, the `deps-cascade.yml` switches, the env allow-list of
  `release.yml`, that only those two jobs read the key or declare the Environment, and the one SHA
  and pin comment on all five references. It guards against mistakes; review and the `main`
  ruleset guard against a deliberate edit.
- **`AGENTS.md`** § Release & publishing: the verify job, notify, the receiver and publish, the
  gates, the pin and how it moves, the wiring check, the repo variables and the stop switches
  catalog_opm owns.

Not in this change:

- the cascade actions, reusable workflows and their scripts (`.github`
  `add-release-cascade-workflows`, merged);
- setting the repo variables (`CASCADE_DRY_RUN=true` is already set, wiring supervisor records);
- going live (Phase 4);
- making G2 or G3 required (Phase 5, `require-pin-freshness-gate`).

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is the job graph
of `release.yml` and the two new callers, shown as the YAML that decides them.

**Before** (`release.yml` on `main`)

```yaml
publish-cue:            # needs: release-please; if: opm_release_created == 'true'
  outputs: {published: ${{ steps.publish.outputs.published }}}
  steps: [checkout tag, read CLI pin, install opm, GHCR login, setup cue, task,
          vet:fixtures on tag, "Publish CUE catalog" (sets published=true),
          "Verify the published build"]   # a finding fails publish-cue after the push
publish-docs:           # needs: [release-please, publish-cue]
  if: always() && needs.publish-cue.outputs.published == 'true'
# no notify; no deps-cascade.yml; no cascade-gates.yml; cascade-task.yml checks the resolver out at ref: main
```

**After**

```yaml
publish-cue:            # unchanged gate, ends at "Publish CUE catalog"
  outputs: {published: ${{ steps.publish.outputs.published }}}
verify-published:       # name: Verify the published build
  needs: [release-please, publish-cue]
  if: needs.publish-cue.outputs.published == 'true'
  timeout-minutes: 15
  permissions: {contents: read, packages: read}
  steps: [checkout tag, read CLI pin, install opm, GHCR login, verify (unchanged)]
publish-docs:           # unchanged
  if: always() && needs.publish-cue.outputs.published == 'true'
notify-downstream:      # name: Notify downstream; caller-owned key-holding job
  needs: [release-please, publish-cue]
  if: ${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}
  runs-on: ubuntu-latest
  environment: cascade
  timeout-minutes: 20
  permissions: {contents: read}
  steps:
    - uses: open-platform-model/.github/.github/actions/cascade-notify@<SHA> # .github main
      with: {tag: opm_tag_name, client-id: vars.CASCADE_APP_CLIENT_ID, private-key: secrets.CASCADE_APP_PRIVATE_KEY}
# + deps-cascade.yml   cascade: cascade-receive.yml@<SHA>; publish: cascade-publish@<SHA> in environment cascade
# + cascade-gates.yml  gates: cascade-gates.yml@<SHA>
# ~ cascade-task.yml   resolver checkout ref: <SHA> # .github main
# + ci.yml Validate catalog: task cascade:wiring:check
```

`<SHA>` is `2376ffae4bfc665f327d51581350dea694c01504`, one SHA on all five references.

## Impact

- **Published catalog: none.** No file under `src/` changes and no member moves to a new
  `apiVersion` segment. Every commit is a non-releasing `ci`, `docs` or `chore` type, so `opm`
  (stable 4.x line) does not advance. The PR title is `ci: join the release cascade` (wiring §1).
- **library, opm-operator, cli:** after their own `join-release-cascade` merges, they receive one
  `upstream-released` dispatch per catalog release. A dispatch to a repo with no receiver yet
  returns 204 and starts nothing (wiring §1).
- **modules fleet, subscribing platforms, cli fixtures under `testing.opmodel.dev`:** nothing to
  do. Leaves stay manual (owner decision 15).
- **Release PRs** gain two commit statuses, `success` in `warn` mode; neither is required
  (wiring §10). `Validate catalog` gains one offline step.
- **Release workflow:** a verify finding now shows as a red `Verify the published build` job
  instead of a red `Publish opm`. Recovery for a missed `publish-docs` is unchanged.
- **Every later `.github` cascade change** needs one pin PR here (owner decision 24's cost).

**Depends on / gates:**

- Depends on: `.github` `add-release-cascade-workflows`, merged as PR 9 (`2376ffa`). Before this
  PR merges, `gh api repos/open-platform-model/.github/compare/2376ffae4bfc665f327d51581350dea694c01504...main --jq .status`
  prints `identical` or `ahead` (wiring §10.1 "Pre-merge check").
- Depends on: workspace `RELEASING.md` describing the version 3.1 shapes (merged, workspace
  PR 26).
- Depends on: catalog_opm `add-deps-cascade-task` and `prepare-release-cascade`, both merged.
- Depends on: Phase 0 settings in catalog_opm, verified: the `cascade` Environment (`main` only)
  with `CASCADE_APP_PRIVATE_KEY` and `CASCADE_APP_CLIENT_ID`; the repo variable
  `CASCADE_DRY_RUN=true`.
- Gates: the Phase 3 exit gate for catalog_opm. A `workflow_dispatch` dry run on `main` must show
  mode `fresh` and action `noop` (or the diff `task -x deps:cascade` gives locally), `Publish`
  skipped, and the `Compute` log naming `scripts from open-platform-model/.github <SHA>`; both
  statuses must appear on the next PR; the next `cascade-task.yml` run checks the resolver out at
  `<SHA>` (wiring §1, §10).
- Gates: Phase 4, `CASCADE_DRY_RUN=false`, only after one non-noop dry-run summary was read and
  found correct (wiring §1, §15 item 5). Phase 5 `require-pin-freshness-gate`.
- Peers (same phase, independent): core, library, opm-operator and cli `join-release-cascade`.

## Enhancement

None. The design lives in workspace `RELEASING.md` ("The cascade", "Gates", "Stop switches",
"Owner settings", "Rollout and changes") and the two cascade contracts. No enhancement backs it,
so there is no `enhancement.yaml`.
