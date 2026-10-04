## Why

The release cascade (workspace `RELEASING.md`, "The cascade", `:162-325`) has two halves per repo.
Phase 2 gave catalog_opm the first half, `task -x deps:cascade` (archived
`openspec/changes/archive/2026-10-04-add-deps-cascade-task`). Nothing calls it yet, and nothing
tells library, opm-operator or cli when a catalog release reaches GHCR. Phase 3 ("Rollout and
changes", `:538`, `:569`) wires each repo to the shared notify, receive and gates workflows that
the `.github` change `add-release-cascade-workflows` adds. This change is catalog_opm's part.

catalog_opm has a hazard the other repos lack. `publish-cue` ends with "Verify the published
build" (`.github/workflows/release.yml:235-244`), a non-gating check that fails the job after the
module is already on GHCR. A notify job that `needs: publish-cue` would then never dispatch for a
release that really shipped. `RELEASING.md:172` and `:569` therefore require this change to move
verification into its own job first.

The binding interface is the Phase 3 wiring contract (version 2, cited as "wiring §N"), which
builds on the Phase 2 contract (`open-platform-model/.github`,
`openspec/changes/archive/2026-10-04-add-cascade-resolver/contract.md`, cited as "P2 §N"). Where
either disagrees with `RELEASING.md` or an owner decision, those win, and the conflict goes to the
supervisor (wiring, "Sources").

## What Changes

- **Split `verify-published` out of `publish-cue`** (wiring §4.5, catalog_opm). The step "Verify the
  published build" leaves `publish-cue`, so that job ends at "Publish CUE catalog"
  (`release.yml:225-233`). A new job `verify-published`, named `Verify the published build`, runs
  `needs: [release-please, publish-cue]` and
  `if: needs.publish-cue.outputs.published == 'true'` with `permissions: {contents: read,
  packages: read}`. Its steps are the tag checkout, "Read the pinned opm CLI version", "Install opm",
  "Login to GHCR" and the unchanged verify step. It stays an aid, not a gate (0011:D7): a finding
  fails only this job. The fixture gate on the tag (`release.yml:218-219`) stays in `publish-cue`
  before the publish. `publish-docs` keeps its `if:` (`:266`); only its comment changes.
- **Add the `notify-downstream` job** (wiring §4.3, §4.5) with
  `needs: [release-please, publish-cue]`, the condition
  `${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}`
  and `permissions: {contents: read}`. It calls
  `open-platform-model/.github/.github/workflows/cascade-notify.yml@main` with
  `tag: ${{ needs.release-please.outputs.opm_tag_name }}`. The reusable workflow sends one
  `upstream-released` dispatch to library, opm-operator and cli (`RELEASING.md:169-175`,
  wiring §3.1). Notify never depends on `verify-published` or `publish-docs`.
- **Add the receiver caller `.github/workflows/deps-cascade.yml`** (wiring §5). It runs on
  `repository_dispatch` (`upstream-released`), the daily sweep `17 5 * * *` and
  `workflow_dispatch` (`dry_run`, `gates_only`), with the wiring §5 concurrency expression.
  It calls `cascade-receive.yml@main` with
  `dry-run: ${{ inputs.dry_run == true || vars.CASCADE_DRY_RUN != 'false' }}`, `setup-go: false`
  and `labels-managed: false`. The receiver accepts payloads from core and cli only (wiring §3.2).
  It is live only when `CASCADE_DRY_RUN` is exactly `false`.
- **Add the per-PR gates caller `.github/workflows/cascade-gates.yml`** (wiring §8.3) on
  `pull_request_target` (`opened`, `reopened`, `synchronize`). It posts `cascade/freshness` (G2)
  and `cascade/settled` (G3) as `n/a` on non-release PRs. On the release PR it dispatches a
  gates-only receiver run. The mode comes from `CASCADE_G2_MODE` and `CASCADE_G3_MODE`, `warn`
  by default (owner decisions 11, 12).
- **`AGENTS.md`** § Release & publishing: the verify job, notify, the receiver, the gates, the
  repo variables and the stop switches catalog_opm owns.

Not in this change:

- the reusable workflows and their scripts (`.github` `add-release-cascade-workflows`);
- setting the repo variables (the supervisor sets `CASCADE_DRY_RUN=true` before merge,
  wiring §1);
- going live (Phase 4);
- making G2 or G3 required (Phase 5, `require-pin-freshness-gate`).

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is the job graph
of `release.yml`, shown as the YAML that decides it.

**Before** (`release.yml:155-279` on `main`, fce215a)

```yaml
publish-cue:            # needs: release-please; if: opm_release_created == 'true'
  outputs: {published: ${{ steps.publish.outputs.published }}}
  steps: [checkout tag, read CLI pin, install opm, GHCR login, setup cue, task,
          vet:fixtures on tag, "Publish CUE catalog" (sets published=true),
          "Verify the published build"]   # a finding fails publish-cue after the push
publish-docs:           # needs: [release-please, publish-cue]
  if: always() && needs.publish-cue.outputs.published == 'true'
# no notify; no deps-cascade.yml; no cascade-gates.yml
```

**After**

```yaml
publish-cue:            # unchanged gate, ends at "Publish CUE catalog"
  outputs: {published: ${{ steps.publish.outputs.published }}}
verify-published:       # name: Verify the published build
  needs: [release-please, publish-cue]
  if: needs.publish-cue.outputs.published == 'true'
  permissions: {contents: read, packages: read}
  steps: [checkout tag, read CLI pin, install opm, GHCR login, verify (unchanged)]
publish-docs:           # unchanged
  if: always() && needs.publish-cue.outputs.published == 'true'
notify-downstream:      # name: Notify downstream
  needs: [release-please, publish-cue]
  if: ${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}
  permissions: {contents: read}
  uses: open-platform-model/.github/.github/workflows/cascade-notify.yml@main
  with: {tag: ${{ needs.release-please.outputs.opm_tag_name }}}
# + .github/workflows/deps-cascade.yml   (wiring §5; cron 17 5 * * *)
# + .github/workflows/cascade-gates.yml  (wiring §8.3)
```

## Impact

- **Published catalog: none.** No file under `src/` changes and no member moves to a new
  `apiVersion` segment. Every section commit is a non-releasing `ci` or `chore` type, so `opm`
  (stable 4.x line) does not advance. The PR title is `ci: join the release cascade` (wiring §1).
- **library, opm-operator, cli:** after their own `join-release-cascade` merges, they receive one
  `upstream-released` dispatch per catalog release. A dispatch to a repo with no receiver yet
  returns 204 and starts nothing (wiring §1).
- **modules fleet, subscribing platforms, cli fixtures under `testing.opmodel.dev`:** nothing to
  do. Leaves stay manual (owner decision 15).
- **Release PRs** gain two commit statuses, `success` in `warn` mode; neither is required
  (wiring §10). `Validate catalog` is untouched.
- **Release workflow:** a verify finding now shows as a red `Verify the published build` job
  instead of a red `Publish opm`. Recovery for a missed `publish-docs` is unchanged.

**Depends on / gates:**

- Depends on: `.github` `add-release-cascade-workflows` **merged first**. The callers reference
  `cascade-notify.yml`, `cascade-receive.yml` and `cascade-gates.yml` at `@main` (owner
  decision 13). Merged earlier, GitHub could not load `release.yml`, so no release could run.
  A merges only after the sandbox cycle is green (wiring §1, §11).
- Depends on: the workspace PR with the `RELEASING.md` amendments of wiring §14, merged before or
  with A. `RELEASING.md:460` still says `CASCADE_DRY_RUN=true` stops the receiver, while this
  change documents "live only at exactly `false`".
- Depends on: catalog_opm `add-deps-cascade-task` (archived 2026-10-04) and
  `prepare-release-cascade` (archived 2026-10-02), both merged (`RELEASING.md:569`).
- Depends on: Phase 0 settings in catalog_opm, already verified: the `cascade` Environment
  (`main` only) with `CASCADE_APP_PRIVATE_KEY` and `CASCADE_APP_CLIENT_ID`
  (`RELEASING.md:516-527`).
- Before merge: the supervisor sets the repo variable `CASCADE_DRY_RUN=true` (wiring §1, §10).
- Gates: the Phase 3 exit gate for catalog_opm. A `workflow_dispatch` dry run on `main` must show
  mode `fresh` and action `noop` (or the diff `task -x deps:cascade` gives locally), and both
  statuses must appear on the next PR (wiring §1, §10).
- Gates: Phase 4, `CASCADE_DRY_RUN=false`, only after one non-noop dry-run summary was read and
  found correct (wiring §1, §15 item 5). Gates: Phase 5 `require-pin-freshness-gate`.
- Peers (same phase, independent): core, library, opm-operator and cli `join-release-cascade`.

## Enhancement

None. The design lives in workspace `RELEASING.md` ("The cascade", "Gates", "Stop switches",
"Owner settings", "Rollout and changes") and the two cascade contracts. No enhancement backs it,
so there is no `enhancement.yaml`.
