## Context

The repository publishes two CUE modules from `opm/` and `k8s/` (AGENTS.md, Purpose). Every Taskfile task loops over `MODULES: opm k8s`; `ci.yml`, `branch-publish.yml` and `release.yml` loop over `opm k8s` and read release-please's per-package outputs keyed by path (`opm--tag_name`, `k8s--version`); `tools/refgen` loads both modules and writes the `k8s` table into `docs/site/reference/kubernetes-resources.md`. The `opm` module's published tree is its directory's contents; the directory's name appears in no published file.

No member file changes. No definition's closedness, defaults or required-field set moves.

## Goals / Non-Goals

**Goals:**
- One module, at `src/`, with every task, workflow and doc naming it.
- Tags, release history and the published `opm` artifact unchanged.
- No description left in this repository of two catalogs, a raw catalog or a `k8s/` directory, outside archived changes and the changelog.

**Non-Goals:**
- Deleting anything published: `k8s-v*` tags, GitHub Releases and GHCR builds of `k8s@v1` stay.
- Editing archived OpenSpec changes (`openspec/changes/archive/`) or released changelog entries; they record what was true.
- The downstream repositories (proposal, Impact).

## Decisions

### D1. release-please: rename the package path, keep the component

```json
"packages": {
  "src": {
    "release-type": "simple",
    "package-name": "catalog_opm",
    "component": "opm",
    "changelog-path": "/CHANGELOG.md",
    "versioning": "prerelease",
    "prerelease": false,
    "extra-files": [{"type": "generic", "path": "RELEASE"}]
  }
}
```

and `.release-please-manifest.json` becomes `{"src": "<current opm version>"}`. With `include-component-in-tag: true` and `component: "opm"`, release-please finds the previous release by the tag `opm-v<version>` and keeps tagging `opm-vX.Y.Z`. The `prerelease-type: "alpha"` key, unused on a stable line, is dropped. `RELEASE` is resolved relative to the package path, so `src/RELEASE` needs no edit.

Alternative rejected: a root package (`"."`). It would count every commit in the repository (CI, docs, OpenSpec) as a change to the module, and the module root would no longer be the package root.

### D2. Workflows: one module, no loops, path and component kept apart

Manifest mode keys per-package outputs by path even for a single package, so `release.yml` reads `steps.release.outputs['src--tag_name']` and `['src--version']`. Today `$m` / `matrix.module` is used as four keys at once: the directory, the release-please package key, the component and the tag prefix. After the move the first two are `src` and the last two stay `opm`, so no single variable can carry them:

- `release.yml`: the publish matrix built from `paths_released` (which now yields `src`) and its `format('{0}_tag_name', matrix.module)` lookups are replaced by one publish job gated on `src` being released, reading `src--tag_name` / `src--version`. The identity-advance loop (branch `release-please--branches--main--components--opm`, manifest key `.src`, `opm catalog version set ./src`, `git add src/identity/identity.cue`) is written out once.
- `branch-publish.yml`: directory `src`, tag prefix `opm-`, no loop.
- `ci.yml`: `opm catalog publish ./src --dry-run`.

The `k8s_*` outputs and every `k8s` loop entry go in section 1.

### D3. Taskfile: one directory variable, no loops

```yaml
vars:
  # The one CUE module this repo publishes: opmodel.dev/catalogs/opm@v4.
  MODULE_DIR: src
```

Each task runs once against `{{.MODULE_DIR}}`. The `.tasks/*.sh` scripts keep taking the module directory as an argument.

`.tasks/generate-index.sh` titles `INDEX.md` with `basename` of the directory (`# opm — Definition Index`). `INDEX.md` ships inside the module, so a `src` title would change the published tree. The script takes the label from the module path instead (the last element before the major, `opm`), and `INDEX.md` stays byte-identical; `task generate:index:check` proves it. `branch-tag` passes `opm-` as the tag prefix literally; it was derived from the directory name, which no longer matches the component. `vet:layering` is deleted: with one module there is nothing to layer.

### D4. Changelogs

`git mv CHANGELOG-opm.md CHANGELOG.md`; `CHANGELOG-k8s.md` is deleted (the `k8s` release notes stay on GitHub Releases). Changelogs sit outside the module root so they do not ship; `CHANGELOG.md` at the root keeps that.

### D5. `tools/refgen`

`refgen` loads `src/` only, stops writing the `k8s` table and fails if `kubernetes-resources.md` reappears. Its orphan check covers only the generated member directories, not this authored page under `docs/site/reference/`, so the retired path is named explicitly: `-check` fails while the file exists and a write removes it. The page is deleted. This keeps `task generate:reference:check` green until `publish-docs-bundle` section 3 retires `refgen`; that change's gate G3 waits on this one.

### D6. `tools/kindgen`

`kindgen` (added by `add-objects-resource`, which merged before this change) reads the `cue.dev/x/k8s.io` pin from `<module>/cue.mod/module.cue`, loads the x/k8s.io packages through that module and writes `<module>/schemas/kinds/table.cue`. Its module directory moves from `opm` to `src` with the rest. The generated table names no repository path, so it stays byte-identical; `KUBERNETES_VERSION` (`v1.36.0`, the release x/k8s.io `v0.12.0` is generated from) does not move. The `generate:kinds` and `test:kindgen` tasks and the kind-table lines in `AGENTS.md` (Purpose, Repository Layout, Dependencies, the command table) name `src/`.

## Research & Decisions

### Which files name `opm/`, `k8s/` or two catalogs
**Context**: The move has to reach every path and every description, including comments that say "Check against: catalog_opm/opm/...".
**Explored**: Workspace-wide grep (2026-10-02) for `catalogs/k8s`, `k8s catalog`, `raw catalog`, `two catalogs`, `catalog_opm/opm/` and `./opm`. In this repository: `AGENTS.md`, `README.md`, `Taskfile.yml`, `release-please-config.json`, `.release-please-manifest.json`, the three workflows, `.tasks/generate-index.sh`, `.tasks/fixtures.sh`, `.tasks/branch-tag.sh`, `tools/refgen/{main,render,refgen_test}.go`, `tools/kindgen/{main,kinds}.go`, `openspec/config.yaml`, the schema and its templates, `docs/name-constraints.md`, all seven pages under `docs/site/authoring/` and `docs/site/extending/`, `docs/site/reference/kubernetes-resources.md`, and the `publish-docs-bundle` change. Outside it: listed in the proposal's Impact.
**Decision**: tasks.md names each file; section 3 ends with a grep that must come back empty.
**Rationale**: A path in a comment rots silently; only the closing grep makes the rewrite complete.

## Risks / Trade-offs

- [release-please does not find the previous `opm` release after the path rename, and proposes `1.0.0` or a full changelog] → The manifest carries the version under the new key and the component is unchanged, which is how release-please resolves the last tag. Before merge, run `release-please release-pr --dry-run` against the PR branch and confirm it proposes nothing (every commit is hidden). If it misbehaves, a one-shot `Release-As:` cannot fix a lookup, so the fix is `bootstrap-sha` set to this PR's merge base.
- [The published tree changes after all (an INDEX title, a generated path)] → Before merge, `opm catalog publish ./src --dry-run` on the branch and the same on `main`'s `opm/` must report the same tree digest; a difference is a bug in this change, not a release.
- [A CI run on the PR still loops over `opm` because a workflow line was missed] → The workflows fail loudly on a missing directory; the PR's own CI is the check.
- [Docs in other repositories link to `kubernetes-resources.md` on the site] → The downstream sweep removes those links; until then the site build reports a broken reference and does not publish a dead link.
- [A downstream test reads `../catalog_opm/opm` and skips when it is missing] → cli `TestRealTree_CatalogOpm` does exactly that. The cli change moves it to `src`; this change's PR body names it so the reviewer checks it landed.

## Durable decisions

- One module at `src/`; release-please package path `src` with component `opm`: lands in `AGENTS.md` (Purpose, Repository Layout, Repository Rules) and `openspec/config.yaml` Principle IV.
- The raw passthrough catalog is retired, and `objects@v1alpha1` is the escape hatch: lands in `AGENTS.md` Purpose and `README.md`.
