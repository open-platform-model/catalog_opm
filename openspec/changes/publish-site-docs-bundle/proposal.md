## Why

opmodel.dev still reads this repository's `docs/site/` (seven authored pages under `authoring/` and `extending/`) through git: `resolve-versions.sh` picks the `opm-v4` line, `materialise.sh` copies the tree and `gen-lastmod.sh` dates it. docs-kit phase 3 (`docs-kit DESIGN decision 4`, phase 3 in `DESIGN.md`) ends that: every repository ships its authored pages in a signed docs bundle, and the site build reads no git repository except its own. This repository goes first (docs-kit `docs/orchestration.md`, phase 3 step 1): its catalog reference is already a bundle, so it has the workflow, the pinned tool and the release job, and only needs a second project.

The pages cannot join the `catalog-opm` bundle: that bundle is a tab placed at `/catalogs/opm/`, and these pages publish under `/docs/`. docs-kit names a repository's docs-placed bundle after the repository, with the suffix `-docs` when that name is already a tab project of the same repository (docs-kit C1, the naming rule decided in `generalize-build-assembly` D9): `catalog-opm-docs`.

## Gates

| Section | Gate |
| --- | --- |
| 1. Publish the catalog-opm-docs bundle | **G3.0** (docs-kit `orchestration.md`): `add-authored-docs` is released, so the release that carries it also carries `generalize-build-assembly` (docs placement, C15) and `pull-docs-placement` is at least merged. The contracts are re-read at that tag (task 1.1). |
| 2. Go live (owner) | Section 1 is merged and its first `Docs / edge` run for `catalog-opm-docs` is green. The release half waits for the first opm release after that merge (design.md, "The first release bundle needs the next opm release"). |

Delivery: one PR per section (opmodel.dev needs the published catalog-opm-docs bundle after section 2)

## What Changes

- **Section 1, publish the catalog-opm-docs bundle.** `docs-kit.cue` gains a second project, `catalog-opm-docs`: placement `docs` at `/docs/`, version from the same `opm-v` tags as the tab, one `markdown` source over `docs/site`. `docs.yml` runs `check` and `edge` for both projects (a matrix over `project`), and its dispatch gains a `project` choice. `release.yml`'s `publish-docs` publishes both projects from the same release tag. `docs:bundle` and `docs:bundle:check` cover both. `.opm-docs-version` and every `publish.yml@` ref move to the docs-kit release of the gate, together (docs-kit C5). `AGENTS.md` says what `docs/site/` now ships in.
- **Section 2, go live (owner).** Verify `ghcr.io/open-platform-model/docs/catalog-opm-docs` is public and linked, verify the first `edge`, then the first release bundle, published by the next opm release. Record the digests in design.md and archive the change.

## Before / After

No catalog member changes. The review surface is the bundle configuration.

**Before**

```cue
// docs-kit.cue
bundles: {
	"catalog-opm": {
		placement: {kind: "tab", root: "/catalogs/opm/"}
		version: {from: "tag", prefix: "opm-v"}
		sources: [
			{kind: "cue-catalog", module: "./src"},
			{kind: "markdown", dir: "docs/catalogs/opm"},
		]
	}
}
```

**After**

```cue
// docs-kit.cue (docs-kit add-authored-docs D2)
bundles: {
	"catalog-opm": {
		placement: {kind: "tab", root: "/catalogs/opm/"}
		version: {from: "tag", prefix: "opm-v"}
		sources: [
			{kind: "cue-catalog", module: "./src"},
			{kind: "markdown", dir: "docs/catalogs/opm"},
		]
	}
	"catalog-opm-docs": {
		placement: {kind: "docs", root: "/docs/"}
		version: {from: "tag", prefix: "opm-v"}
		sources: [{kind: "markdown", dir: "docs/site"}]
	}
}
```

## Impact

- **Release class.** Section 1 is `ci(docs):`, section 2 `docs(openspec):`. Neither touches `src/`, so neither cuts an opm release, and the published CUE module is byte-identical. No member moves to a new `apiVersion` segment; nothing is breaking.
- **Modules fleet, subscribing platforms, cli fixtures.** Nothing to do: they consume the CUE module.
- **opmodel.dev** (`serve-docs-from-bundles` section 1, gate G3.1): `bundles.cue` gains `docs."catalog-opm-docs"` (`repo: "open-platform-model/catalog_opm"`) and `versions."v1.0".tags."catalog-opm-docs": "4"`; this repository's `docs/site/` leaves the site's git mounts and `resolve-versions.sh`. The tag `4` exists only after the first release bundle (section 2), so G3.1 means a release bundle, not `edge`.
- **Registry.** A new package `ghcr.io/open-platform-model/docs/catalog-opm-docs`, created by the first `edge` publish. Same tag scheme as `catalog-opm` (docs-kit C4): full tags immutable, the others move by design.
- **Authors.** A page under `docs/site/` now reaches `edge` on the next push to `main`, and a released minor only through a release or a docs revision (`-f project=catalog-opm-docs -f mode=revision`). "Edit this page" on the site links the file on `main` (docs-kit DESIGN decision 19, `pages[].edit`).

## Enhancement

None. No enhancement entry backs this work; it implements docs-kit `DESIGN.md` decisions 4 and 19 against docs-kit contracts C1, C5, C6 and C15 (`add-authored-docs`, `generalize-build-assembly`). There is no `enhancement.yaml` and no delivery log.
