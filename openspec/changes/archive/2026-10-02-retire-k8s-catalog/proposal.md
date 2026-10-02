## Why

The raw Kubernetes catalog `opmodel.dev/catalogs/k8s@v1` is retired (owner decision, 2026-10-02). Nothing uses it: no module in `modules/` or `opm-modules/` imports it, and the cli subscribes to it only in its default platform template and in test samples. Its only member worth keeping, the object escape hatch, is replaced by `objects@v1alpha1` in the `opm` catalog (change `add-objects-resource`), which validates against `cue.dev/x/k8s.io` where the k8s catalog's open wrappers validated nothing.

With one module left, the two-module layout (`opm/` and `k8s/` side by side, Taskfile loops over `MODULES`, the layering check, two release-please packages) is cost with no purpose. The `opm` module root moves back to `src/`, where it lived before the split. The CUE module path does not change.

## What Changes

- **Remove the `k8s` module.** Delete `k8s/` and `CHANGELOG-k8s.md`; drop the `k8s` package from `release-please-config.json` and `.release-please-manifest.json`; drop every `k8s` loop entry, output and step in `ci.yml`, `branch-publish.yml` and `release.yml`; delete `task vet:layering`. `tools/refgen` stops loading `k8s/` and stops writing `docs/site/reference/kubernetes-resources.md`, which is deleted.
- **Move `opm/` to `src/`** with `git mv`. `module: "opmodel.dev/catalogs/opm@v4"` and every import path stay byte-identical, so the published artifact does not change.
  - release-please: the package key (its path) becomes `src`; `component` stays `opm`, so tags stay `opm-vX.Y.Z`. `CHANGELOG-opm.md` becomes `CHANGELOG.md`. Per-package outputs in `release.yml` move from `opm--*` to `src--*`.
  - Taskfile: the `MODULES` loops collapse to the one module directory; `branch-tag` passes the `opm-` tag prefix explicitly, because it was derived from the directory name.
  - `.tasks/*.sh`, `tools/refgen`, `tools/kindgen` and every "Check against" path in `docs/site/` name `src/`.
- **Rewrite the repository's description of itself as one catalog**: `AGENTS.md`, `README.md`, `openspec/config.yaml` (Principles I, III and IV), `openspec/schemas/catalog-change/schema.yaml` and its templates, and every page under `docs/site/` that names the raw catalog, `k8s/` or two catalogs.
- **Update the planned change `publish-docs-bundle`** in place: its extractor path `./opm` becomes `./src`, and its gate G3 notes that this change has landed.
- Nothing is **BREAKING** for a consumer of `opmodel.dev/catalogs/opm@v4`. For `k8s`, see Impact.

## Before / After

No catalog member changes. The review surface is the layout and the release configuration.

**Before**

```cue
// repository layout
"opm/": cue.mod: module: "opmodel.dev/catalogs/opm@v4"
"k8s/": cue.mod: module: "opmodel.dev/catalogs/k8s@v1"

// release-please-config.json, packages (JSON shown as CUE)
packages: {
	opm: {component: "opm", "changelog-path": "/CHANGELOG-opm.md"}
	k8s: {component: "k8s", "changelog-path": "/CHANGELOG-k8s.md", prerelease: true}
}
// .release-please-manifest.json
{opm: "4.5.0", k8s: "1.0.0-beta.2"}
```

**After**

```cue
"src/": cue.mod: module: "opmodel.dev/catalogs/opm@v4"

packages: src: {component: "opm", "changelog-path": "/CHANGELOG.md"}
{src: "4.5.0"}
```

## Impact

- **Release class.** Every commit is a hidden type (`refactor`, `chore`, `ci`, `docs`): the published `opm` tree is byte-identical, so no release follows (AGENTS.md, rule of thumb). The PR title is `refactor: retire the k8s catalog and move the opm module to src/`.
- **Order.** This change lands after `add-objects-resource` has merged, so the escape hatch exists before the k8s catalog goes and that change's files move with the rest.
- **`k8s` consumers.** Every published `opmodel.dev/catalogs/k8s@v1` build and every `k8s-v*` tag stays (release tags and published versions are immutable), so a platform or module that pins one keeps resolving. No further `k8s` release follows; `1.0.0-beta.2` is the last. CUE has no deprecation marker for a module, so the retirement is announced in `README.md` and in the downstream changes.
- **`modules` fleet and `opm-modules`.** Nothing to do: none pins `k8s`, and the `opm` path is unchanged.
- **Subscribing platforms.** A platform that subscribes to `k8s@v1` keeps working on the last build; the cli and the operator stop seeding the subscription in their own changes.
- **Downstream repositories** carry their own changes, not this one: `cli` (the default catalog list, test samples, `TestRealTree_CatalogOpm`, which skips silently when `catalog_opm/opm` is missing, and the `replaceWith: "../catalog_opm/opm"` test fixtures), `library`, `opm-operator`, `core`, `opm` and `opmodel.dev` (site pages and specs naming two catalogs or `catalog_opm/opm/`), the workspace root (`.tasks/deps/*`, `AGENTS.md`, `RELEASING.md`) and `opm-suite-installer` (a vendored copy of `k8s@v1`). They may land before or after this change.
- **`publish-docs-bundle`.** Its section 2 backfills `opm-v4.4.5`, whose tree has the module at `opm/`. A backfill of any tag cut before this change needs the old path; that change's design must take the extractor path per tag or limit the backfill to tags after this one.

## Enhancement

None. This retires the raw passthrough family that enhancement 0010 D47 folded into this repository and D48 versioned after upstream, by owner decision, with no new entry; 0010 is archived and is not reopened.
