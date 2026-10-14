# catalog_opm: where do I go?

Router only. Facts and rules are in `AGENTS.md`.

| Task | Read first | Then |
| --- | --- | --- |
| Add or change a resource, trait or blueprint | `references/authoring-rules.md` | `docs/site/extending/`, the page for that kind |
| Add or change a transformer | `references/authoring-rules.md` | `references/fixtures.md`, `docs/transformer-authoring.md` |
| Write or fix a transformer fixture, or `task vet:fixtures` fails | `references/fixtures.md` | `.tasks/fixtures.sh` |
| Change a generated index, `src/INDEX.md` | `task generate:index` in `Taskfile.yml` | `references/doc-comments.md` |
| Name a field that lands in a DNS label, or write a struct disjunction | `docs/name-constraints.md` or `docs/struct-disjunctions.md` | `references/authoring-rules.md` |
| Change the Kubernetes kind table or bump `cue.dev/x/k8s.io` | `references/authoring-rules.md` | `tools/kindgen/` |
| Release, a release PR, a burned or skipped version, or an edit to `release.yml` | `references/release-publishing.md` | `references/releases.md` at the workspace root |
| Choose a commit type or PR title, or force a version | `references/release-publishing.md` | `RELEASING.md` at the workspace root |
| Cascade notify, `deps/cascade`, the `.github` pin, `.opm-cli-version` (not a release-flow edit) | `references/cascade-wiring.md` | `RELEASING.md` at the workspace root |
| Publish or fix the docs bundles, or move the docs-kit pin | `references/docs-bundles.md` | `docs-kit.cue` |
| Write a `//` doc comment or a member description | `references/doc-comments.md` | `.tasks/doc-check.sh` |
| Change a site page | `docs/site/` | `STYLE.md` and `VOICE.md` at the workspace root |
| Run, format or vet | `Taskfile.yml` | `AGENTS.md`, the Commands section |
| Start a feature change | `openspec/config.yaml` | `.claude/skills/openspec-new-change/SKILL.md` |
| Deliver or cite an enhancement | `references/enhancements.md` at the workspace root | `openspec/config.yaml`, the `references:` entry |
| Commit, open a PR or write GitHub text | `references/git-text.md` at the workspace root | |
| Touch a registry or a CUE module path | `references/registry.md` at the workspace root | |
