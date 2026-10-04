## Why

`.github` `main` moved to `6938f8e0247e019cb0c2db13fff5b7b558a6b67d` with `.github` PR 14 (a
background `git gc` no longer fails the resolver) and PR 15 (`verify-wiring-copy`). PR 15 makes
`wiring-check.sh --pin-on-main` compare the running copy byte for byte with the canonical file at
the pin, restricts the CI workflow's and job's `env`, refuses any step before the wiring step that
is not an action from another repo at a full SHA, and holds every `.github` checkout to the pin.
None of that reaches catalog_opm until this repo moves its pin, and the new check refuses this
repo's `ci.yml` as it stands: the `Read the pinned opm CLI version` `run:` step writes
`OPM_CLI_VERSION` to `GITHUB_ENV` before the wiring step.

## What Changes

- **The pin**: the five `open-platform-model/.github` references (the `cascade-notify` step in
  `release.yml`, the `cascade-receive.yml` call and the `cascade-publish` step in
  `deps-cascade.yml`, the `cascade-gates.yml` call, the resolver `ref:` in `cascade-task.yml`)
  move from `7b9ad1b` to `6938f8e0247e019cb0c2db13fff5b7b558a6b67d # .github main`.
- **The wiring check**: `.tasks/cascade/wiring-check.sh` becomes the byte-identical file at the new
  pin. `.tasks/cascade/wiring-check.yaml` is unchanged: neither `.github` PR altered an input, a
  caller shape or a config key catalog_opm uses.
- **CI**: in `ci.yml` job `ci`, "Verify the cascade wiring" moves above `Read the pinned opm CLI
  version`, so only SHA-pinned actions (checkout, `setup-cue`, `setup-task`) run before it.
  `OPM_CLI_VERSION` is first read by `Install opm`, which stays after it.
- **`AGENTS.md`**: the Cascade pin entry says the CI step compares the copy and that only
  SHA-pinned actions may precede it.

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is workflow YAML.

**Before**

```yaml
# ci.yml job ci
- uses: actions/checkout@<sha>
- name: Read the pinned opm CLI version   # run:, writes GITHUB_ENV
- uses: cue-lang/setup-cue@<sha>
- uses: go-task/setup-task@<sha>
- name: Verify the cascade wiring
```

**After**

```yaml
# ci.yml job ci
- uses: actions/checkout@<sha>
- uses: cue-lang/setup-cue@<sha>
- uses: go-task/setup-task@<sha>
- name: Verify the cascade wiring
- name: Read the pinned opm CLI version
```

## Impact

- **Published catalog: none.** No file under `src/` changes. Every commit is `ci`, `docs` or
  `chore`, all hidden, so `opm` does not advance. PR title: `ci(deps): pin the cascade to .github
  6938f8e`.
- **modules fleet, subscribing platforms, cli fixtures:** nothing to do.
- **Canary**: the `.github` diff touches neither `cascade-publish` nor `cascade-notify`, so no live
  canary run gates this pin.

## Enhancement

None. The source is the supervisor's security-pass plan (pin procedure in the `.github` README at
`6938f8e`); no enhancement backs it.
