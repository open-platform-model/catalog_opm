## Context

This change touches no catalog member, no file under `src/` and no `apiVersion` segment. It edits
`.github/workflows/release.yml`, `ci.yml` and `cascade-task.yml`, adds two workflow files, a
check script and a task, and amends `AGENTS.md`. Sources, highest authority first:

1. the owner decisions (3, 5, 7, 11, 12, 13, 19, 22, and 24, which pins the cascade actions by
   SHA and supersedes decision 13's `@main` for them; 26 drops the sandbox);
2. workspace `RELEASING.md` on `main` (501594c, which describes the version 3.1 shapes);
3. the Phase 2 contract ("P2 §N") and the `.github` main specs;
4. the Phase 3 wiring contract, version 3.1 ("wiring §N"), at `.github`
   `openspec/changes/archive/2026-10-04-add-release-cascade-workflows/contract.md` with its
   changelogs 3.1.1 and 3.1.2, and the supervisor's addendum for the five join changes. §10.1 is
   the checklist this rebuild follows.

The branch was first built to wiring version 2 (commits `f18fce6`, `87be9b2`, `c6b314e`): a
reusable notify workflow that declared the Environment, a receiver whose reusable `publish` job
held the key, callers at `@main`. The sandbox cycle showed (E1) that a reusable-workflow job does
not see the caller's Environment secrets without `secrets: inherit`, so version 3 moved notify and
publish into composite actions run by caller-owned jobs, and owner decision 24 pinned them by SHA.
The later commits on this branch replace the version 2 shapes; the version 2 commits stay in the
history.

State on `main` (fe62d0e) that the design relies on:

- `release.yml` has workflow-level `permissions` of `contents: write`, `pull-requests: write`,
  `packages: write` and `actions: write`, and workflow-level `env` `OPM_REGISTRY` and
  `CUE_REGISTRY` (both registry maps, nothing that runs code at startup).
- `release-please` outputs `opm_release_created`, `opm_tag_name` (`opm-vX.Y.Z`) and `opm_version`.
- `publish-cue` runs only on `opm_release_created == 'true'`. It exports `published`, set by the
  last line of "Publish CUE catalog". On `main` it ends with "Verify the published build", which
  reads `src/cue.mod/module.cue` and runs `opm catalog registry check <path>@v<version> --compat`.
- `publish-docs` runs on `always() && needs.publish-cue.outputs.published == 'true'`.
- `ci.yml` job `ci`, `Validate catalog`, is the required check. It runs on every PR with no path
  filter and already installs Task.
- `cascade-task.yml` (Phase 2) checks out `open-platform-model/.github` at `ref: main`,
  `path: org-github`, and sets `CASCADE_RESOLVER_REAL` unconditionally.
- catalog_opm has no `.github/dependabot.yml`.

## Goals / Non-Goals

**Goals:**

- A release that reached GHCR always dispatches to library, opm-operator and cli, whatever the
  verify step finds.
- catalog_opm receives core and cli releases in dry-run mode and posts G2 and G3 on its release
  PRs.
- Every caller matches the wiring contract byte for byte where it gives the YAML, and CI holds
  that shape on every PR, so the five joins stay uniform and the key-holding jobs stay locked.

**Non-Goals:**

- Any cascade logic in this repo beyond the callers and the shape check. Validation, token
  minting, branch strategy and gate evaluation live in `.github`.
- New required checks. None of the new jobs or statuses is required (wiring §10); the wiring
  check is a step of the existing required job.
- Changing the publish gate, the fixture gate or `publish-docs` behaviour.

## Decisions

### D1. `verify-published` is its own job, and nothing waits for it

`release.yml` after the split:

```yaml
  verify-published:
    name: Verify the published build
    needs: [release-please, publish-cue]
    if: needs.publish-cue.outputs.published == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
      packages: read
    steps:
      - name: Clone the released tag
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          ref: ${{ needs.release-please.outputs.opm_tag_name }}
      - name: Read the pinned opm CLI version      # from publish-cue, comment reworded
      - name: Install opm                          # verbatim from publish-cue
      - name: Login to GHCR                        # from publish-cue, comment reworded
      # the existing comment: an aid, not a gate (0011:D7)
      - name: Verify the published build           # verbatim, env VERSION from opm_version
```

- **Why a job and not `continue-on-error`.** `continue-on-error: true` on the step would keep
  `publish-cue` green, but it would also hide a finding. 0011:D7 wants the finding visible. A
  separate job shows it red under its own name, and `notify-downstream` and `publish-docs` never
  depend on it.
- **Same checkout pin.** The job keeps the file's checkout pin, v6.0.2 `de0fac2e…`, so the file
  has one pin (wiring §2.2).
- **Permissions.** The job declares `contents: read` and `packages: read`. Before, the step held
  the workflow's write grants. A registry read needs no write.
- **The moved steps stay verbatim**, including the inline `${{ secrets.GITHUB_TOKEN }}` and
  `${{ github.actor }}` in "Login to GHCR", which `publish-cue` and `ci.yml` use in the same form.
  Neither value is attacker-controlled. Moving the login to `env:` (review nit 10) is a repo-wide
  `ci` change, not this one. Two comments are rewritten, because the new job only reads. Only the
  verify step's `run:` and `env:` stay byte-identical to `main` (wiring §4.5, "the unchanged
  verify step").
- **`timeout-minutes: 15`** bounds a hung registry read (review nit 11).
- **No CUE and no Task in the job.** The verify step runs only `grep`, `sed` and `opm`.
  `OPM_REGISTRY` comes from the workflow-level `env`.
- **`publish-cue` keeps the fixture gate before the publish.** If the gate fails, nothing was
  published, `published` is unset, and verify, docs and notify all skip, which is correct.

### D2. `publish-docs` keeps `always()`; only the comments change

After the split, "Publish CUE catalog" is the last step of `publish-cue`. `always()` still
matters in one case: a post-job step, such as checkout's cleanup, can fail `publish-cue` after
`published=true` is set. Without `always()`, that failure would skip `publish-docs` for a module
that is on GHCR. Wiring §4.5 also says to keep `publish-docs` unchanged, so the `if:` stays. The
`publish-cue` outputs comment and the `publish-docs` comment are rewritten to say this.

**The gap `verify-published` keeps (review finding 4).** Its `if:` is wiring §4.5's literal
`needs.publish-cue.outputs.published == 'true'`, with no status function, so the default
`success()` applies. In the one case above (a post-job step fails `publish-cue` after the push),
`publish-docs` and `notify-downstream` still run, but verification is skipped. The fix would be
`${{ !cancelled() && needs.publish-cue.outputs.published == 'true' }}`. It is a contract change
(wiring §4.5), so this branch keeps the contract's text and reports the gap to the supervisor.
Recovery when it happens: run `opm catalog registry check <path>@v<version> --compat` by hand
against the released version.

### D3. `notify-downstream` is the wiring §4.6 catalog_opm block

```yaml
  notify-downstream:
    name: Notify downstream
    needs: [release-please, publish-cue]
    if: ${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}
    runs-on: ubuntu-latest
    environment: cascade
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - name: Notify downstream
        uses: open-platform-model/.github/.github/actions/cascade-notify@2376ffae4bfc665f327d51581350dea694c01504 # .github main
        with:
          tag: ${{ needs.release-please.outputs.opm_tag_name }}
          client-id: ${{ vars.CASCADE_APP_CLIENT_ID }}
          private-key: ${{ secrets.CASCADE_APP_PRIVATE_KEY }}
```

- **The caller owns the Environment job** (wiring §4.3, E1). This job declares
  `environment: cascade` and passes the key to the action as an input; the action mints the
  token scoped to library, opm-operator and cli (wiring §2.3). There is no reusable notify
  workflow.
- **The key rule** (wiring §10.1 item 9): the key is read only in the caller-owned
  `notify-downstream` or `publish` job, which declares `environment: cascade` and passes
  `secrets.CASCADE_APP_PRIVATE_KEY` only as the `private-key` input of the SHA-pinned cascade
  action; that job has no checkout or `run:` of its own, and no `env:`, `container:` or
  `services:` (the publish action checks out the repo but never runs it); no reusable call passes
  `secrets:` or `secrets: inherit`.
- **The tag** is `opm-vX.Y.Z`, the catalog shape of wiring §3.3; receivers strip `opm-` for
  `CASCADE_EXPECT` (wiring §3.4). The source is never passed: the action derives it from
  `GITHUB_REPOSITORY` (wiring §3.1).
- **`!cancelled()` and `published`** mirror `publish-docs`. A cancelled run never notifies. When
  `publish-cue` fails before the push, `published` is unset and notify skips.
- **The Environment's `main`-only policy** applies: a run from another ref fails at the
  deployment check before any step runs (E1b). Release runs only on `main`.
- **Recovery.** A red `Notify downstream` job is re-run with "Re-run failed jobs" on the Release
  run. Otherwise the three receivers' daily sweeps pick the release up within a day. A failure at
  startup is a bad pin (a SHA that is not a `.github` commit with the action), fixed by a pin PR;
  a pinned SHA cannot go missing the way a `@main` file could (wiring §10.1 item 10).

### D4. `deps-cascade.yml` is wiring §5 with the §5.2 catalog_opm `jobs:` map

Two jobs:

- `cascade` calls the pinned `cascade-receive.yml` (compute and gates; they hold no secret) with
  `contents: read`, `pull-requests: read` and `statuses: write`, the §5 switch inputs,
  `setup-go: false` and `cue-version: v0.17.1`. `labels-managed` left this call: the input moved
  to the `cascade-publish` action, and passing it to the workflow is an actionlint error and a run
  failure (wiring §5.1).
- `publish` is caller-owned: `needs: cascade`, the §5 `if:` byte for byte,
  `runs-on: ubuntu-latest`, `environment: cascade`, `timeout-minutes: 15`,
  `permissions: {contents: read, pull-requests: read}`, and one step running the pinned
  `cascade-publish` with `dry-run` (the same expression as the `cascade` job),
  `labels-managed: false`, `client-id` and `private-key`.

Values:

- `cron: '17 5 * * *'`: tier 1, off the hour, staggered before opm-operator (`47 5`) and cli
  (`17 6`);
- `setup-go: false`, because `cascade.sh` needs only cue, Task, git and yq;
- `labels-managed: false`, because this repo has no `labels.yml`, so publish creates the bot
  labels with `--force` (wiring §6.4);
- `cue-version: v0.17.1`, passed explicitly although it equals the `.github` default. This repo
  pins its CUE in five other workflow places (`ci.yml`, `cascade-task.yml`, two in `release.yml`,
  `branch-publish.yml`). If the receiver took `.github`'s default, a CUE bump here would leave the
  receiver and G2 running `cue mod get` and `cue mod tidy` on the old CUE, and no grep for the old
  version in this repo would find it. Wiring §5.1 and §5.2 keep it for catalog_opm (review
  finding 5 is settled by the contract).

**Dry run fails closed, in three places** (wiring §9.1). `dry-run` is true unless
`CASCADE_DRY_RUN` is exactly `false`, so an unset variable never pushes. The `publish` `if:`
repeats the switches so a dry run starts no Environment job, and `cascade-publish`'s required
`dry-run` input refuses to mint unless it is exactly `false`, so a mistyped `if:` cannot make a
dry run publish. The supervisor set `CASCADE_DRY_RUN=true` in catalog_opm (wiring supervisor
records).

The receiver accepts payload sources core and cli (wiring §3.2). cli is the release-tool edge, for
`.opm-cli-version`. core moves `src/cue.mod/module.cue`.

### D5. `cascade-gates.yml` is wiring §8.3 with the pin

The workflow runs on `pull_request_target` (`opened`, `reopened`, `synchronize`) and has
`permissions: {}`. The job grants `statuses: write` and `actions: write` and calls the pinned
`cascade-gates.yml` with the two mode variables.

- **`pull_request_target` is safe here.** The reusable job checks out nothing and runs no PR code
  (wiring §8.3). Its token holds `statuses: write` and `actions: write`; the job uses them only to
  post statuses and dispatch `deps-cascade.yml` on `main`. `actions: write` would also let a token
  cancel, re-run or delete runs and artifacts or toggle workflows, which is why nothing from the PR
  runs in that job (review finding 3).
- **The gates-only run it dispatches does run repo code** (wiring §8.2): its `compute` runs the
  release head's `task -x deps:cascade` in a worktree, read-only and without secrets. See Risks.
- **Coverage of catalog release PRs.** catalog_opm's release PR head moves by App-token pushes
  (release-please and the identity advance), which fire `synchronize`, so the statuses follow the
  head.
- **G3 here watches only core** (wiring §3.5). The cli → catalog_opm edge is release-tool only
  and never counts.
- **The statuses.** A clean result is `success` in both modes. `warn` posts `success` with a
  `WARN:` description on a problem or an evaluator error; `enforce` posts `failure` on a problem,
  `pending` while evaluating and `error` when evaluation fails (wiring §8.1, §8.3; review
  finding 6).

### D6. No spec delta: the requirements live in the proposal, the decisions and `AGENTS.md`

Wiring §10 and §10.1 item 9 ask each B for spec deltas. catalog_opm's workspace has no specs by
design (`openspec/config.yaml` Principle II, the `catalog-change` schema): every change carries
`skip_specs: true`, and a `specs/` directory is forbidden. The clause "as the repo's workspace
requires" therefore gives no delta here. The requirements a delta would carry are written as
decisions instead: the verify split (D1), the caller-owned publish job with the §5 `dry-run`
expression and the never-publish-unless-`false` rule (D4), the one pinned SHA checked in the
required job (D7, D8), and the key rule (D3). Their durable rules land in `AGENTS.md`.

### D7. One `.github` `main` SHA on every cascade reference

Owner decision 24 pins the two cascade actions by SHA in all five repos; the supervisor extended
the pin to the two reusable workflows and to the resolver checkout in `cascade-task.yml`
(wiring §2.4). catalog_opm has five references, all
`2376ffae4bfc665f327d51581350dea694c01504 # .github main`, the squash commit of `.github` PR 9
(`compare 2376ffa...main` prints `identical`):

| File | Reference |
| --- | --- |
| `release.yml` | `uses: …/actions/cascade-notify@<SHA> # .github main` |
| `deps-cascade.yml` | `uses: …/workflows/cascade-receive.yml@<SHA> # .github main` |
| `deps-cascade.yml` | `uses: …/actions/cascade-publish@<SHA> # .github main` |
| `cascade-gates.yml` | `uses: …/workflows/cascade-gates.yml@<SHA> # .github main` |
| `cascade-task.yml` | `ref: <SHA> # .github main` on the `open-platform-model/.github` checkout |

- **Why the resolver too.** CI's `cascade-task.yml` tests this repo's `deps:cascade` against the
  resolver. At `ref: main` it would test a resolver the receiver does not run; at the pin it
  tests the one `cascade-receive.yml` checks out at its own `job.workflow_sha`.
- **How it moves.** Only by a `ci(deps): pin the cascade to .github <sha7>` PR that replaces the
  SHA in all five places (`grep -rn -A1 'open-platform-model/.github' .github/workflows`), after
  the `compare` check and `task cascade:wiring:check` pass (`RELEASING.md` "Moving the cascade
  pin"). A merge to `.github` `main` changes nothing here until then.
- **This branch pins `main` from the start.** `.github` PR 9 merged (and its branch was deleted)
  before this rebuild, so there is no branch-head pin and no separate swap commit
  (wiring §2.4 "Before A merges" does not apply).
- **Dependabot.** catalog_opm has no `.github/dependabot.yml`; wiring §10.1 item 7 adds nothing
  here, and none is created.

### D8. The wiring check holds the shape on every PR

`.tasks/cascade/wiring-check.sh` is the wiring §10.1 item 6 script with `RECEIVER=true` and
`PIN_COMMENT='.github main'`, plus the supervisor's addendum:

- **`release.yml`'s workflow `env` is an allow-list**: exactly `OPM_REGISTRY` and `CUE_REGISTRY`
  may appear. Workflow-level `env` reaches the notify action's steps, so a new key there (for
  example `BASH_ENV`) could make a step in the key-holding job run repo code. The contract's
  deny-list of three names is replaced by this list.
- **Every key-holding job runs on `ubuntu-latest`**: `notify-downstream` and `publish`. A
  self-hosted runner label would hand the key to a machine outside GitHub's hosted pool.

It runs as `task cascade:wiring:check`, a step "Verify the cascade wiring" in `ci.yml`'s required
job `Validate catalog` right after "Install Task", and as a member of the aggregate `task check`.
It needs mikefarah yq v4 (preinstalled on the runner; the script refuses any other yq).

**What it does and does not stop.** It catches a mistaken edit: a changed `publish` `if:`, an
extra step or key, a second SHA, a branch pin, the key read elsewhere, an `env:` that would run
repo code. A deliberate edit could change the script in the same PR; review and the `main`
ruleset (PR required, the required check, owner bypass pull-request-only) guard against that.

## Research & Decisions

### Where notify hooks in

**Context**: notify must run only after the artifact is public (`RELEASING.md` "Notify after
publish") and must not be suppressed by a non-gating check.
**Decision**: hook on `publish-cue.outputs.published` after the split (D1, D3), not on
`publish-cue` success alone, and not on `verify-published` or `publish-docs`.
**Rationale**: `published` is set right after the push, so it is the most direct proof that the
module is on GHCR. `publish-docs` already keys on it.

### What actionlint can and cannot check here

**Context**: wiring §10 asks each B to run actionlint on the new files.
**Explored**: actionlint v1.7.12 (scratchpad binary). It does not fetch a remote
`owner/repo/...@ref` call, and it does not check a composite action's inputs at all.
**Decision**: run actionlint on every section, and check each caller against the `.github` files
at the pinned SHA by copying them into a scratch tree and pointing each `uses:` at the local copy
(workflows), and by comparing the `with:` keys with the action's `inputs` (actions). The wiring
check (D8) is the lasting check for the actions' inputs.
**Rationale**: a misspelled input on a remote call fails only at run time, which here means a
release.

### Caller inputs checked

Filled by tasks 2.2 and 3.3.

### Wiring check run

Filled by task 5.4.

### Re-grep

Filled by task 6.2.

## Risks / Trade-offs

- [The pin is not on `.github` `main`] → a key-holding job would run code no `.github` review
  approved. Mitigation: `2376ffa` is PR 9's squash commit (`compare` prints `identical`); the
  supervisor's pre-merge check repeats the `compare` (wiring §10.1).
- [A verify finding is now easier to miss, because the release run's headline job is green] → the
  job is named `Verify the published build` and the run is still red overall. It was never a gate
  (0011:D7).
- [`verify-published` is skipped when a post-job step fails `publish-cue` after the push] → D2;
  the contract's `if:` is kept and the gap reported.
- [Shared App key reach (wiring Facts, §11.5)] → whoever can run a job in catalog_opm's `cascade`
  Environment can mint a token for all five product repos. Mitigation: the Environment is `main`
  only, `main` is ruleset-protected, and the wiring check refuses a third job that declares the
  Environment or reads the key, and any `env:`, `container:`, `services:` or extra step on the two
  that do.
- [`pull_request_target` on a public repo] → no checkout and no PR code in the per-PR job (D5);
  its token holds `statuses: write` and `actions: write` only.
- [Release-head code in `compute` can shape the plan and the gate results (review finding 1;
  wiring §8.2, `.github` design Risks m3, wiring §15 item 11)] → the gates-only run's `compute`
  runs the release head's `task -x deps:cascade` in a `git worktree` of `repo/`, before "Run the
  task", in the same job and on the same runner. That code shares `repo/.git` (config, hooks) and
  can write the runner's `GITHUB_ENV`, `GITHUB_PATH` or `BASH_ENV`, so it could influence the
  later `compute` steps, the `plan.json` and bundle they build, and `gates.json`. `publish`
  re-derives and verifies the plan before it mints, but checks it only against itself and guards
  `.github/workflows/` only, so the bundle it pushes with the App key can carry what that code put
  there. Any user with write access can push a `release-please--x` branch, so release heads are
  not limited to release-please. Accepted for now in `.github` (wiring §8.2 "Accepted"); the
  controls left are: compute holds no secret and only read permissions, the result lands only in
  a bot-authored `deps/cascade` PR that the owner reviews and merges by hand (owner decision 7),
  and this repo is in dry run until Phase 4. The fix (G2 in its own job, or a fresh clone after
  the plan is uploaded) belongs in `.github` and is reported to the supervisor. "compute holds no
  secret" is true but does not address this.
- [Workflows guard (wiring §7.6, `WF_GUARD_RULE=tree`)] → merging this change edits
  `.github/workflows/` on `main`. While the receiver is in dry run no `deps/cascade` branch
  exists, so there is nothing to recreate.
- [Every `.github` cascade change needs a pin PR here] → owner decision 24's stated cost; the pin
  PR is mechanical and checked by the wiring step.

## Durable decisions

- **`verify-published` is an aid in its own job. Notify and docs publishing key on
  `publish-cue`'s `published` output, never on verification.** Lands in `AGENTS.md`
  § Release & publishing (task 1.3).
- **The cascade wiring catalog_opm owns**: the caller-owned `notify-downstream` job and what it
  dispatches; `deps-cascade.yml` (the reusable `cascade` call plus the caller-owned `publish`
  job) and its sources (core, cli); `cascade-gates.yml`; the repo variables `CASCADE_DRY_RUN`
  (live only at exactly `false`), `CASCADE_NOTIFY=off`, `CASCADE_G2_MODE` and `CASCADE_G3_MODE`;
  recovery of a failed notify. Lands in `AGENTS.md` § Release & publishing (task 6.1).
- **The key rule and the pin**: the key only in the two caller-owned jobs as an action input;
  one `.github` `main` SHA on all five references, moved only by a `ci(deps)` pin PR; the wiring
  check in `Validate catalog`. Lands in `AGENTS.md` § Release & publishing (task 6.1).
- **A CUE bump moves every pinned CUE literal under `.github/workflows/`, including
  `cue-version:` in `deps-cascade.yml`.** Lands in `AGENTS.md` § Release & publishing.
- **Phase 4 and Phase 5 steps** (setting `CASCADE_DRY_RUN=false`, making G2 and G3 required) stay
  with the change and `RELEASING.md`. They are rollout steps, not authoring rules.
