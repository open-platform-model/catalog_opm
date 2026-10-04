## Context

This change touches no catalog member, no file under `src/` and no `apiVersion` segment. It edits
`.github/workflows/release.yml`, adds two workflow files and amends `AGENTS.md`. Sources, highest
authority first:

1. the owner decisions (3, 5, 7, 11, 12, 13, 19, 22);
2. workspace `RELEASING.md` on `main` (1b11159);
3. the Phase 2 contract ("P2 §N") and the `.github` main specs;
4. the Phase 3 wiring contract, version 2 ("wiring §N"), binding for every `join-release-cascade`.

State on `main` (fce215a) that the design relies on:

- `release.yml` has workflow-level `permissions` of `contents: write`, `pull-requests: write`,
  `packages: write` and `actions: write` (`:8-12`). It also has workflow-level `OPM_REGISTRY` and
  `CUE_REGISTRY` (`:14-20`).
- `release-please` outputs `opm_release_created`, `opm_tag_name` (`opm-vX.Y.Z`) and `opm_version`
  (`:30-33`).
- `publish-cue` (`:155-244`) runs only on `opm_release_created == 'true'` (`:158`). It exports
  `published` (`:162-163`), set by the last line of "Publish CUE catalog" (`:225-233`). Its steps,
  in order:
  - checkout of the tag with `actions/checkout@de0fac2e…` v6.0.2 (`:169-172`);
  - "Read the pinned opm CLI version" (`:179-182`) and "Install opm" (`:184-194`);
  - "Login to GHCR" (`:196-199`);
  - Setup CUE, Install Task and the fixture gate on the tag (`:208-219`);
  - the publish (`:225-233`);
  - "Verify the published build" (`:235-244`). It reads `src/cue.mod/module.cue` and runs
    `opm catalog registry check <path>@v<version> --compat`. Its comment calls it "an aid, not a
    gate (0011 D7)".
- `publish-docs` (`:263-279`) runs on `always() && needs.publish-cue.outputs.published == 'true'`
  (`:266`). Its comment (`:246-262`) says `always()` exists so that a failure of the later
  verification step cannot skip it. The comment on `publish-cue` (`:160-161`) says the same.
- `ci.yml` job `ci`, `Validate catalog`, is the required check. `cascade-task.yml` (Phase 2)
  already checks out `.github` at `path: org-github`, the P2 §11 C4 layout the receiver copies.
- `AGENTS.md:229` says "A post-publish `opm catalog registry check --compat` verifies the pushed
  build (an aid, not a gate)". `AGENTS.md:224-253` is § Release & publishing.
- `RELEASING.md:172` and `:569` name this change as the one that moves verification into its own
  job.

## Goals / Non-Goals

**Goals:**

- A release that reached GHCR always dispatches to library, opm-operator and cli, whatever the
  verify step finds.
- catalog_opm receives core and cli releases in dry-run mode and posts G2 and G3 on its release
  PRs.
- Every caller matches the wiring contract byte for byte where it gives the YAML, so the five
  joins stay uniform.

**Non-Goals:**

- Any logic in this repo beyond the callers. Validation, token minting, branch strategy and gate
  evaluation live in the `.github` reusable workflows.
- New required checks. None of the new jobs or statuses is required (wiring §10).
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
      # the existing comment: an aid, not a gate (0011 D7)
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
  `${{ github.actor }}` in "Login to GHCR". Two comments are rewritten, because the new job only
  reads: "the CLI that publishes a release" (`release.yml:174-178`) and "opm's push path reads the
  docker credential chain" (`:196-197`). Only the verify step's `run:` and `env:` stay
  byte-identical. Wiring §4.5 says "the unchanged verify step". The
  no-inline-expressions rule of wiring §2.2 governs the `.github` reusable workflows, and neither
  value is attacker-controlled here. Hardening the login is a separate, repo-wide `ci` change.
- **No CUE and no Task in the job.** The verify step runs only `grep`, `sed` and `opm`.
  `OPM_REGISTRY` comes from the workflow-level `env` (`:19`).
- **`publish-cue` keeps the fixture gate before the publish.** If the gate fails, nothing was
  published, `published` is unset, and verify, docs and notify all skip, which is correct.

### D2. `publish-docs` keeps `always()`; only the comments change

After the split, "Publish CUE catalog" is the last step of `publish-cue`. `always()` still
matters in one case: a post-job step, such as checkout's cleanup, can fail `publish-cue` after
`published=true` is set. Without `always()`, that failure would skip `publish-docs` for a module
that is on GHCR. Wiring §4.5 also says to keep `publish-docs` unchanged, so the `if:` stays.

Two comments become false and are rewritten:

- the `publish-cue` comment (`:160-161`), which describes a later non-gating step;
- the `publish-docs` comment sentence (`:251-255`) that explains `always()` by the verification
  step.

The new text says that `always()` keeps a failing post-job step of `publish-cue` from skipping
the docs once the module is on GHCR.

### D3. `notify-downstream` follows wiring §4.3 and §4.5 exactly

```yaml
  # The release cascade (workspace RELEASING.md, "Notify after publish"): tell library,
  # opm-operator and cli that opm-vX.Y.Z is on GHCR. It waits only for the push
  # (published), never for verify-published or publish-docs. The reusable workflow
  # declares the cascade Environment and mints the App token itself; a job that calls
  # a reusable workflow cannot set environment. CASCADE_NOTIFY=off stops it.
  notify-downstream:
    name: Notify downstream
    needs: [release-please, publish-cue]
    if: ${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}
    permissions:
      contents: read
    uses: open-platform-model/.github/.github/workflows/cascade-notify.yml@main
    with:
      tag: ${{ needs.release-please.outputs.opm_tag_name }}
```

- **The tag** is `opm-vX.Y.Z`. That is the catalog shape of wiring §3.3, and the receivers strip
  `opm-` for `CASCADE_EXPECT` (wiring §3.4). The source is never passed: the reusable workflow
  derives it from `GITHUB_REPOSITORY` (wiring §3.1). The targets come from its fixed map: library,
  opm-operator and cli (`RELEASING.md:172`).
- **`!cancelled()` and `published`** mirror `publish-docs`. A cancelled run never notifies. When
  `publish-cue` fails before the push, `published` is unset and notify skips. That is correct,
  because nothing was published.
- **Permissions.** `contents: read` replaces the workflow-level write grants for this job. The
  reusable job declares `contents: read` itself and does its work with the App token
  (wiring §2.3).
- **No `secrets:`.** The App key is an Environment secret, read only inside the reusable job's
  `environment: cascade` (wiring §2.2). E1 in A's sandbox cycle proves that GitHub resolves it in
  the caller repo.
- **No `org-github-ref`.** Production always runs `.github` `main` (wiring §2.4).
- **Recovery.** A red `Notify downstream` job is re-run with "Re-run failed jobs" on the Release
  run. Otherwise the three receivers' daily sweeps pick the release up within a day
  (`RELEASING.md:201`).

### D4. `deps-cascade.yml` is wiring §5 with catalog_opm's values

The file is the wiring §5 YAML with these values:

- `cron: '17 5 * * *'`: tier 1, off the hour, staggered before opm-operator (`47 5`) and cli
  (`17 6`);
- `setup-go: false`, because `cascade.sh` needs only cue, Task, git and yq;
- `labels-managed: false`, because this repo has no `labels.yml`, so `publish` creates the five
  bot labels with `--force` (wiring §6.4 step 4).

`setup-cue` stays at its default `true`. `cue-version: v0.17.1` is passed explicitly, although
it equals the `.github` default (wiring §6.1). This repo pins its CUE in five other workflow
places (`ci.yml:38`, `cascade-task.yml:48`, `release.yml:66`, `release.yml:211`,
`branch-publish.yml:24`). If the
receiver took `.github`'s default, a CUE bump here would leave the receiver and G2 running
`cue mod get` and `cue mod tidy` on the old CUE, and no grep for the old version in this repo
would find it. (`cascade.sh:219` only refuses a change to `language.version`; it does not compare
it with the CUE that runs.) The file carries:

- `permissions: {}` at the top;
- on the job, `contents: read`, `pull-requests: read` and `statuses: write`, which together cover
  the three reusable jobs (wiring §6.1);
- no `secrets:`.

The receiver accepts payload sources core and cli (wiring §3.2). cli is the release-tool edge, for
`.opm-cli-version`. core moves `src/cue.mod/module.cue`.

**Dry run fails closed.** `dry-run` is true unless `CASCADE_DRY_RUN` is exactly `false`, so an
unset variable never pushes. The supervisor still sets `true` before merge, to make the state
visible (wiring §1, §9.1).

### D5. `cascade-gates.yml` is wiring §8.3 verbatim

The workflow runs on `pull_request_target` (`opened`, `reopened`, `synchronize`) and has
`permissions: {}`. The job grants `statuses: write` and `actions: write` and calls
`cascade-gates.yml@main` with the two mode variables.

- **`pull_request_target` is safe here.** The reusable job checks out nothing and runs no PR code
  (wiring §8.3). The only write it holds is to post a status and dispatch `deps-cascade.yml` on
  `main`.
- **Coverage of catalog release PRs.** catalog_opm's release PR head moves by App-token pushes:
  release-please and the identity advance (`release.yml:118-137`), both pushed with the release
  App token (`:45-50`). Those fire `synchronize`, so the statuses follow the head. That closes the
  "missing until the next dispatch" gap in `RELEASING.md:341-345`, which the wiring §14
  amendment rewrites.
- **G3 here watches only core** (wiring §3.5). The cli → catalog_opm edge is release-tool only
  and never counts.

### D6. No spec delta: the verify split is a decision and a proposal item

Wiring §10 says each B has "an OpenSpec change with a spec delta, as the repo's workspace
requires", with the verify split as its own requirement. catalog_opm's workspace has no specs by
design (`openspec/config.yaml` Principle II, the `catalog-change` schema). Every change carries
`skip_specs: true`, and a `specs/` directory is forbidden. The clause "as the repo's workspace
requires" therefore gives no delta here. The verify split is D1 and its own `tasks.md` section,
and its durable rule lands in `AGENTS.md`.

## Research & Decisions

### Where notify hooks in

**Context**: notify must run only after the artifact is public (`RELEASING.md:164-168`) and must
not be suppressed by a non-gating check.
**Explored**: `release.yml` on `main` (read in the worktree, fce215a); the Phase 3 wiring research
(r-wiring §1, "catalog_opm split"); wiring §4.5.
**Decision**: hook on `publish-cue.outputs.published` after the split (D1, D3), not on
`publish-cue` success alone, and not on `verify-published` or `publish-docs`.
**Rationale**: `published` is set right after the push, so it is the most direct proof that the
module is on GHCR. `publish-docs` already keys on it.

### What actionlint can and cannot check here

**Context**: wiring §10 asks each B to run actionlint on the new files.
**Explored**: actionlint v1.7.12 (scratchpad binary) on today's workflows exits 0. It validates a
local reusable workflow's inputs, but it does not fetch a remote `owner/repo/...@ref` call.
**Decision**: run actionlint on every section. Sections 2 and 3 also compare each `with:` key
against wiring §4.1, §6.1 and §8.3 and against the `workflow_call` inputs of A's branch copies
(tasks 2.3, 3.4), and record the result below under "Caller inputs checked". `.github` `main`
holds none of the three files until A merges, so the check against `main` is the supervisor's
pre-merge step (proposal, "Depends on / gates").
**Rationale**: a misspelled input on a remote call fails only at run time, which here means a
release.

### Caller inputs checked

Checked against the wiring contract and the reusable workflows on A's branch
`feat/add-release-cascade-workflows` at `04bc25d` (worktree copies; the branch is not on
`origin` yet). The check copies the callers and A's three files into a scratch tree, points
each `uses:` at the local copy and runs actionlint v1.7.12, which then validates input names,
required inputs and types. A planted unknown key `tagg` fails it, so the check bites.

- `notify-downstream` → `cascade-notify.yml` (wiring §4.1): inputs `tag` (string, required)
  and `org-github-ref` (string, default `main`). The caller passes `tag` only. The reusable job
  declares `contents: read`, which the caller grants. No `secrets:` on either side.
- `cascade` job → `cascade-receive.yml` (wiring §6.1): the caller passes `dry-run` (boolean,
  the only required input), `gates-only`, `setup-go` and `labels-managed` (boolean), and
  `g2-mode`, `g3-mode` and `cue-version` (string), all declared with those types. The called
  jobs declare `contents: read` + `pull-requests: read` (`compute`, `publish`) and
  `contents: read` + `statuses: write` + `pull-requests: read` (`gates`); the caller grants
  `contents: read`, `pull-requests: read` and `statuses: write`, which covers all three.
  `publish` does its writes with the App token, not `GITHUB_TOKEN`.
- `gates` job → `cascade-gates.yml` (wiring §8.3): the caller passes `g2-mode` and `g3-mode`
  (string), both declared. The called job declares `statuses: write` and `actions: write`,
  exactly what the caller grants.
- Apart from comments, both new files equal the wiring §5 (with the §5.1 values) and §8.3 YAML;
  the only added line is `cue-version: v0.17.1` (D4).

### Contract choices that apply to catalog_opm

**Context**: wiring version 2 binds all five joins.
**Explored**: wiring §1, §3, §4.5, §5.1, §8.3, §9, §10.
**Decision**:

- apply §4.5 catalog_opm (the split, then notify on `published`);
- apply §5 with the §5.1 row `17 5 * * *`, `false`, `false`;
- apply §8.3 unchanged;
- the PR title is `ci: join the release cascade`;
- never add `!` to a cascade title (`AGENTS.md:273`, wiring §7.3), which the shared receiver
  enforces.

**Rationale**: uniform callers, with all logic in one reviewed place (`.github`).

## Risks / Trade-offs

- [This PR merges before `.github` `add-release-cascade-workflows`] → GitHub cannot resolve
  `cascade-notify.yml@main`, and the whole Release run fails at load time. That is GitHub's
  documented behaviour for an invalid reusable-workflow reference, and for a `with:` key the
  called workflow does not declare, so no spike tests it. No release PR update,
  no tag, no publish. Mitigation: "Depends on" in the proposal; tasks 2.3 and 3.4 check every `with:` key
  against the contract and A's branch; before this PR merges, the supervisor diffs them against
  `.github` `main` (proposal, "Depends on / gates"). The supervisor merges A first (wiring §1).
- [E1 fails in A's sandbox cycle: an Environment secret is invisible to a reusable-workflow job]
  → wiring §13.1 replaces notify and publish with composite actions. That changes this repo's
  callers: a local `environment: cascade` job for notify, and a local `publish` job in
  `deps-cascade.yml`. Mitigation: sections 2 and 3 are re-planned with `opsx:update` before they
  are implemented. Section 1 does not depend on E1 and needs no re-plan; it still ships in this change's one PR.
- [A verify finding is now easier to miss, because the release run's headline job is green] → the
  job is named `Verify the published build` and the run is still red overall. It was never a gate
  (0011:D7).
- [Shared App key reach (wiring Facts, §11.5)] → whoever can run a job in catalog_opm's `cascade`
  Environment can mint a token for all seven repos. Mitigation: the Environment is `main` only, and
  `main` is ruleset-protected. This change adds no job that declares the Environment itself.
- [`pull_request_target` on a public repo] → no checkout and no PR code (D5), and the token holds
  only `statuses: write` and `actions: write`.
- [Workflows guard (wiring §7.6)] → merging this change edits `.github/workflows/` on `main`.
  While the receiver is in dry run no `deps/cascade` branch exists, so nothing is recreated. Under
  `WF_GUARD_RULE=strict`, later workflow edits on `main` recreate a bot-only cascade PR. That is
  accepted in A.
- [The G2 evaluator runs `task -x deps:cascade` from the release head inside `compute`] →
  accepted in wiring §8.2. `compute` holds no secret and only read permissions.

## Durable decisions

- **`verify-published` is an aid in its own job. Notify and docs publishing key on
  `publish-cue`'s `published` output, never on verification.** Lands in `AGENTS.md`
  § Release & publishing, replacing the post-publish sentence at `:229` (task 1.3).
- **The cascade wiring catalog_opm owns**: `notify-downstream` and what it dispatches;
  `deps-cascade.yml` and its sources (core, cli); `cascade-gates.yml`; the repo variables
  `CASCADE_DRY_RUN` (live only at exactly `false`), `CASCADE_NOTIFY=off`, `CASCADE_G2_MODE` and
  `CASCADE_G3_MODE`; recovery of a failed notify. Lands in `AGENTS.md` § Release & publishing
  (tasks 2.2, 3.3).
- **A CUE bump moves every pinned CUE literal under `.github/workflows/`, including
  `cue-version:` in `deps-cascade.yml`.** Lands in `AGENTS.md` § Release & publishing (task 3.3).
- **Phase 4 and Phase 5 steps** (setting `CASCADE_DRY_RUN=false`, making G2 and G3 required) stay
  with the change and `RELEASING.md`. They are rollout steps, not authoring rules.
