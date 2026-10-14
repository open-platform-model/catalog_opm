# Docs bundles, doc comments and descriptions

Covers the two docs bundles, what publishes when, how to recover or revise a release's docs, the docs-kit pin, and the doc-comment and `metadata.description` rules that shape the published catalog reference.

## The two bundles

- `docs-kit.cue` declares two bundles, both versioned by the same `opm-v` release tags (docs-kit `docs/contracts.md`, C1 and C15).
- `catalog-opm` is the Catalogs tab. The `cue-catalog` extractor runs over `./src` (one page per blueprint, resource and trait, plus the kind indexes). The authored pages under `docs/catalogs/opm/` join it. It publishes to `ghcr.io/open-platform-model/docs/catalog-opm`.
- `catalog-opm-docs` holds the authored pages under `docs/site/`, placed in a site version's `/docs/` tree. It publishes to `ghcr.io/open-platform-model/docs/catalog-opm-docs`. It owns no path (nothing generates into it), and each page links "Edit this page" to its file on `main` (`pages[].edit`). opmodel.dev reads this bundle (`v1.0` takes tag `4`), not git.
- docs-kit's reusable `publish.yml` builds, lints, signs and publishes each one. Every job in `docs.yml` and `release.yml` runs once per project (a matrix with `fail-fast: false`).
- `docs/catalogs/opm/` holds pages that ship only in the tab bundle. `docs/catalogs/opm/_index.md` is its landing (the Catalog Contract): front matter `title` and `description` only, and no `## Catalog members` heading, because `opm-docs` appends that generated block. A link from it into the catalog uses the major alias (`/catalogs/opm/4/<path>/`), which the build pins to its own segment.
- The catalog reference is never written by hand or committed here. `docs-kit.cue`, `docs/` and `.opm-docs-version` sit outside the module root, so none of them ships in the published module.

## What publishes when

- `docs.yml` runs `check` for both projects on every pull request and publishes both at `edge` on every push to `main`.
- `release.yml`'s `publish-docs` job publishes both at `<version>.0` from the same release tag, after `publish-cue`, only when release-please released `opm`. The first `catalog-opm-docs` release bundle comes with the next opm release after the project joined `docs-kit.cue`.
- The `docs.yml` dispatch names its bundle with `-f project=catalog-opm` or `-f project=catalog-opm-docs` (required on the CLI; the web UI preselects `catalog-opm`). Both modes run on `main` only, because `publish.yml` refuses any other ref.
- `release` recovers a release whose `publish-docs` job did not run (a failed `publish-cue`, an outage): `gh workflow run docs.yml --ref main -f project=<project> -f mode=release -f tag=opm-vX.Y.Z`. It is recovery only, never a backfill. Releases cut before this repo had `docs-kit.cue` (up to `opm-v4.5.0`, module at `opm/`) have no bundle and get none (owner decision, 2026-10-03). `catalog-opm-docs` is never backfilled. Those tags would build with `main`'s config (docs-kit C5) and publish the retired reference pages under `docs/site/reference/`. The `guard` job in `docs.yml` therefore refuses a `catalog-opm-docs` dispatch unless the tag's own `docs-kit.cue` declares the project. `opm-v4.5.1`, whose `docs-kit.cue` names just `catalog-opm`, would fail that guard.
- `revision` publishes a docs revision of a release that already has a bundle. Land the fix on `main` as one single-parent commit that changes only Markdown, or only comments in `.cue` files. Then run `gh workflow run docs.yml --ref main -f project=<project> -f mode=revision -f tag=opm-vX.Y.Z -f fix=<full 40-hex sha>`. It publishes `<version>.<next>` with every earlier fix of that release plus this one. It refuses a fix not on `main`, one already applied, a conflict, and any change to code (docs-kit README, "Fixing a release's docs"; `docs/contracts.md`, "Docs revisions"). A doc-comment fix that needs a value change (a `metadata.description`, a default) is a `fix:` and a patch release instead.
- Docs revisions are dispatched by hand (owner decision, 2026-10-03). Automating them is open-platform-model/catalog_opm#130.
- Full tags (`<version>.<revision>`) are written once. `<version>`, `<MAJOR>.<MINOR>`, `<MAJOR>` and `edge` move by design.
- Preview with `task docs:bundle` (both bundles into `out/<project>/`). Then run opmodel.dev's build with `--local catalog-opm@edge=<this repo>/out/catalog-opm` for the tab, or `--local catalog-opm-docs@v1.0=<this repo>/out/catalog-opm-docs` for the `/docs/` pages (docs-kit C16 D6).

## The docs-kit pin

- The docs-kit release is pinned twice: `.opm-docs-version` (read by `publish.yml` in CI and by `task tools:opm-docs` locally) and every `open-platform-model/docs-kit/.github/workflows/publish.yml@vX.Y.Z` ref under `.github/workflows/`. Pin by tag, never by SHA, because the signature names that ref (docs-kit C5 and C9).
- Move both in one PR, a `ci` commit that needs the Workflows permission. `task docs:bundle:check` refuses a mismatch.
- The tool is the checksum-verified release binary, never `go run` or `go install` (docs-kit C12).
- `publish.yml` declares no permissions; the calling job grants them. `check` takes `contents: read` and `packages: read`. `edge`, `release` and `revision` take `contents: read`, `packages: write` and `id-token: write`.

## Doc comments

- Every `//` block that ends on the line directly above a field or definition is that declaration's doc comment. `cue lsp` hover, `Value.Doc()`, `cue def` and `task generate:index` replay it verbatim. One blank line ends the block, and `cue fmt` keeps that blank line.
- Tier 1, the doc comment, at most 6 lines: the contract an author needs, in this order until 6 lines are used: what it is, what it renders, what a value must satisfy, then an optional `See docs/<note>.md`.
- Tier 2, a `// WHY ...` block above the doc comment, separated from it by one blank line: rationale that must stay next to the code (measured evaluator behaviour, rendering decisions, history). The block goes above, never below the field. The blank line is load-bearing; the `WHY` prefix marks it so nobody closes the gap.
- Tier 3, `docs/<note>.md` or the enhancement entry: the full argument.
- `task docs:check` fails on every doc comment over 6 lines in the module. `.tasks/doc-check.sh` is kept byte-identical with `core`'s copy; `task docs:lint` at the workspace root checks it. `_test*` fixture fields (in `@if(fixtures)` files) are exempt; other hidden fields are not. `package` docs, `let` and comprehension clauses are not counted.
- A comment never cites an enhancement as a decision number or a lone id. `task cite-lint` checks it (see Commands in `AGENTS.md`).
- Every comment that is not a `// WHY` block or a `////` banner is published, inside the spec block or as notes. It states what the member does today. Maintainer history goes in a `// WHY` block. A published comment never points at a WHY block, because the block is not on the page. Decision citations are stripped from the page; a link to the enhancement is the renderer's, never the comment's.
- A page states only what the source proves. Marks (**Not implemented**, **Provided by your platform**) and enforcement tags are derived, never authored (workspace `STYLE.md`, "Site Pages").
- `opm-docs build` enforces the rules (docs-kit `docs/contracts.md`, "Doc-comment rules"): a member's doc comment must open with its description, or the build refuses it. A doc-comment change reaches `edge` on the next push to `main`, and a released minor through a docs revision.

## Descriptions

- Every member of the four catalog maps carries a non-blank `metadata.description`. For a resource, trait or blueprint it is the first sentence of the member's doc comment, word for word without the closing period.
- It is the member's one-line summary in the published catalog reference (workspace `STYLE.md`, "Site Pages"). It says what the member is or does, not that it is "a trait to specify" something, and never claims behaviour no transformer has.
- `task vet:descriptions` refuses a missing or blank one. `metadata.description` is on the compatibility gate's provenance denylist (enhancement 0010, provenance is excluded by a Go-side operand filter), so rewording one is never a contract change.
- `src/INDEX.md` takes the doc comment's first sentence, up to the first period, as the member's description. Its title comes from the module path, never the directory name, because it ships in the module.

## Pitfalls

- Pointing a published comment at a `// WHY` block: the block is not on the page.
- A blank line between a doc comment and its field: the comment stops being the doc comment.
- Moving only one of the two docs-kit pins.
- Dispatching `docs.yml` without `-f project=`: the CLI refuses.
- A docs revision fix that is a merge commit, touches a `.cue` value, or is not on `main`.
- Backfilling a bundle for a release cut before `docs-kit.cue` existed.
- Writing a mark such as **Not implemented** by hand: it is derived.

## Check before you finish

- [ ] `task docs:check` and `task docs:bundle:check` pass.
- [ ] A new member's `metadata.description` equals the first sentence of its doc comment.
- [ ] `task generate:index` was run and its output reviewed.
- [ ] No comment holds a decision number or a lone enhancement id.
