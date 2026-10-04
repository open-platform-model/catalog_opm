## Context

No catalog member and no file under `src/` changes. The change edits the five workflows that hold
a `.github` reference, moves one step in `ci.yml`, replaces `.tasks/cascade/wiring-check.sh` and
amends `AGENTS.md`. Source: the `.github` README at `6938f8e0247e019cb0c2db13fff5b7b558a6b67d`,
sections "Pinning and bumps" and "The wiring check".

## Decisions

### D1. One SHA, five references

All five references carry `6938f8e0247e019cb0c2db13fff5b7b558a6b67d # .github main`.
`gh api repos/open-platform-model/.github/compare/6938f8e...main --jq .status` printed
`identical` before the edit. `git diff 7b9ad1b 6938f8e` on `.github` touches no action, no
reusable workflow and no caller shape, so no caller input and no `wiring-check.yaml` key changes.

### D2. The copy

`.tasks/cascade/wiring-check.sh` is the `.github` file at the pin, proven with
`gh api ".../contents/.github/scripts/cascade/wiring-check.sh?ref=6938f8e..." | cmp -`. It is
never edited here.

### D3. Step order in `ci.yml`

The README at the pin requires every step before the wiring step to be an action from another
repo at a full SHA with only `id`, `name`, `uses` and `with`, and names catalog_opm's
`OPM_CLI_VERSION` step. The step moves to just after the wiring step rather than further down:
`Install opm` is its first reader and the move keeps the diff to one block. `setup-cue` and
`setup-task` stay before the check; they are SHA-pinned actions and need no `GITHUB_ENV`.

## Durable decisions

- `AGENTS.md` § Cascade pin: the CI step also compares the copy with the file at the pin, and only
  SHA-pinned actions may come before it.
