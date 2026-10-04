## Context

No catalog member, no file under `src/` and no `apiVersion` segment changes. The change edits
`.github/workflows/release.yml`, `deps-cascade.yml`, `cascade-gates.yml`, `cascade-task.yml` and
`ci.yml`, replaces `.tasks/cascade/wiring-check.sh`, adds `.tasks/cascade/wiring-check.yaml`, and
amends `AGENTS.md`.

Sources, highest authority first: owner decisions 28 to 31, the supervisor's security-pass plan
(wave 2), and the `.github` README at `7b9ad1bea132f7a3f053a5db61ac3933b59ee226` (sections
"Cascade workflows", "Pinning and bumps", "The wiring check").

## Decisions

### D1. One SHA, five references

All five `.github` references carry `7b9ad1bea132f7a3f053a5db61ac3933b59ee226 # .github main`.
`gh api repos/open-platform-model/.github/compare/7b9ad1b...main --jq .status` printed
`identical` before the edit. The comment lines in the workflows that name the pin in prose need no
change.

### D2. The publish caller shape

The `.github` README's receiver caller at that SHA is the target, verbatim except the per-repo
values (`setup-go: false`, `labels-managed: false`, and `cue-version: v0.17.1`, which
`wiring/install-tools.sh` holds a sha256 for). Two edits: `&& inputs.gates_only != true` in the
`publish` `if:` after `inputs.dry_run != true`, and `gates-only: ${{ inputs.gates_only == true }}`
as the `Publish` step's second input. Without the input the action fails before minting, so the
two must land with the pin.

### D3. The canonical check and its config

`.tasks/cascade/wiring-check.sh` is the `.github` file at the pin, fetched and proven with `cmp`;
it is never edited here. `.tasks/cascade/wiring-check.yaml` holds the README's catalog_opm row:

```yaml
pin-comment: .github main
receiver: true
env-allow: [OPM_REGISTRY, CUE_REGISTRY]
publish-workflows: [release.yml, branch-publish.yml, docs.yml]
ci: {workflow: ci.yml, job: ci}
notify:
  needs: [release-please, publish-cue]
  if: ${{ !cancelled() && needs.publish-cue.outputs.published == 'true' && vars.CASCADE_NOTIFY != 'off' }}
  tag: ${{ needs.release-please.outputs.opm_tag_name }}
publish:
  labels-managed: false
```

`notify.needs`, `if` and `tag` are read from `release.yml`'s `notify-downstream` on `main`
(`daae275`), and the publishing workflows are the three that push to GHCR (`release.yml`,
`branch-publish.yml`, `docs.yml`).

### D4. The CI step

"Verify the cascade wiring" in `ci.yml`'s `ci` job becomes the README's exact step: `env:
GH_TOKEN: ${{ github.token }}`, `run: bash .tasks/cascade/wiring-check.sh --pin-on-main`. The
job's `contents: read` token is enough for the public `compare` call. `task cascade:wiring:check`
stays offline (no flag) for laptops and `task check`.

## Durable decisions

- The pin, the canonical copy, the config file and the `--pin-on-main` CI step: `AGENTS.md`
  § Release & publishing ("Cascade pin") and the `task cascade:wiring:check` row of the command
  table.
- The gates-only switch on `publish`: `AGENTS.md` § Release & publishing ("Receive and gate").
