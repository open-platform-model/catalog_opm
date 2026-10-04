## Why

Wave 2 of the release cascade security pass (2026-10-04, owner decisions 28 to 31). `.github`
PR 12 (`bound-cascade-publish`, squash `7b9ad1bea132f7a3f053a5db61ac3933b59ee226` on `.github`
`main`) bounded what the cascade's `publish` may push, added the release App key rule to the
wiring check, made `cascade-publish` require a `gates-only` input, and replaced every repo's own
wiring check with one canonical script each repo copies byte for byte. Nothing of that reaches
catalog_opm until this repo moves its cascade pin: today all five `.github` references carry
`2376ffa`, and `.tasks/cascade/wiring-check.sh` is the repo's own 140-line check, which knows
neither the release-key rule nor the `publish-workflows` cache rule nor the `compare` check that
refuses a SHA that exists only in a fork of `.github`.

Moving the pin without the caller edits would break the receiver: `cascade-publish` at the new
SHA fails before the mint when its required `gates-only` input is missing.

## What Changes

- **The pin**: every `open-platform-model/.github` reference (the `cascade-notify` step in
  `release.yml`, the `cascade-receive.yml` call and the `cascade-publish` step in
  `deps-cascade.yml`, the `cascade-gates.yml` call, the resolver `ref:` in `cascade-task.yml`)
  moves to `7b9ad1bea132f7a3f053a5db61ac3933b59ee226 # .github main`.
- **`deps-cascade.yml` `publish`**: the job `if:` gains `&& inputs.gates_only != true` and the
  `Publish` step passes `gates-only: ${{ inputs.gates_only == true }}`, the shapes the `.github`
  README documents at that SHA. `cue-version: v0.17.1` stays (it has a sha256 row in
  `wiring/install-tools.sh` there).
- **The wiring check**: `.tasks/cascade/wiring-check.sh` becomes a byte-identical copy of `.github`
  `.github/scripts/cascade/wiring-check.sh` at the pin; the repo's values move to a new
  `.tasks/cascade/wiring-check.yaml` (the README's catalog_opm row, notify `needs`/`if:`/`tag`
  re-derived from `release.yml`).
- **CI**: the `Validate catalog` step "Verify the cascade wiring" runs
  `bash .tasks/cascade/wiring-check.sh --pin-on-main` with `GH_TOKEN: ${{ github.token }}`, so CI
  also proves the SHA is on `.github` `main`. `task cascade:wiring:check` stays the offline entry
  (and part of `task check`).
- **`AGENTS.md`**: the Cascade pin and command-table entries describe the canonical copy, its
  config, the `--pin-on-main` CI step and the gates-only switch.

`.github/dependabot.yml` already carries `cooldown: {default-days: 7}` on the `github-actions`
entry; no change there.

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is workflow YAML.

**Before**

```yaml
# deps-cascade.yml publish
if: >- ... && inputs.dry_run != true && vars.CASCADE_DRY_RUN == 'false' && ...
steps:
  - uses: open-platform-model/.github/.github/actions/cascade-publish@2376ffa... # .github main
    with: {dry-run: ..., labels-managed: false, client-id: ..., private-key: ...}
# ci.yml
- name: Verify the cascade wiring
  run: task cascade:wiring:check
```

**After**

```yaml
# deps-cascade.yml publish
if: >- ... && inputs.dry_run != true && inputs.gates_only != true && vars.CASCADE_DRY_RUN == 'false' && ...
steps:
  - uses: open-platform-model/.github/.github/actions/cascade-publish@7b9ad1b... # .github main
    with: {dry-run: ..., gates-only: ${{ inputs.gates_only == true }}, labels-managed: false, client-id: ..., private-key: ...}
# ci.yml
- name: Verify the cascade wiring
  env:
    GH_TOKEN: ${{ github.token }}
  run: bash .tasks/cascade/wiring-check.sh --pin-on-main
```

## Impact

- **Published catalog: none.** No file under `src/` changes and no member moves to a new
  `apiVersion` segment. Every commit is `ci`, `docs` or `chore`, all hidden, so `opm` does not
  advance. PR title: `ci(deps): pin the cascade to .github 7b9ad1b`.
- **modules fleet, subscribing platforms, cli fixtures:** nothing to do.
- **The receiver** stays dry (`CASCADE_DRY_RUN` is not `false`), so the first run on the new pin
  computes and summarizes only; the supervisor's Phase 4 canary decides when a receiver goes live.
- **Required CI** now calls the GitHub API once (`compare`) with the job's read-only token.

## Enhancement

None. The source is the supervisor's security-pass plan (wave 2) and owner decisions 28 to 31; no
enhancement backs it, so there is no `enhancement.yaml`.
