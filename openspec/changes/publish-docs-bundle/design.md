## Context

Today `tools/refgen` (own `go.mod`, `cuelang.org/go` v0.17.1) loads both catalog modules and writes `docs/site/reference/catalog-members/` (one page per `opm` blueprint, resource and trait), the generated block of `catalog-members/_index.md`, and the table in `docs/site/reference/kubernetes-resources.md`. `task generate:reference:check` and `task test:refgen` run in `task check` and in `ci.yml`; `release.yml`'s identity advance runs `task generate:reference` on every release PR, because every page carries `identity.Version`. Three workflows install Go only for refgen (`ci.yml`, `branch-publish.yml`, `release.yml`). opmodel.dev's v1.0 version reads this repository's `docs/site/` from `main` while `main` still releases opm 4.x (opmodel.dev `site/versions.conf`), so a file deleted on `main` leaves the site at its next build.

The authored contract page is `docs/site/reference/catalog-contract.md` (title "The Catalog Contract", `type: reference`, `weight: 5`). No page in this repository links it or the member pages; the references are maintainer "Check against" pointers inside HTML comments in `docs/site/extending/` (four, to the contract file) and `docs/site/authoring/` (two, to `catalog-members/`). Outside this repository only cli's `docs/site/reference/registry-namespaces.md` links `/docs/reference/catalog-contract/`.

Contracts this change consumes, from docs-kit's change `build-opm-docs-phase-1` (`design.md`):

- **docs-kit C1**: the bundle lives at `ghcr.io/open-platform-model/docs/catalog-opm`, placement tab, root `/catalogs/opm/`, release tag prefix `opm-v`.
- **docs-kit C4**: full tags `<version>.<revision>` are immutable; `4.4.5`, `4.4`, `4` and `edge` move; edge builds carry no full tag.
- **docs-kit C5**: callers pin `publish.yml` by tag (`@v0.1.0`), declare no secrets, and grant per mode: `check` needs `contents: read`, `packages: read`; `edge` and `release` need `contents: read`, `packages: write`, `id-token: write`. Every mode but `check` refuses unless `github.ref` is `refs/heads/main`. `release` runs from the job that runs release-please, gated on that package's release, or by `workflow_dispatch` for a release with no bundle yet. A release cut before the repository had `docs-kit.cue` builds with `main`'s.
- **docs-kit C6**: `docs-kit.cue` at the repository root, `bundles` keyed by project; a root `_index.md` from a `markdown` source replaces the generated landing.
- **docs-kit C8, C11**: page paths and link forms. An authored bundle page links into its own catalog through the major alias (`/catalogs/opm/4/<path>/`), which the `markdown` source rewrites to the build's own segment; `/docs/<section>/<page>/` links from a tab page resolve in the site's default version; an `_index.md` declares no `type`.
- **docs-kit C9**: the signature's Source Repository Ref must be `refs/heads/main`, so no bundle is published from a release branch or a tag ref (docs-kit DESIGN decision 9).

No member file, `apiVersion` segment, definition, default, closedness or required-field set is touched. The only files under a module root that any section reads are the ones `opm-docs` evaluates.

## Goals / Non-Goals

**Goals:**

- Every push to `main` publishes a signed `edge` bundle of the opm catalog; every opm release publishes `<version>.0` in the same workflow run that publishes the CUE module.
- Every pull request runs `opm-docs check`; `task check` runs the same check locally with the same tool version CI uses.
- The authored contract page is the bundle's landing.
- After section 3, nothing under this repository generates or commits reference pages, and the repository has no Go code and no Go toolchain step.

**Non-Goals:**

- A `catalog-k8s` bundle. The `k8s` catalog is being removed from this repository by another change; section 3 waits for it (gate G3).
- Docs revisions. Their dispatch belongs to docs-kit's change `add-docs-revisions` (Decisions, "Docs revisions are left to add-docs-revisions").
- Any edit to opmodel.dev, cli, docs-kit or the workspace repository.
- Redirects from the old Reference URLs (opmodel.dev's decision, after section 3).

## Decisions

### One bundle, declared at the repository root

`docs-kit.cue` is docs-kit C6's example with the `catalog-k8s` entry dropped:

```cue
bundles: {
	"catalog-opm": {
		placement: {kind: "tab", root: "/catalogs/opm/"}
		version: {from: "tag", prefix: "opm-v"}
		sources: [
			{kind: "cue-catalog", module: "./opm"},
			{kind: "markdown", dir: "docs/catalogs/opm"},
		]
	}
}
```

It sits outside both module roots, so `cue` run from `opm/` never loads it and `opm catalog publish ./opm` never ships it, and it changes no release-please package (its commit touches no file under `opm/` or `k8s/`). It carries no `package` clause, as docs-kit C6 shows it. `task fmt` and `task fmt:check` MUST format and diff it alongside the module trees, so it stays `cue fmt` clean.

### The contract page is the landing, at `docs/catalogs/opm/_index.md`

`docs/catalogs/` holds pages that ship only in a bundle; `docs/site/` keeps holding pages opmodel.dev reads through git for a site version. The landing is `docs/site/reference/catalog-contract.md` with:

- front matter `title: The Catalog Contract` and the same `description`; no `type` (an `_index.md` declares none, docs-kit C11) and no `weight`;
- the body unchanged, except a new `## Catalog members` section before "See also" that names the module (`opmodel.dev/catalogs/opm@v4`) and links the three kind indexes as `/catalogs/opm/4/blueprints/`, `/catalogs/opm/4/resources/` and `/catalogs/opm/4/traits/`. The authored landing replaces the generated one (docs-kit C6), and without this section the landing would link none of the pages under it. The `markdown` source rewrites those links to the build's own segment (`/catalogs/opm/4.4/...`, `/catalogs/opm/edge/...`, docs-kit C8);
- the two "See also" links (`/docs/reference/registry-namespaces/`, `/docs/reference/cli/`) unchanged: a `/docs/` link from a tab page resolves in the site's default version (docs-kit C8).

`docs/site/reference/catalog-contract.md` stays until section 3, because the site's Reference shows it until the Catalogs tab is live. Section 1 marks it with an HTML comment on the line after its front matter ("Moved to `docs/catalogs/opm/_index.md`; edit there. This copy is deleted when publish-docs-bundle section 3 lands.") and moves the four "Check against" pointers in `docs/site/extending/` to the new path. Section 3 moves the two pointers to `catalog-members/` in `docs/site/authoring/` to `catalog_opm/opm/INDEX.md`, the generated index that stays in git.

### `docs.yml`: check, edge and the release backfill

A new workflow, so the existing `CI` and `Release` workflows keep their names, triggers and required checks:

```yaml
name: Docs
on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      mode:
        description: release only, until docs-kit add-docs-revisions adds revision
        type: choice
        options: [release]
        required: true
      tag:
        description: An opm release tag with no docs bundle yet (opm-v4.4.5)
        type: string
        required: true
permissions: {}
jobs:
  check:
    if: github.event_name == 'pull_request'
    permissions: {contents: read, packages: read}
    uses: open-platform-model/docs-kit/.github/workflows/publish.yml@v0.1.0
    with: {project: catalog-opm, mode: check}
  edge:
    if: github.event_name == 'push'
    permissions: {contents: read, packages: write, id-token: write}
    uses: open-platform-model/docs-kit/.github/workflows/publish.yml@v0.1.0
    with: {project: catalog-opm, mode: edge}
  release:
    if: github.event_name == 'workflow_dispatch'
    permissions: {contents: read, packages: write, id-token: write}
    uses: open-platform-model/docs-kit/.github/workflows/publish.yml@v0.1.0
    with: {project: catalog-opm, mode: "${{ inputs.mode }}", tag: "${{ inputs.tag }}"}
```

One project, so no matrix. The dispatch's `mode` offers `release` only: it is the backfill and the recovery path for a release whose `publish-docs` job did not run, and the `revision` choice is added later without renaming anything (docs-kit `orchestration.md`, "Follow-up: docs-kit add-docs-revisions"). It MUST be dispatched on `main` (`gh workflow run docs.yml --ref main -f mode=release -f tag=opm-v4.4.5`); `publish.yml` refuses any other ref. `cue-registry` keeps its default (`opmodel.dev=ghcr.io/open-platform-model,registry.cue.works`), the value `ci.yml` uses.

### `release.yml`: `publish-docs` after `publish-cue`, only for an opm release

release-please sets `opm--tag_name` (the job's `opm_tag_name` output) only when it released `opm` in this run, so the job's condition is that output being non-empty.

```yaml
publish-docs:
  name: Publish the opm docs bundle
  needs: [release-please, publish-cue]
  if: needs.release-please.outputs.opm_tag_name != ''
  permissions: {contents: read, packages: write, id-token: write}
  uses: open-platform-model/docs-kit/.github/workflows/publish.yml@v0.1.0
  with:
    project: catalog-opm
    mode: release
    tag: ${{ needs.release-please.outputs.opm_tag_name }}
```

- It runs in the run the release-PR merge starts, on `refs/heads/main`, which docs-kit C5 and C9 require. A `release: published` trigger would run on the tag ref and be refused, and is not used.
- `needs: publish-cue` without `always()` means a bundle is published only when every released module published: the reference never describes a version GHCR does not serve. While the `k8s` catalog still exists, a failed `k8s` leg skips this job; the recovery is the `docs.yml` dispatch with `opm_tag_name`.
- No version is passed: docs-kit C5 has no version input, and `opm-docs` reads the version from the tag through the `opm-v` prefix.
- `release.yml`'s workflow-level permissions do not include `id-token`; the job-level block grants what docs-kit C5 asks and nothing more.

### A pinned `opm-docs` binary, never `go run`

`.opm-docs-version` holds one line, the docs-kit release tag (`v0.1.0`), beside `.opm-cli-version`. `.tasks/opm-docs.sh` installs that release's `opm-docs_<version>_<os>_<arch>.tar.gz` to `.bin/opm-docs` (gitignored) after checking it against the release's `checksums.txt`, and reuses an installed binary whose `opm-docs version` matches. The tasks:

| Task | Runs |
| --- | --- |
| `docs:bundle` | `opm-docs build --project catalog-opm --out out` (a local preview; `out/` is gitignored; opmodel.dev reads it with `--local catalog-opm=<this repo>/out/catalog-opm`, docs-kit C7) |
| `docs:bundle:check` | the pin check, then `opm-docs check --project catalog-opm` |

The pin check refuses unless every `open-platform-model/docs-kit/.github/workflows/publish.yml@` reference under `.github/workflows/` names the version in `.opm-docs-version`: a workflow `uses:` ref cannot be read from a file, so two pins exist and the check keeps them equal. It reads the version from the ref (`@v0.1.0`) or, if docs-kit's review settles on SHA pinning (docs-kit C5, "Known conflict"), from the comment after the SHA (`@<40 hex> # v0.1.0`); every `uses:` snippet in this design then takes that form and nothing else here changes. `task check` runs `docs:bundle:check`, so a section gate catches a member the bundle build refuses (a doc comment that does not open with its description, a page that fails the dialect) before the PR's `Docs / check` does. `ci.yml` does not run it; `Docs / check` is the PR gate.

### Docs revisions are left to `add-docs-revisions`

docs-kit plans revisions as its own change, released as `v0.2.0`. Its `orchestration.md` names catalog_opm's part as a `ci` PR with no OpenSpec change: `.opm-docs-version` and the `publish.yml@` refs move to `v0.2.0`, and the dispatch gains the `revision` choice and a `fix` input. Planning that here as a gated section would keep this change active on `main` for an unscheduled dependency, and the pin bump belongs with the release that brings the mode.

### What section 3 removes

| File | Removed |
| --- | --- |
| `tools/refgen/` | the whole Go module |
| `docs/site/reference/catalog-members/`, `docs/site/reference/catalog-contract.md` | the committed pages and the moved contract copy |
| `Taskfile.yml` | `generate:reference`, `generate:reference:check`, `test:refgen`, their `check` entries, the `## Site reference` comment block; `check`'s `desc` reworded |
| `ci.yml` | `Setup Go`, "Test the reference generator", "Verify the generated site reference is up to date" |
| `branch-publish.yml` | `Setup Go` (its `task check` needs no Go: `opm-docs` is a binary) |
| `release.yml`, job `release-please` | `Setup Go`, `Install Task`, `task generate:reference`, `docs/site/reference` in `git add`, and the `git status --porcelain -- docs/site/reference` test, so the step reads `if git diff --quiet; then`. The GHCR login goes too unless `opm catalog version set` needs a registry: the implementer runs it on a scratch checkout with no credentials and records the result in the section's commit body |

`vet:descriptions` stays: the summary rule now feeds the bundle. Its `desc` and `.tasks/description-check.sh`'s header stop saying "generated site reference" and say the published catalog reference. `docs/site/reference/kubernetes-resources.md` belongs to the `k8s` removal (gate G3); section 3 deletes it only if that change left it.

## Research & Decisions

### Where the release bundle is published
**Context**: A release bundle must be signed on `refs/heads/main` (docs-kit C9) and must not describe a version GHCR does not serve.
**Explored**: `release: published` (the release App's token does fire it, but its `github.ref` is the tag, which `publish.yml` refuses); a matrix over `paths_released` mapping `<module>` to `catalog-<module>` (the first draft of docs-kit's `orchestration.md`, which would call `publish.yml` for a `catalog-k8s` project this repository does not declare); one job gated on `opm` being released, as the amended `orchestration.md` also has it.
**Decision**: One `publish-docs` job in `release.yml`, `needs: [release-please, publish-cue]`, gated on a non-empty `opm_tag_name`.
**Rationale**: Same run, `main` ref, after the module is on GHCR; correct whether or not the `k8s` catalog still exists.

### How `task check` gets `opm-docs`
**Context**: docs-kit's `orchestration.md` sketches `go run github.com/open-platform-model/docs-kit/cmd/opm-docs@v0.1.0`.
**Explored**: `go run` needs a Go toolchain at docs-kit's `go` directive (1.26) on every machine and in `branch-publish.yml` (which runs `task check`) forever, and builds the tool from source instead of running the binary `publish.yml` runs. A checksum-verified release download is how this repository already installs `opm`.
**Decision**: `.opm-docs-version` plus `.tasks/opm-docs.sh`, as above.
**Rationale**: The local check runs the bytes CI runs, and section 3 can drop Go entirely.

### Moving the contract page before the generator goes
**Context**: The site's Reference reads `docs/site/` from `main`, so deleting the contract page in section 1 would remove it from the site before the Catalogs tab exists.
**Explored**: Move in section 1 (a gap on the site), copy in section 1 and delete in section 3 (two copies for a window), a symlink (the dialect refuses symlinks, docs-kit C11).
**Decision**: Copy in section 1, mark the old copy as moved, delete it in section 3.
**Rationale**: No reader loses the page, and the comment stops an edit landing in the copy that is about to go.

## Risks / Trade-offs

- [The backfill of `opm-v4.4.5` builds a tree cut before `docs/catalogs/opm/` existed, and docs-kit C5 says only that `main`'s `docs-kit.cue` is used, not where a `markdown` source's `dir` resolves] -> This plan expects docs-kit to resolve sources against the release tree and to treat a directory that tree lacks as no pages, so `4.4.5.0` carries the generated landing and the contract landing reaches 4.4 with the next opm release. Section 2 records what the backfill produced. If docs-kit refuses instead, 4.4 first appears with the next opm release, and docs-kit DESIGN decision 8 waits for it.
- [docs-kit C5 serializes one project's publishes in one concurrency group with `cancel-in-progress: false`, but GitHub keeps at most one pending run per group and cancels the older pending one when a third arrives; a release-PR merge queues `Docs / edge` and `Release / publish-docs` in the same group] -> A cancelled release publish is recovered by the `docs.yml` dispatch; `AGENTS.md` says so. Raised with docs-kit as a contract gap.
- [The contract text exists twice between sections 1 and 3] -> The old copy carries a "moved" comment, and gate G3 keeps the window to the opmodel.dev and cli merges.
- [Two docs-kit pins (`.opm-docs-version` and the `publish.yml@` refs)] -> `docs:bundle:check` refuses a mismatch; a bump changes both in one PR, which needs the Workflows permission the release cascade bot lacks.
- [`task check` downloads a binary on first run] -> cached in `.bin/`; every gate here already needs the network for the CUE registry.
- [This PR's `Docs / check` is the first real run of `publish.yml`] -> A failure there is a docs-kit defect: report it to docs-kit, never work around it in this repository.
- [After section 3, a doc-comment fix reaches a released minor only through a docs revision, which does not exist until `add-docs-revisions`; a doc comment change is a `docs:` commit and releases nothing] -> `edge` shows the fix at once. Until revisions ship, a released minor's page keeps its text until the next opm release.
- [The package is private after the first push, and every site pull fails until the owner makes it public] -> Section 2 is the owner's step, and opmodel.dev `add-catalogs-tab` merges only after it.

## Durable decisions

- `docs/catalogs/opm/` holds pages that ship only in the docs bundle; `docs/site/` holds pages opmodel.dev reads for a site version: `AGENTS.md`, Repository Layout and a new "Docs bundles" subsection under Release & publishing (section 1).
- What publishes when (`edge` on every push to `main`, `<version>.0` from `release.yml` after `publish-cue`, the `docs.yml` dispatch as backfill and recovery), how to preview (`task docs:bundle`, opmodel.dev's `--local`), and that `.opm-docs-version` and the `publish.yml@` refs move together: `AGENTS.md`, "Docs bundles" (section 1).
- The catalog reference is published by docs-kit and never committed; the doc-comment rules that shape it (description first, `// WHY` blocks and banners dropped, citations stripped, marks and enforcement derived) are enforced by `opm-docs build` and documented in docs-kit: `AGENTS.md` (Purpose, Repository Layout, Dependencies, the commands table, Release & publishing, Working Style) and `openspec/config.yaml` (context and Principle II) (section 3).
- The digests and tags of the first published bundles, and what the 4.4.5 backfill's landing was: stays with the change (section 2).
