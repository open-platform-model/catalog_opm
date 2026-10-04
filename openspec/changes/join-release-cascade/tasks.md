## 1. `.github/workflows/release.yml`: split `verify-published` out of `publish-cue`

- [x] 1.1 Remove the step "Verify the published build" and its comment from `publish-cue`, which then ends at "Publish CUE catalog". Keep the fixture gate on the tag before the publish. Rewrite the `publish-cue` outputs comment so it no longer names a later verification step (design D1, D2)
- [x] 1.2 Add the job `verify-published` as design D1 shows. Name `Verify the published build`, `needs: [release-please, publish-cue]`, `if: needs.publish-cue.outputs.published == 'true'`, `permissions: {contents: read, packages: read}`. Steps: checkout of `opm_tag_name` with the file's existing pin `de0fac2e…` v6.0.2, then "Read the pinned opm CLI version", "Install opm", "Login to GHCR" and the verify step, copied with its comment. Rewrite the two comments that would turn false in a read-only job: "the CLI that publishes a release" and "opm's push path reads the docker credential chain" (design D1). In the `publish-docs` comment, say that `always()` keeps a failing post-job step of `publish-cue` from skipping the docs, and leave its `if:` unchanged (design D2)
- [x] 1.3 `AGENTS.md` § Release & publishing: replace "A post-publish `opm catalog registry check --compat` verifies the pushed build (an aid, not a gate)" with the `verify-published` rule: an aid in its own job, run only when `published` is true, and never a `needs` of `publish-docs` or of the notify job (design, Durable decisions)
- [x] 1.4 Run the scratchpad `actionlint` (v1.7.12) on `.github/workflows/*.yml`; it must exit 0. `git diff` must show the verify step's `run:` and `env:` byte-identical to `main`'s
- [x] 1.5 `openspec validate join-release-cascade --strict` and `task check` green, then commit `ci(release): verify the published build in its own job`
- [x] 1.6 Apply the implementation review nits to `verify-published` (review findings 7, 8, 9, 11): one blank line before its comment, the `publish-docs` comment reflowed, `0011:D7` in the verify comment, and `timeout-minutes: 15` on the job. Its `if:` stays the contract's (wiring §4.5); the gap it leaves is stated in design D2 (review finding 4). actionlint exits 0, the verify step's `run:` and `env:` still equal `main`'s, then commit `ci(release): tidy the verify-published job`

## 2. `.github/workflows/release.yml`: the caller-owned notify job

- [x] 2.1 Replace the version 2 `notify-downstream` job (a call of the reusable `cascade-notify.yml@main`) with the catalog_opm block of wiring §4.6, byte for byte except the pin: `runs-on: ubuntu-latest`, `environment: cascade`, `timeout-minutes: 20`, `permissions: {contents: read}`, and one step that runs `open-platform-model/.github/.github/actions/cascade-notify@2376ffae4bfc665f327d51581350dea694c01504 # .github main` with `tag`, `client-id: ${{ vars.CASCADE_APP_CLIENT_ID }}` and `private-key: ${{ secrets.CASCADE_APP_PRIVATE_KEY }}`. `needs` and `if:` are unchanged. It stays the last job. Rewrite its comment to the caller-owned job (wiring §10.1 items 1 and 9; design D3)
- [x] 2.2 Check the `with:` keys against `inputs` of `.github/actions/cascade-notify/action.yml` at `2376ffa`: `tag`, `client-id` and `private-key`, all required, no other. Record it in design.md "Caller inputs checked"
- [x] 2.3 actionlint v1.7.12 exits 0 on `.github/workflows/*.yml`
- [x] 2.4 `openspec validate join-release-cascade --strict` and `task check` green, then commit `ci(release): notify downstream from a caller-owned cascade job`

## 3. `.github/workflows/deps-cascade.yml` and `cascade-gates.yml`

- [ ] 3.1 Make `deps-cascade.yml` the wiring §5 block with the catalog_opm `jobs:` map of §5.2 (wiring §10.1 item 4): pin `cascade-receive.yml` to the SHA with ` # .github main`; drop `labels-managed` from the `cascade` job's `with:` (the input no longer exists there); keep `setup-go: false` and `cue-version: v0.17.1`; add the whole caller-owned `publish` job with the §5 `if:`, `runs-on: ubuntu-latest`, `environment: cascade`, `timeout-minutes: 15`, `permissions: {contents: read, pull-requests: read}`, and one step running `cascade-publish` at the SHA with `dry-run` (the §5 expression, byte for byte), `labels-managed: false`, `client-id` and `private-key`. Rewrite the header comment: no text may say the reusable workflow publishes, mints a token or declares the Environment (design D4)
- [ ] 3.2 In `cascade-gates.yml` change only the `uses:` line to `cascade-gates.yml@<SHA> # .github main` (wiring §10.1 item 5), and rewrite the header comment so it says what `actions: write` allows: the token holds `statuses: write` and `actions: write`, and the job uses them only to post statuses and dispatch `deps-cascade.yml` on `main` (review finding 3; design D5)
- [ ] 3.3 Check both callers against `.github` at `2376ffa`: the `cascade` job's `with:` keys and types against `cascade-receive.yml`'s `workflow_call` inputs, the `publish` step's keys against `cascade-publish/action.yml`'s inputs, the gates caller against `cascade-gates.yml`, and each caller's job permissions against the called jobs'. Record it in design.md "Caller inputs checked"
- [ ] 3.4 actionlint v1.7.12 exits 0 on `.github/workflows/*.yml`
- [ ] 3.5 `openspec validate join-release-cascade --strict` and `task check` green, then commit `ci(cascade): run publish in a caller-owned job and pin the receiver`

## 4. `.github/workflows/cascade-task.yml`: pin the resolver checkout

- [ ] 4.1 In the step that checks out `repository: open-platform-model/.github`, change only `ref: main` to `ref: 2376ffae4bfc665f327d51581350dea694c01504 # .github main`; the `actions/checkout` pin `de0fac2e…` v6.0.2 stays. Rewrite the header comment so the resolver comes from the pinned `.github` commit, not `main`. `CASCADE_RESOLVER_REAL` is already set unconditionally, so there is no fallback to delete (wiring §10.1 item 3; design D7)
- [ ] 4.2 actionlint exits 0, `task check` green, then commit `ci(cascade): pin the cascade task's resolver checkout`

## 5. The wiring check, run in CI on every PR

- [ ] 5.1 Add `.tasks/cascade/wiring-check.sh` with the wiring §10.1 item 6 script, `RECEIVER=true` and `PIN_COMMENT='.github main'`, plus the supervisor addendum: `release.yml`'s top-level `env` keys are an allow-list (`OPM_REGISTRY`, `CUE_REGISTRY`), and every key-holding job (`notify-downstream`, `publish`) has `runs-on: ubuntu-latest` (design D8)
- [ ] 5.2 Add the task `cascade:wiring:check` to `Taskfile.yml` next to `docs:pins:check`, and `- task: cascade:wiring:check` to the aggregate `check` task's `cmds`
- [ ] 5.3 Add the step `Verify the cascade wiring` (`run: task cascade:wiring:check`) to `ci.yml` job `ci` ("Validate catalog", the required check), directly after "Install Task"
- [ ] 5.4 shellcheck v0.11.0 on the script is clean. The check passes on the branch and prints `cascade wiring: ok, .github 2376ffae4bfc665f327d51581350dea694c01504 (.github main)`. Mutations of the real workflows are each refused: the contract's 24 plus the addendum's (an extra `release.yml` env key, `runs-on` changed on either key-holding job). Record the run in design.md "Wiring check run"
- [ ] 5.5 actionlint exits 0, `task check` green, then commit `ci(cascade): check the cascade wiring on every pull request`

## 6. Docs and the re-grep

- [ ] 6.1 `AGENTS.md` § Release & publishing: the notify bullet describes the caller-owned `cascade` job and the pinned `cascade-notify` action; the receive bullet the reusable `cascade-receive.yml` (compute and gates, no secret) plus the caller-owned `publish` job; one `.github` `main` SHA on every cascade reference, the `cascade-task.yml` resolver `ref:` included, moved only by a `ci(deps): pin the cascade to .github <sha7>` PR; `task cascade:wiring:check` in `Validate catalog`; the gates-only run executes the release head's task read-only (review finding 2); the full enforce-mode statuses (review finding 6); a bad pin, not a missing workflow, as the failure mode (wiring §10.1 items 8 to 10)
- [ ] 6.2 Run the wiring §10.1 item 11 re-grep. Every hit is fixed or allowed; record the remaining hits in design.md "Re-grep"
- [ ] 6.3 `openspec validate join-release-cascade --strict` and `task check` green, then commit `docs(agents): describe the pinned cascade wiring`

## 7. Verify and archive

- [ ] 7.1 Run `openspec verify` for `join-release-cascade` (the `opsx:verify` skill). Confirm that every Durable decision in design.md has landed in `AGENTS.md`
- [ ] 7.2 Archive the change on this branch with `--skip-specs`, so the archive rides the implementing PR. Never push to main (owner decision 4; `RELEASING.md` "Owner settings")
- [ ] 7.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive join-release-cascade`
