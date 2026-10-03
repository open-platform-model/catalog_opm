## Context

Today `tools/refgen` (own `go.mod`, `cuelang.org/go` v0.17.1) loads both catalog modules and writes `docs/site/reference/catalog-members/` (one page per `opm` blueprint, resource and trait), the generated block of `catalog-members/_index.md`, and the table in `docs/site/reference/kubernetes-resources.md`. `task generate:reference:check` and `task test:refgen` run in `task check` and in `ci.yml`; `release.yml`'s identity advance runs `task generate:reference` on every release PR, because every page carries `identity.Version`. Three workflows install Go only for refgen (`ci.yml`, `branch-publish.yml`, `release.yml`). opmodel.dev's v1.0 version reads this repository's `docs/site/` from `main` while `main` still releases opm 4.x (opmodel.dev `site/versions.conf`), so a file deleted on `main` leaves the site at its next build.

The authored contract page is `docs/site/reference/catalog-contract.md` (title "The Catalog Contract", `type: reference`, `weight: 5`). No page links the contract page; it is named only by maintainer "Check against" pointers inside HTML comments in `docs/site/extending/` (four). The member pages are linked by `docs/site/reference/kubernetes-resources.md` (lines 8 and 51, to `/docs/reference/catalog-members/`), which the `k8s` removal deleted (3f9d6fd), and named by two "Check against" pointers in `docs/site/authoring/`; `catalog-members/_index.md` links `kubernetes-resources.md` and goes in section 3. Outside this repository only cli's `docs/site/reference/registry-namespaces.md` links `/docs/reference/catalog-contract/`.

Contracts this change consumes, from docs-kit's change `build-opm-docs-phase-1` (`design.md`):

- **docs-kit C1**: the bundle lives at `ghcr.io/open-platform-model/docs/catalog-opm`, placement tab, root `/catalogs/opm/`, release tag prefix `opm-v`.
- **docs-kit C4**: full tags `<version>.<revision>` are immutable; the release, minor and major tags (`<version>`, `<MAJOR>.<MINOR>`, `<MAJOR>`) and `edge` move; edge builds carry no full tag.
- **docs-kit C5**: callers pin `publish.yml` by tag (`@v0.1.0`), declare no secrets, and grant per mode: `check` needs `contents: read`, `packages: read`; `edge` and `release` need `contents: read`, `packages: write`, `id-token: write`. Every mode but `check` refuses unless `github.ref` is `refs/heads/main`. `release` runs from the job that runs release-please, gated on that package's release, or by `workflow_dispatch` for a release with no bundle yet. A release cut before the repository had `docs-kit.cue` builds with `main`'s, and its sources resolve against the release tree: a `markdown` directory that tree lacks yields no pages. `publish.yml` declares no `permissions` of its own: the caller's job grants them, and one `docs` job runs every mode. Edge and release publishes run in separate concurrency groups (`docs-edge-<project>`, `docs-release-<project>-<tag>`). `publish.yml` has no version input: it reads the caller's repo-root `.opm-docs-version` (one line, `v0.1.0`) from the checked-out caller tree (`main`'s in release mode), installs that checksum-verified `opm-docs` release, and logs in to GHCR itself for the extractors' CUE dependencies, so a caller adds no login step.
- **docs-kit C6**: `docs-kit.cue` at the repository root, `bundles` keyed by project; a root `_index.md` from a `markdown` source replaces the generated landing's text, and the renderer appends its generated "Catalog members" block (module path, version or edge commit, each kind index with its count) after the authored body.
- **docs-kit C8, C11**: page paths and link forms. An authored bundle page links into its own catalog through the major alias (`/catalogs/opm/4/<path>/`), which the `markdown` source rewrites to the build's own segment; `/docs/<section>/<page>/` links from a tab page resolve in the site's default version; an `_index.md` declares no `type`.
- **docs-kit C9**: the signature's Source Repository Ref must be `refs/heads/main`, so no bundle is published from a release branch or a tag ref (docs-kit DESIGN decision 9); the signer is `publish.yml` at a ref matching `refs/tags/v[0-9]*`, which is why callers pin it by docs-kit release tag.
- **Re-read 2026-10-03 against docs-kit `main` (5f3eab4), before `v0.1.0` was tagged.** Three amendments since this plan was written are folded in above: `publish.yml` reads `.opm-docs-version` (no version literal of its own), declares no permissions, and keys the release concurrency group on the tag. A fourth changes section 2: the GHCR spike created its new package **public** (it took the visibility of the public repository it is linked to, docs-kit C2), so go-live verifies the visibility rather than setting it. docs-kit C1 and C6 still show the module at `./opm`; this repository moved it to `src/` (`retire-k8s-catalog`), so `docs-kit.cue` names `./src`. Nothing else differs; `v0.1.0` (4f3f72a) was tagged later the same day with these contracts unchanged.

No member file, `apiVersion` segment, definition, default, closedness or required-field set is touched. The only files under a module root that any section reads are the ones `opm-docs` evaluates.

## Goals / Non-Goals

**Goals:**

- Every push to `main` publishes a signed `edge` bundle of the opm catalog; every opm release publishes `<version>.0` in the same workflow run that publishes the CUE module.
- Every pull request runs `opm-docs check`; `task check` runs the same check locally with the same tool version CI uses.
- The authored contract page is the bundle's landing.
- After section 3, nothing under this repository generates or commits reference pages, and no workflow installs Go for the reference. (Amended at section 3: `tools/kindgen`, added by `feat(resources): add the objects resource` (#118) after this plan was written, is Go and its tests run in `task check`, so `ci.yml` and `branch-publish.yml` keep `Setup Go`, now read from `tools/kindgen/go.mod`; only `release.yml` drops Go.)

**Non-Goals:**

- A `catalog-k8s` bundle. The `k8s` catalog was removed from this repository by another change (`retire-k8s-catalog`, 3f9d6fd).
- Docs revisions. Their dispatch belongs to docs-kit's change `add-docs-revisions` (Decisions, "Docs revisions are left to add-docs-revisions"). It landed outside this change, as planned there: `ci(docs): adopt docs-kit v0.2.0` (#126) moved both pins to `v0.2.0` and gave the dispatch the `revision` mode and the `fix` input.
- Any edit to opmodel.dev, cli, docs-kit or the workspace repository.
- Redirects from the old Reference URLs. There are none (decided): the opmodel.dev build that gains the tab stops mounting the old pages and maps links to them onto the tab's alias forms.

## Decisions

### One bundle, declared at the repository root

`docs-kit.cue` is docs-kit C6's example with the `catalog-k8s` entry dropped:

```cue
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

It sits outside the module root, so `cue` run from `src/` never loads it and `opm catalog publish ./src` never ships it, and it changes no release-please package (its commit touches no file under `src/`). It carries no `package` clause, as docs-kit C6 shows it. `task fmt` and `task fmt:check` MUST format and diff it alongside the module trees, so it stays `cue fmt` clean.

### The contract page is the landing, at `docs/catalogs/opm/_index.md`

`docs/catalogs/` holds pages that ship only in a bundle; `docs/site/` keeps holding pages opmodel.dev reads through git for a site version. The landing is `docs/site/reference/catalog-contract.md` with:

- front matter `title: The Catalog Contract` and the same `description`; no `type` (an `_index.md` declares none, docs-kit C11) and no `weight`;
- the body unchanged, with no hand-written members section: the renderer appends the generated `## Catalog members` block after the authored body (docs-kit C6, C8, "Page renderer"), so the landing links the kind indexes with the build's own segment and counts. The build refuses an authored landing that already holds a `## Catalog members` heading;
- the two "See also" links (`/docs/reference/registry-namespaces/`, `/docs/reference/cli/`) unchanged: a `/docs/` link from a tab page resolves in the site's default version (docs-kit C8).

`docs/site/reference/catalog-contract.md` stays until section 3, because the site's Reference shows it until the Catalogs tab is live. Until then `docs:bundle:check` (`.tasks/opm-docs.sh contract-sync`) refuses the two copies' bodies differing, front matter and the "moved" comment ignored, naming both files. Section 1 marks it with an HTML comment on the line after its front matter ("Moved to `docs/catalogs/opm/_index.md`; edit there. This copy is deleted when publish-docs-bundle section 3 lands.") and moves the four "Check against" pointers in `docs/site/extending/` to the new path. Section 3 moves the two pointers to `catalog-members/` in `docs/site/authoring/` to `catalog_opm/src/INDEX.md`, the generated index that stays in git.

### `docs.yml`: check, edge and the release recovery dispatch

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
        description: An opm release tag whose publish-docs job did not run (opm-vX.Y.Z)
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
  dispatch:
    if: github.event_name == 'workflow_dispatch'
    permissions: {contents: read, packages: write, id-token: write}
    uses: open-platform-model/docs-kit/.github/workflows/publish.yml@v0.1.0
    with: {project: catalog-opm, mode: "${{ inputs.mode }}", tag: "${{ inputs.tag }}"}
```

One project, so no matrix. The dispatch's `mode` offers `release` only: it is the recovery path for a release whose `publish-docs` job did not run, never a backfill (owner decision, 2026-10-03: the tab starts at the first opm release after section 1 merges), and the `revision` choice is added later without renaming anything (docs-kit `orchestration.md`, "Follow-up: docs-kit add-docs-revisions"). It MUST be dispatched on `main` (`gh workflow run docs.yml --ref main -f mode=release -f tag=opm-vX.Y.Z`); `publish.yml` refuses any other ref. `cue-registry` keeps its default (`opmodel.dev=ghcr.io/open-platform-model,registry.cue.works`), the value `ci.yml` uses.

### `release.yml`: `publish-docs` after `publish-cue`, only for an opm release

`publish-cue` runs only when release-please released `opm` in this run, and sets an output `published=true` right after "Publish CUE catalog", before its non-gating "Verify the published build" step. The job's condition is that output, under `always()`, so a failed verification (an aid, not a gate, 0011 D7) does not skip the docs while a failed or skipped publish does. The tag comes from release-please's `src--tag_name` (the job's `opm_tag_name` output; the package path is `src`, the component `opm`).

```yaml
publish-docs:
  name: Publish the opm docs bundle
  needs: [release-please, publish-cue]
  if: always() && needs.publish-cue.outputs.published == 'true'
  permissions: {contents: read, packages: write, id-token: write}
  uses: open-platform-model/docs-kit/.github/workflows/publish.yml@v0.1.0
  with:
    project: catalog-opm
    mode: release
    tag: ${{ needs.release-please.outputs.opm_tag_name }}
```

- It runs in the run the release-PR merge starts, on `refs/heads/main`, which docs-kit C5 and C9 require. A `release: published` trigger would run on the tag ref and be refused, and is not used.
- Gating on `published` means a bundle is published only when the module reached GHCR: the reference never describes a version GHCR does not serve. The `k8s` catalog, whose failed leg could once have skipped this job, was retired in 3f9d6fd (`retire-k8s-catalog`), so `publish-cue` publishes the one module. When this job does not run, the recovery is the `docs.yml` dispatch with `opm_tag_name`.
- No version is passed: docs-kit C5 has no version input, and `opm-docs` reads the version from the tag through the `opm-v` prefix.
- `release.yml`'s workflow-level permissions do not include `id-token`; the job-level block grants what docs-kit C5 asks and nothing more.

### A pinned `opm-docs` binary, never `go run`

docs-kit C12 fixes this for callers: the local tool is the checksum-verified release binary named by a repo-root `.opm-docs-version`, installed into a gitignored repo-local directory, never `go run` or `go install`.

`.opm-docs-version` holds one line, the docs-kit release tag (`v0.1.0`), beside `.opm-cli-version`; `publish.yml` reads the same file in CI (docs-kit C5), so the local tool and CI run the same release. `task tools:opm-docs` (its script in `.tasks/opm-docs.sh`) downloads that release's `opm-docs_<version>_<os>_<arch>.tar.gz` and `checksums.txt`, checks the archive with `grep ' <archive>$' checksums.txt | sha256sum -c -` (refusing an archive with no line), extracts only `opm-docs` to `.bin/opm-docs` (gitignored), and reuses an installed binary whose `opm-docs version` matches. A failed check stops the task; nothing builds from source (docs-kit C12). The tasks:

| Task | Runs |
| --- | --- |
| `tools:opm-docs` | install or reuse `.bin/opm-docs` as above |
| `docs:bundle` | depends on `tools:opm-docs`; `opm-docs build --project catalog-opm --out out` (a local preview of `main` as the edge segment; `out/` is gitignored; opmodel.dev reads it with `--local catalog-opm@edge=<this repo>/out/catalog-opm`, docs-kit C7's `<project>@<segment>=<dir>`) |
| `docs:pins:check` | the pin check, offline; `ci.yml`'s `Validate catalog` runs it too |
| `docs:bundle:check` | depends on `tools:opm-docs`; `docs:pins:check`, the contract-copy body comparison (until section 3), then `opm-docs check --project catalog-opm` |

The pin check refuses unless every `open-platform-model/docs-kit/.github/workflows/publish.yml@` reference under `.github/workflows/` names the version in `.opm-docs-version`: a workflow `uses:` ref cannot be read from a file, so two pins exist and the check keeps them equal. Callers pin `publish.yml` by tag (owner decision, docs-kit C5), so the check reads the version from the ref (`@v0.1.0`). `task check` runs `docs:bundle:check`, so a section gate catches a member the bundle build refuses (a doc comment that does not open with its description, a page that fails the dialect) before the PR's `Docs / check` does. `ci.yml` runs only the offline `docs:pins:check` from it; `Docs / check` is the PR gate for the bundle build.

### Docs revisions are left to `add-docs-revisions`

docs-kit plans revisions as its own change, released as `v0.2.0`. Its `orchestration.md` names catalog_opm's part as a `ci` PR with no OpenSpec change: `.opm-docs-version` and the `publish.yml@` refs move to `v0.2.0`, and the dispatch gains the `revision` choice and a `fix` input. Planning that here as a gated section would keep this change active on `main` for an unscheduled dependency, and the pin bump belongs with the release that brings the mode.

### What section 3 removes

| File | Removed |
| --- | --- |
| `tools/refgen/` | the whole Go module |
| `docs/site/reference/catalog-members/`, `docs/site/reference/catalog-contract.md` | the committed pages and the moved contract copy |
| `Taskfile.yml` | `generate:reference`, `generate:reference:check`, `test:refgen`, their `check` entries, the `## Site reference` comment block; `check`'s `desc` reworded |
| `ci.yml` | "Test the reference generator", "Verify the generated site reference is up to date"; `Setup Go` stays for `test:kindgen`, read from `tools/kindgen/go.mod` (amended at section 3) |
| `branch-publish.yml` | nothing removed: its `task check` runs `test:kindgen`, so `Setup Go` stays, read from `tools/kindgen/go.mod` (amended at section 3) |
| `release.yml`, job `release-please` | `Setup Go`, `Install Task`, `task generate:reference`, `docs/site/reference` in `git add`, and the `git status --porcelain -- docs/site/reference` test, so the step reads `if git diff --quiet; then`. The GHCR login goes too unless `opm catalog version set` needs a registry: the implementer runs it on a scratch checkout with no credentials and records the result in the section's commit body. Result (2026-10-03, opm `v1.0.0-beta.4`, the `.opm-cli-version` pin): with an empty `HOME` and `DOCKER_CONFIG` and `OPM_REGISTRY`/`CUE_REGISTRY` at an unreachable `localhost:1`, it rewrote `Version` and exited 0, so the login goes |
| `.tasks/opm-docs.sh`, `docs:bundle:check` | the `contract-sync` mode and its call: one contract copy remains |

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
**Decision**: `.opm-docs-version` plus `task tools:opm-docs`, as above; raised with docs-kit and adopted there as contract C12 (supervisor, 2026-10-02).
**Rationale**: The local check runs the bytes CI runs, and section 3 can drop Go entirely.

### Moving the contract page before the generator goes
**Context**: The site's Reference reads `docs/site/` from `main` until opmodel.dev's `add-catalogs-tab` stops mounting the catalog pages, so deleting the contract page in section 1 would remove it from the site before the Catalogs tab exists.
**Explored**: Move in section 1 (a gap on the site), copy in section 1 and delete in section 3 (two copies in git for a window, one on the site at any time), a symlink (the dialect refuses symlinks, docs-kit C11).
**Decision**: Copy in section 1, mark the old copy as moved, delete it in section 3.
**Rationale**: No reader loses the page, and the comment stops an edit landing in the copy that is about to go.

## Risks / Trade-offs

- [The Catalogs tab has no released minor until the first opm release after section 1 merges] -> Owner decision (2026-10-03): no backfill. Every existing tag, up to and including `opm-v4.5.0`, has the module at `opm/`, not `src/`, and none has a `docs-kit.cue`, so a release build of it would take `main`'s config and find no `./src` in the release tree. Until that release the tab shows only `edge`; section 2 waits for it and verifies it.
- [The recovery dispatch is given a tag cut before section 1] -> It fails for the same reason; the dispatch is for releases cut after section 1 only, which `AGENTS.md` says.
- [`Release / publish-docs` does not run or fails (a failed `publish-cue` leg, a registry outage)] -> The `docs.yml` dispatch publishes the release that has no bundle; `AGENTS.md` says so.
- [The contract text exists twice in git between sections 1 and 3] -> The site shows only one of them at any time (the Reference copy until opmodel.dev's merge, the bundle landing after it); the old copy carries a "moved" comment, and gate G3 ends the window.
- [Two docs-kit pins (`.opm-docs-version` and the `publish.yml@` refs)] -> `docs:bundle:check` refuses a mismatch; a bump changes both in one PR, which needs the Workflows permission the release cascade bot lacks.
- [`task check` downloads a binary on first run] -> cached in `.bin/`; every gate here already needs the network for the CUE registry.
- [This PR's `Docs / check` is the first real run of `publish.yml`] -> A failure there is a docs-kit defect: report it to docs-kit, never work around it in this repository.
- [After section 3, a doc-comment fix reaches a released minor only through a docs revision, which does not exist until `add-docs-revisions`; a doc comment change is a `docs:` commit and releases nothing] -> `edge` shows the fix at once. Until revisions ship, a released minor's page keeps its text until the next opm release.
- [The package is private after the first push, and every site pull fails until the owner makes it public] -> docs-kit's GHCR spike saw a new package created public, inheriting the linked public repository's visibility (docs-kit C2), so this is not expected; section 2 verifies the visibility anonymously and the owner flips it only if it came out private. opmodel.dev `add-catalogs-tab` merges only after section 2.

## Durable decisions

- `docs/catalogs/opm/` holds pages that ship only in the docs bundle; `docs/site/` holds pages opmodel.dev reads for a site version: `AGENTS.md`, Repository Layout and a new "Docs bundles" subsection under Release & publishing (section 1).
- What publishes when (`edge` on every push to `main`, `<version>.0` from `release.yml` after `publish-cue`, the `docs.yml` dispatch for release recovery, never a backfill, and, since docs-kit `v0.2.0` (#126), for docs revisions of a published release), how to preview (`task docs:bundle`, then opmodel.dev's `--local catalog-opm@edge=<this repo>/out/catalog-opm`), and that `.opm-docs-version` and the `publish.yml@` refs move together: `AGENTS.md`, "Docs bundles" (section 1).
- The catalog reference is published by docs-kit and never committed; the doc-comment rules that shape it (description first, `// WHY` blocks and banners dropped, citations stripped, marks and enforcement derived) are enforced by `opm-docs build` and documented in docs-kit: `AGENTS.md` (Purpose, Repository Layout, Dependencies, the commands table, Release & publishing, Working Style) and `openspec/config.yaml` (context and Principle II) (section 3).
- The digests and tags of the first published bundles (the first `edge` and the first release): stays with the change (section 2).

## Rollout record

Section 2, verified 2026-10-03 against `ghcr.io/open-platform-model/docs/catalog-opm` with no registry credentials. Every bundle below was built by `opm-docs` 0.1.0 at revision `0`, and its landing `_index.md` is the authored contract page (`source: docs/catalogs/opm/_index.md`, `generated: false`).

- **Package.** Created public by the first push and linked to `open-platform-model/catalog_opm` (docs-kit C2); no owner action was needed.
- **First `edge`.** Docs run 37104102042, the push of `fc4ff72` (#121, section 1's merge). `edge` named `sha256:ff9aa21fdb563de3cbd6f4f595881977d24659e74825ee8a63dc29896963b3d1`, built from `fc4ff72f94e6e3adf563caba413b384b12309fca`. `cosign verify` with the docs-kit C9 flags passes for it, and `opm-docs pull` (v0.1.0) with a scratch `bundles.cue` resolved, verified and unpacked it.
- **First release, opm 4.5.1.** Owner decision: forced as a patch so the tab gets a released minor without waiting for a catalog change. #122 set `release-as: 4.5.1`; release-please still reported no user-facing commits, because `release-as` alone does not override that, so #123 landed a user-facing `fix(catalog)`; #124 released `opm-v4.5.1` (`f13ccf1d9d36be323fa97b97c6c778036b15816e`); #125 removed the `release-as` pin. Release run 37104462834's `Publish the opm docs bundle` job succeeded.
- **Release tags.** `4.5.1.0`, `4.5.1`, `4.5` and `4` all name `sha256:1d131ea45aeb07a4bff4593b0e033d7a9a3f21ba28fa5d81508b7db60e3bdaaa`, built from `f13ccf1d9d36be323fa97b97c6c778036b15816e` (`source.ref: opm-v4.5.1`). `cosign verify` with the C9 flags passes for it, and an anonymous `opm-docs pull` with the tab's `from` at `4.5` resolved, verified and unpacked segment `4.5` as 4.5.1 revision `0` together with `edge`.
- **`edge` at the release.** Docs run 37104462855, the push of `f13ccf1`, moved `edge` to `sha256:2d7cdc483e98edacebbbe67c571160977ea069bd786dcf0b903cd6ad011b6dbf`, built from the same commit; `cosign verify` passes for it. `edge` has moved with every push since, so it names a later digest today.
