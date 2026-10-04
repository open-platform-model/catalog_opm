## Context

`docs/site/` holds seven authored pages: `authoring/attach-a-trait.md`, `authoring/choose-a-blueprint.md`, `authoring/use-a-raw-kubernetes-resource.md`, and `extending/write-a-{blueprint,resource,trait,transformer}.md`. No `_index.md`: the section pages `/docs/authoring/` and `/docs/extending/` are site content (docs-kit `add-authored-docs`, Non-Goals). No other repository's `docs/site/` has a page at one of these paths (checked 2026-10-03 against opm, core, cli, library and opm-operator `main`), so the site version's pull finds no collision (docs-kit C16 D4).

The `catalog-opm` docs bundle (archived change `publish-docs-bundle`) supplies everything this change reuses: `docs.yml` (`check` on pull requests, `edge` on push to `main`, a `workflow_dispatch` with modes `release` and `revision`), `release.yml`'s `publish-docs` job gated on `publish-cue`'s `published` output, `.opm-docs-version`, `.tasks/opm-docs.sh` and the `tools:opm-docs`, `docs:bundle`, `docs:pins:check` and `docs:bundle:check` tasks.

Contracts this change consumes, from docs-kit (`docs/contracts.md` once the changes archive; until then each change's `design.md` on docs-kit `main`):

- **C1**: the project `catalog-opm-docs`, repository catalog_opm, tag prefix `opm-v`, placement docs (its `docs/site/`), phase 3 (`generalize-build-assembly` D9).
- **C5**: one `publish.yml` call per project and mode; callers pin it by docs-kit tag and move `.opm-docs-version` with it; per-mode permissions as today. In release mode the config is the release tree's `docs-kit.cue` when the tag has one, else `main`'s.
- **C15**: a docs bundle has root `/docs/`, may declare `owns` (only paths its renderers generate must be owned; an authored-only bundle owns nothing), carries no `cue-catalog` source, and is linted in bundle mode: docs-mode link rules, `/catalogs/` links only through the bare root or a major.
- **C3, C8 (`add-authored-docs` D1)**: `build` records `pages[].edit` for an authored page whose path exists on `main`; the site links "Edit this page" to `https://github.com/open-platform-model/catalog_opm/edit/main/<edit>` (DESIGN decision 19).

This repository is on docs-kit `v0.2.1` (#128); opmodel.dev pins `0.2.2`.

**Trial build, 2026-10-03, docs-kit `v0.2.1`.** With the After config of proposal.md in a scratch tree, `opm-docs check --project catalog-opm-docs` passed: 7 pages, no lint violation. `v0.2.1` predates `pages[].edit`, so task 1.6 re-checks the manifest at the gate's release.

**G3.0 re-read, 2026-10-04, docs-kit `v0.6.0`** (task 1.1). The release lists the four archives and `checksums.txt`; opmodel.dev `main` pins `OPM_DOCS_VERSION=0.6.0`. C1 (the `catalog-opm-docs` row), C3 (`#Page.edit`), C5 (inputs, per-mode permissions, the release tree's config read first), C6 and C15 match this design; nothing in it changed. Section 1 therefore moves straight to `v0.6.0`. Task 1.6 at `v0.6.0`: `out/catalog-opm-docs/` holds the 7 pages, each `generated: false` with `source` and `edit` equal to `docs/site/<path>` and a `lastmod`, placement `docs` at `/docs/` with no `owns`; `opm-docs lint --bundle` (markup check included) passes both bundles; `out/catalog-opm/` has the same 50 pages and identical content as a build of `main` with the same tool, and none of its pages has `edit`.

No member file, `apiVersion` segment, definition, default, closedness or required-field set is touched.

## Goals / Non-Goals

**Goals:** publish `docs/site/` as `catalog-opm-docs` at `edge` and with every opm release, from the same workflows as `catalog-opm`.

**Non-Goals:** moving or rewriting any page; the site's switch (opmodel.dev `serve-docs-from-bundles`); a backfill of releases cut before section 1 (most would build with `main`'s config and publish the retired reference pages, so a guard refuses them, see below); docs-kit's own changes.

## Decisions

### One more project, same tags

`docs-kit.cue` gains `catalog-opm-docs` exactly as proposal.md's After block shows. It MUST use the `opm-v` prefix: both projects publish from the same release tag, and the site picks this one by major (`tags."catalog-opm-docs": "4"`), as `catalog-line = opm-v4` does today. It declares no `owns` (no renderer writes into it).

### `docs.yml`: a matrix over `project`

```yaml
on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      project:
        description: catalog-opm (the Catalogs tab) or catalog-opm-docs (docs/site)
        type: choice
        options: [catalog-opm, catalog-opm-docs]
        required: true
      mode: # unchanged: release | revision
      tag:  # unchanged
      fix:  # unchanged
permissions: {}
jobs:
  check:
    if: github.event_name == 'pull_request'
    strategy:
      fail-fast: false
      matrix:
        project: [catalog-opm, catalog-opm-docs]
    permissions: {contents: read, packages: read}
    uses: open-platform-model/docs-kit/.github/workflows/publish.yml@vX.Y.Z
    with: {project: "${{ matrix.project }}", mode: check}
  edge:      # the same matrix, mode edge, the publishing permissions
  dispatch:  # no matrix: project: ${{ inputs.project }}
```

`fail-fast: false`, so a failure of one project never cancels the other's publish. The check job names change from `Docs / check` to `Docs / check (catalog-opm)` and `Docs / check (catalog-opm-docs)`. No rule requires the old name: branch protection on `main` requires only `Validate catalog` (read 2026-10-03). `publish.yml`'s concurrency groups are keyed on the project (C5), so the two edge runs of one push never cancel each other. The dispatch's `project` input has no default: a recovery or revision names its bundle.

### `release.yml`: `publish-docs` once per project

The existing job gains the same matrix and keeps its `needs`, its condition (`always() && needs.publish-cue.outputs.published == 'true'`) and its permissions. Both bundles document the same release, so both are gated on the module actually being on GHCR.

### Tasks over both projects

`docs:bundle` and `docs:bundle:check` loop over a `DOCS_PROJECTS` var (`catalog-opm catalog-opm-docs`): `opm-docs build --project <p> --out out` and `opm-docs check --project <p>`. The pin check runs once.

### The first release bundle needs the next opm release

`opm-v4.5.1`, the newest release, already has a `docs-kit.cue` (one project, `catalog-opm`). In release mode `build --source src` reads the release tree's config when it has one (C5), so a `mode: release` dispatch of `catalog-opm-docs` for `opm-v4.5.1` fails with an unknown project. docs-kit `orchestration.md` first assumed that dispatch works; it does not, and this change MUST NOT rely on it. Earlier tags are worse: up to `opm-v4.5.0` they have no `docs-kit.cue`, so C5 falls back to `main`'s config, and a `mode: release` dispatch of `catalog-opm-docs` builds, lints and publishes their retired reference pages (an `opm-v4.5.0` dry run gave 59 pages, 52 of them retired) as `4.5.0.0`, moving `4.5` and `4`. Nothing in C5 stops that, so `docs.yml` gets a `guard` job that `dispatch` needs: it reads `docs-kit.cue` at the tag through the contents API and refuses `catalog-opm-docs` unless that file exists and declares the project. C5 stays as it is (supervisor decision, 2026-10-03): gate G3.1 is the first `catalog-opm-docs` release bundle, published with the next opm release. The first release bundle is published by `release.yml` with the first opm release whose tag contains section 1's `docs-kit.cue`. Section 1 is a `ci` commit, so it cuts no release by itself; the bundle waits for the next `feat:` or `fix:` on opm, or for an owner-forced patch (as opm 4.5.1 was for `catalog-opm`).

## Research & Decisions

### Second project versus a docs source in the tab bundle

**Context**: the tab bundle already has a `markdown` source.
**Explored**: docs-kit C15 and `generalize-build-assembly` D2: one bundle has one placement; a tab places every page under `/catalogs/opm/<segment>/`.
**Decision**: a second project, `catalog-opm-docs`.
**Rationale**: these pages publish under `/docs/` in a site version, which only a docs placement can do; the name follows docs-kit's naming rule.

### Matrix versus two named jobs

**Context**: three `publish.yml` callers would double to six.
**Explored**: reusable-workflow jobs accept `strategy.matrix`; the matrix value is known before the called workflow's concurrency expression is evaluated.
**Decision**: a matrix in `check`, `edge` and `publish-docs`; the dispatch takes `project` as an input.
**Rationale**: one place per mode to change on the next docs-kit bump.

### Backfill of `opm-v4.5.1`

**Context**: docs-kit `orchestration.md` offers a dispatch for the newest `opm-v4.*` tag as the go-live path.
**Explored**: `git show opm-v4.5.1:docs-kit.cue` declares only `catalog-opm`; C5 reads the release tree's config first.
**Decision**: no backfill; the first release bundle comes with the next opm release.
**Rationale**: for `opm-v4.5.1` the dispatch fails (unknown project); for every earlier tag it would succeed with `main`'s config and publish the retired reference pages, so the refusal is policy, enforced by `docs.yml`'s `guard` job, not by C5. Changing C5 is docs-kit's call (reported to its plan as a gap).

## Risks / Trade-offs

- [The site's G3.1 waits on an opm release that no docs work triggers] -> section 2 names the wait; the owner may force a patch, as for opm 4.5.1.
- [`add-authored-docs` writes a field an older site `pull` refuses (closed manifest schema)] -> G3.0 requires opmodel.dev's `OPM_DOCS_VERSION` at the gate's release or newer before section 1 merges; task 1.6 confirms the `catalog-opm` tab manifest gains no `edit`.
- [Docs revisions stay manual] -> owner decision, 2026-10-03; automation is open-platform-model/catalog_opm#130 (tracked by open-platform-model/docs-kit#16).
- [A required check is added for `Docs / check` before section 1 merges] -> task 1.8 re-reads branch protection; today only `Validate catalog` is required.
- [A page that passes the site's shell lint fails `opm-docs lint` in bundle mode] -> the trial build found none at `v0.2.1`; task 1.6 repeats it at the gate's release.

## Durable decisions

- `docs/site/` ships in the `catalog-opm-docs` bundle, built from the same `opm-v` tags as the tab; the dispatch and the tasks name a project: `AGENTS.md`, "Docs bundles" and Repository Layout (section 1).
- The docs-kit pin covers both projects and still moves in one PR with every `publish.yml@` ref: `AGENTS.md`, "Docs bundles" (already there; reworded in section 1).
- Why no backfill of `opm-v4.5.1`: stays with the change.
