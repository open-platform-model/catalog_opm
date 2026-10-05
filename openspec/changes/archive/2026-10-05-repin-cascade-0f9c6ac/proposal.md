## Why

`.github` `main` is now `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13`. Since catalog_opm's pin
`6938f8e` it carries `.github` PR 16 (a single code owner), PR 17 (owner decision 37, "Which
repos move when", in the README's rollout steps) and PR 19: `cascade-publish` refuses a push or
recreate when a receiver's mirrored `.tasks/cascade/` files differ on its `origin/main` from the
sha256 recorded in `mirror_sources` (`wiring/lib.sh`), the daily `cascade-mirror-drift.yml`
runs the same comparison, and the resolver's `newest` also checks opm-operator's
`opm_operator-v*` tags are on its `main`. catalog_opm still pins `6938f8e`, so its cascade runs
neither the mirror-drift refusal nor the updated resolver.

PR 19 changes `wiring/lib.sh`, which both `cascade-notify` and `cascade-publish` run, so the
README's "Both actions" rule applied: the library moved first as the canary (library PR 204).
Its first live publish (library PR 206) and its first live notify (library `v1.0.0-beta.5`
release run 37294102028, `Notify downstream` green) on the new pin succeeded, so catalog_opm may
now move.

## What Changes

- **The pin**: the five `open-platform-model/.github` references (the `cascade-notify` step in
  `release.yml`, the `cascade-receive.yml` call and the `cascade-publish` step in
  `deps-cascade.yml`, the `cascade-gates.yml` call, the resolver `ref:` in `cascade-task.yml`)
  move from `6938f8e` to `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13 # .github main`.
- **The wiring check**: `.tasks/cascade/wiring-check.sh` is the canonical file at the new pin,
  byte for byte. The file is unchanged between `6938f8e` and `0f9c6ac`, so the copy already is.
- **Nothing else.** The README at `0f9c6ac` changes no caller shape or input and leaves
  catalog_opm's config-table row as it was, so `.tasks/cascade/wiring-check.yaml`, `ci.yml` and
  `AGENTS.md` stay as they are.

## Before / After

No catalog member changes, so there is no CUE member shape. The reviewed surface is the five
reference lines.

**Before**

```yaml
uses: open-platform-model/.github/.github/actions/cascade-notify@6938f8e0247e019cb0c2db13fff5b7b558a6b67d # .github main
```

**After**

```yaml
uses: open-platform-model/.github/.github/actions/cascade-notify@0f9c6ac2c9b752a79f4874f637ef9955bcf00c13 # .github main
```

## Impact

- **Published catalog: none.** No file under `src/` changes. Every commit is `ci` or `chore`,
  both hidden, so `opm` does not advance. PR title: `ci(deps): pin the cascade to .github
  0f9c6ac`.
- **modules fleet, subscribing platforms, cli fixtures:** nothing to do.
- **Mirror drift**: catalog_opm's `.tasks/cascade/pins.sh`, `classes` and `cascade.sh` on
  `origin/main` (`423c6f9`) hash to the values in `mirror_sources` at `0f9c6ac`, so the new
  refusal passes for this repo. From this pin on, a change to any of those three files needs the
  matching `.github` mirror and hash change merged and pinned first, or publish refuses
  catalog_opm's plans.

## Enhancement

None. The source is the supervisor's security-pass plan (pin procedure in the `.github` README
at `0f9c6ac`); no enhancement backs it.
