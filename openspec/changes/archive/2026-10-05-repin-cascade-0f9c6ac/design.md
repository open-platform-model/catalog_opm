## Context

No catalog member and no file under `src/` changes. The change edits the four workflows that
hold the five `.github` references and confirms the wiring-check copy. Source: the `.github`
README at `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13`, sections "Pinning and bumps", "Keeping
the mirrors in step" and "The wiring check".

## Decisions

### D1. One SHA, five references

All five references carry `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13 # .github main`.
`gh api repos/open-platform-model/.github/compare/0f9c6ac...main --jq .status` printed
`identical` before the edit. `git diff 6938f8e 0f9c6ac` on `.github` changes no action or
reusable-workflow input and no caller shape, and the README's config table row for catalog_opm
is unchanged, so no caller input and no `wiring-check.yaml` key changes.

### D2. The copy

`.tasks/cascade/wiring-check.sh` is the `.github` file at the pin, proven with
`gh api ".../contents/.github/scripts/cascade/wiring-check.sh?ref=0f9c6ac..." | cmp -`. The
file did not change between the two pins, so the copy needs no edit.

### D3. Mirror hashes checked before the PR

`mirror_sources catalog_opm` at the pin records `.tasks/cascade/pins.sh` `264c6f70…`,
`classes` `83e67ce0…` and `cascade.sh` `c5605510…`. `git show origin/main:<file> | sha256sum`
on `423c6f9` gives the same three values (catalog_opm has no `.tasks/cascade/lib.sh`), so
publish will not refuse catalog_opm for a stale mirror once live.

## Durable decisions

None. `AGENTS.md` § Cascade pin already describes the pin procedure and names no SHA; the
mirror-before-receiver ordering is owned by the `.github` README.
