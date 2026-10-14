# Release cascade wiring

Covers this repo's part of the release cascade: the notify job, the receive and publish jobs, the stop switches, the App key rules, the `.github` cascade pin and its wiring check, and the `.opm-cli-version` pin with the writers that move it. The release flow itself is in a separate file. The cascade design is in the workspace `RELEASING.md`.

## Notify downstream

- `notify-downstream` in `release.yml` is this repo's own job. It declares `environment: cascade` (`main` only). Its one step runs the pinned `cascade-notify` action with the `opm-vX.Y.Z` tag, `client-id: ${{ vars.CASCADE_APP_CLIENT_ID }}` and `private-key: ${{ secrets.CASCADE_APP_PRIVATE_KEY }}`. The action mints the `opm-cascade` App token and sends one `upstream-released` dispatch each to library, opm-operator and cli.
- There is no reusable notify workflow: a reusable-workflow job does not see the caller's Environment secrets without `secrets: inherit`.
- It waits only for the push: `needs: [release-please, publish-cue]`, run when `publish-cue`'s `published` is `true` and the run was not cancelled. It never waits for `verify-published` or `publish-docs`.
- Stop switch: the repo variable `CASCADE_NOTIFY=off` skips it. Recovery: re-run a red `Notify downstream` with "Re-run failed jobs" on the Release run. Otherwise each receiver's daily sweep picks the release up within a day. A job that fails at startup has a bad pin: fix it with a pin PR.

## Receive and gate

- `deps-cascade.yml` has two jobs. `cascade` calls the pinned reusable `cascade-receive.yml`: its `compute` job runs `task -x deps:cascade` and plans the one rolling `deps/cascade` PR, and its `gates` job posts G2 and G3. Neither holds a secret. `publish` is this repo's own job: it declares `environment: cascade` and runs the pinned `cascade-publish` action, which verifies the plan, mints the App token and pushes.
- The receiver runs on a `repository_dispatch` of type `upstream-released`, on the daily sweep at `17 5 * * *` UTC, and on `workflow_dispatch` (`dry_run`, `gates_only`). It accepts payloads from core and cli only; cli is the release-tool edge for `.opm-cli-version`.
- It is live only when the repo variable `CASCADE_DRY_RUN` is exactly `false`. Unset, `true` or any other value is a dry run that writes the diff to the job summary and pushes nothing. So is a manual run with `dry_run` and any run from a ref other than `main`. Three places enforce it: the `dry-run` input of the `cascade` call, the `publish` `if:`, and `cascade-publish`'s required `dry-run` input, which refuses to mint unless it is exactly `false`. Go live by setting `false`, never by deleting the variable.
- A gates-only run never publishes: the `publish` `if:` carries `inputs.gates_only != true`, and the action's required `gates-only` input (`${{ inputs.gates_only == true }}`) refuses to mint unless it is exactly `false`.
- `cascade-gates.yml` runs on `pull_request_target` and posts `cascade/freshness` (G2) and `cascade/settled` (G3) on every PR, `n/a` on a PR that is not a release PR. On the release PR it dispatches a gates-only `Deps cascade` run that evaluates and posts them. Both are `warn` by default through the repo variables `CASCADE_G2_MODE` and `CASCADE_G3_MODE`: a clean result is `success`; `warn` posts `success` with a `WARN:` description on a problem; `enforce` posts `failure` on a problem, `pending` while evaluating and `error` when evaluation fails. They are not required checks. G3 here watches core only.
- The per-PR gates job checks out nothing from the PR, so no PR code runs there. Its token holds `statuses: write` and `actions: write`, used only to post statuses and dispatch `deps-cascade.yml` on `main`. The gates-only run it dispatches does run the release head's `task -x deps:cascade`, read-only and without secrets (wiring contract 8.2).
- Stop switches, smallest first: the `deps-cascade:hold` label on the cascade PR, a `.cascade-hold` entry, `CASCADE_DRY_RUN` set to anything but `false`, `CASCADE_NOTIFY=off`, and disabling `deps-cascade.yml`.
- A CUE bump also sets `cue-version:` in `deps-cascade.yml`, together with every other CUE version literal under `.github/workflows/`: the receiver and G2 run `cue mod get` and `cue mod tidy` on that CUE.

## The App key

- `secrets.CASCADE_APP_PRIVATE_KEY` is read only in the caller-owned `notify-downstream` or `publish` job. That job declares `environment: cascade` and passes the key only as the `private-key` input of the SHA-pinned cascade action. It has no checkout or `run:` of its own and no `env:`, `container:` or `services:` (the publish action checks out the repo but never runs it). No reusable call passes `secrets:` or `secrets: inherit`.
- Both jobs run on `ubuntu-latest`. Notify waits for `publish-cue` only, and its `tag` is the release tag. `release.yml`'s workflow-level `env` holds only `OPM_REGISTRY` and `CUE_REGISTRY`, because it reaches the notify action's steps.
- Never add a step, an `env:` or another `environment: cascade` job. `task cascade:wiring:check` refuses it.

## The cascade pin

- Every reference to the cascade code carries one full SHA of a `.github` `main` commit and the comment `# .github main`. There are six in this repo: the `cascade-notify` step in `release.yml`, the `cascade-receive.yml` call and the `cascade-publish` step in `deps-cascade.yml`, the `cascade-gates.yml` call, the `cite-lint.yml` call in `ci.yml`, and the `ref:` of the `open-platform-model/.github` checkout in `cascade-task.yml`, so CI tests the resolver the receiver runs. Owner decision 24 pins the actions; the workflows and the resolver follow, so the references never mix commits.
- A merge to `.github` `main` changes nothing here until a PR titled `ci(deps): pin the cascade to .github <first 7 of the SHA>` replaces the SHA in all six (`grep -rn -A1 'open-platform-model/.github' .github/workflows`) and nothing else. Then compare `CITE_LINT_REF` in `Taskfile.yml` with the `enh-ref` default of `cite-lint.yml` at the new SHA, and move it when they differ. Move the pin only after `gh api repos/open-platform-model/.github/compare/<SHA>...main --jq .status` prints `identical` or `ahead`. Never pin a branch, a tag or a commit that is not on `.github` `main`. Dependabot ignores `open-platform-model/.github*`, so nothing else moves the references.
- The pin PR also replaces `.tasks/cascade/wiring-check.sh` with `.github`'s `.github/scripts/cascade/wiring-check.sh` at the new SHA: `gh api "repos/open-platform-model/.github/contents/.github/scripts/cascade/wiring-check.sh?ref=<SHA>" -H 'Accept: application/vnd.github.raw'`. A reviewer pipes the same call to `cmp - .tasks/cascade/wiring-check.sh`. Edit the caller shapes and `.tasks/cascade/wiring-check.yaml` only when that `.github` change altered an input or a caller shape. Never edit the copy here: a change to the check is made in `.github`.
- The required `Validate catalog` job runs the check as "Verify the cascade wiring" (`GH_TOKEN: ${{ github.token }}`, `bash .tasks/cascade/wiring-check.sh --pin-on-main`). That also runs the `compare` check above and compares the copy byte for byte with the file at the pin. Only SHA-pinned actions may come before it, so the `.opm-cli-version` read and every other `run:` step go after it. `task cascade:wiring:check` runs it offline inside `task check` (needs mikefarah yq v4).
- The check holds: the exact shape of the two jobs that hold the cascade App key and their `needs`, `if:`, timeout and inputs; the `deps-cascade.yml` and `cascade-gates.yml` callers; `release.yml`'s env allow-list; `environment: release` on exactly the jobs that read `RELEASE_APP_PRIVATE_KEY`; and one `.github` `main` SHA with `# .github main` on all references. For the CI job that runs it: the workflow and job `env` come from the env-allow names only, only SHA-pinned actions from another repo come before the step (no `run:` step), and every `.github` checkout is `actions/checkout` at a full SHA with exactly `repository`, `ref`, `path` and `persist-credentials: false`. It guards against mistakes; review and the `main` ruleset guard against a deliberate edit.

## `.opm-cli-version` and the pin writers

- The repo-root `.opm-cli-version` (one line, the CLI tag) pins the opm CLI that CI and the release workflow install. Every job that installs the CLI reads the file into `$GITHUB_ENV` right after its checkout, or, in `Validate catalog`, right after the cascade wiring step. `publish-cue` reads it from the released tag. A bump is a `ci(deps)` commit. Keeping the pin out of workflow files lets the cascade bot bump it without the GitHub Workflows permission.
- Two writers move `.opm-cli-version` and the core pin, until the workspace's Phase 5 rewire. One is this repo's `task -x deps:cascade` (`.tasks/cascade/cascade.sh`), which the cascade runs. The other is the workspace root `task deps:pins:opm-cli` and `task deps:update`. The root tasks never read `.cascade-hold` or `.cascade-frozen`, and root `deps:update` also moves `cue.dev/x/k8s.io@v0` (which then needs `KUBERNETES_VERSION` and `task generate:kinds`), swallowing its errors. Running them bypasses holds and frozen entries.
- `deps:cascade` never names `cue.dev/x/k8s.io@v0` (a `tidy` that raises it is a warning in the PR body, never a revert). It never touches `src/identity/identity.cue`, `src/RELEASE`, the release-please files, `CHANGELOG.md`, `.opm-docs-version`, `language.version`, `.cascade-hold`, `.cascade-frozen` or anything under `.github/`. Its PR title is `fix(deps)` when `src/` moved, else `ci(deps)`,.
- Run it as `task -x deps:cascade`. It exits 0 when it changed the tree, 3 when there was nothing to do, anything else is an error. Plain `task` turns every failing exit, 3 included, into 201. It refuses a dirty tree unless `CASCADE_ALLOW_DIRTY=1`. The related tasks `deps:cascade:title` and `deps:cascade:body` need the resolver: the `.github` checkout beside this repo, or an absolute `CASCADE_RESOLVER`.
- `deps:cascade:test` runs in sandbox copies against `.tasks/cascade/testdata/stub-resolve.sh`, the contract stub copied byte for byte and never edited in place. `CASCADE_TEST_SET=offline` runs the offline scenarios (the required `Validate catalog` job). `all` also resolves core from GHCR for S2 and S4, and runs S5 title and body when `CASCADE_RESOLVER_REAL` is set (the non-required `cascade-task.yml`).

## Pitfalls

- A pin PR that edits anything besides the six SHAs (and `CITE_LINT_REF`, the copy and the data file when the rules above call for it).
- Editing `.tasks/cascade/wiring-check.sh` here: the next pin PR overwrites it, and CI compares it byte for byte.
- Running `task deps:cascade` without `-x`: exit 3 becomes 201.
- Putting a `run:` step before the wiring step in `Validate catalog`.
- Adding `secrets: inherit`, an `env:` or a second job with `environment: cascade`.
- Deleting `CASCADE_DRY_RUN` to go live: set it to `false`.

## Check before you finish

- [ ] `task cascade:wiring:check` passes.
- [ ] All six `.github` references carry the same SHA and `# .github main`.
- [ ] A CUE bump also changed `cue-version:` in `deps-cascade.yml` and every other CUE version literal.
