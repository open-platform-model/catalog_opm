**Gates.** A section starts only when its gate holds; every gate is external to this repository. Delivery is one PR per section (proposal.md), so the change stays active on `main` between PRs.

- **G1, before section 1**: docs-kit `v0.1.0` is released (the tag exists and its GitHub Release carries the `opm-docs_0.1.0_<os>_<arch>.tar.gz` archives and `checksums.txt`), and docs-kit's contracts (`docs/contracts.md` at `v0.1.0`, C1 to C11) still read as design.md "Context" quotes them.
- **G2, before section 2**: section 1 is merged, its PR's `Docs / check` run was green, and the first `Docs / edge` run on `main` is green.
- **G3, before section 3**: section 2 is done; opmodel.dev `add-catalogs-tab` is merged and `https://opmodel.dev/catalogs/opm/4/` serves the Catalogs tab; the cli link fix (`docs/site/reference/registry-namespaces.md` links `/catalogs/opm/4/`) is merged; the change that removes the `k8s` catalog from this repository is merged on `main` (no `k8s/` module).

## 1. Publish the opm docs bundle (gate G1; docs-kit.cue, docs/catalogs/, .github/, Taskfile.yml)

- [ ] 1.1 Confirm G1: `gh release view v0.1.0 -R open-platform-model/docs-kit` lists the archives and `checksums.txt`; read docs-kit's `docs/contracts.md` at `v0.1.0` and compare C1, C4, C5, C6, C8, C9 and C11 with design.md "Context". A difference in a `publish.yml` input, a permission, the config schema or a link form is fixed in design.md first; one that changes the approach stops the section and goes to the owner
- [ ] 1.2 Add `docs-kit.cue` at the repository root exactly as design.md shows (one bundle, `catalog-opm`); make `task fmt` format it and `task fmt:check` diff it with the module trees
- [ ] 1.3 Add `docs/catalogs/opm/_index.md`: the body of `docs/site/reference/catalog-contract.md`, front matter `title` and `description` only, plus the `## Catalog members` section linking `/catalogs/opm/4/blueprints/`, `/catalogs/opm/4/resources/` and `/catalogs/opm/4/traits/` (design.md, "The contract page is the landing")
- [ ] 1.4 Mark `docs/site/reference/catalog-contract.md` as moved (the HTML comment in design.md) and point the four "Check against" comments in `docs/site/extending/` (`write-a-resource.md`, `write-a-blueprint.md` twice, `write-a-trait.md`) at `catalog_opm/docs/catalogs/opm/_index.md`
- [ ] 1.5 Add `.opm-docs-version` (`v0.1.0`) and `.tasks/opm-docs.sh` (install the release archive for the host's OS and architecture into `.bin/` after the `checksums.txt` check; reuse a matching install; the pin check over `.github/workflows/`); add `docs:bundle` and `docs:bundle:check` to `Taskfile.yml` and `docs:bundle:check` to `check` (keep `generate:reference*` and `test:refgen`); add `/out/` and `/.bin/` to `.gitignore`
- [ ] 1.6 `task docs:bundle`, then inspect `out/catalog-opm/`: `manifest.json` lists `_index.md` with `generated: false` and `source: docs/catalogs/opm/_index.md`, 45 member pages (5 blueprints, 12 resources, 28 traits) and the three kind indexes; the landing's member links read `/catalogs/opm/edge/...`; prove the pin check refuses a scratch edit of one `publish.yml@` ref
- [ ] 1.7 Add `.github/workflows/docs.yml` as design.md shows (`check`, `edge`, the `release` dispatch; `permissions: {}` at the top and per job as docs-kit C5 asks)
- [ ] 1.8 `release.yml`: add the `publish-docs` job as design.md shows (`needs: [release-please, publish-cue]`, `if: needs.release-please.outputs.opm_tag_name != ''`, `tag: opm_tag_name`, job-level `contents: read`, `packages: write`, `id-token: write`)
- [ ] 1.9 `AGENTS.md`: Repository Layout gains `docs/catalogs/`, `docs-kit.cue`, `.opm-docs-version`; the commands table gains `docs:bundle` and `docs:bundle:check` and the `task check` row names the bundle check; a "Docs bundles" subsection under Release & publishing lands the first two durable decisions (design.md)
- [ ] 1.10 `task check` green, then commit `ci(docs): publish the opm catalog docs bundle with docs-kit`

## 2. Go live (owner; gate G2)

- [ ] 2.1 **OWNER**: make `ghcr.io/open-platform-model/docs/catalog-opm` public (Package settings, Danger zone) and confirm the package is linked to `open-platform-model/catalog_opm`
- [ ] 2.2 **OWNER**: dispatch the backfill, `gh workflow run docs.yml -R open-platform-model/catalog_opm --ref main -f mode=release -f tag=opm-v4.4.5` (or the newest `opm-v4.4.*` tag by then), and wait for it to finish green
- [ ] 2.3 Verify anonymously, with no registry credentials: `cosign verify` with the docs-kit C9 flags passes for the digests of `edge` and `4.4`; tags `4.4.5.0`, `4.4.5`, `4.4`, `4` and `edge` exist; `opm-docs pull` with a scratch `bundles.cue` holding only the `catalog-opm` tab (`from: "4.4"`) resolves `4.4` and `edge`, verifies both and writes a lock
- [ ] 2.4 Record in design.md, under a new "Rollout record" heading: each tag's digest, the commit each bundle was built from, and whether the 4.4.5.0 landing is the generated one or the contract page (Risks, first entry)
- [ ] 2.5 `task check` green, then commit `docs(openspec): record the first published opm docs bundles`

## 3. Retire tools/refgen (gate G3; tools/, docs/site/, .github/, Taskfile.yml, rules)

- [ ] 3.1 Confirm G3 item by item (`gh pr view` for the opmodel.dev and cli PRs, the live URL, `git ls-tree origin/main k8s` empty)
- [ ] 3.2 Delete `tools/refgen/`, `docs/site/reference/catalog-members/` and `docs/site/reference/catalog-contract.md` (and `docs/site/reference/kubernetes-resources.md` if the `k8s` removal left it)
- [ ] 3.3 `Taskfile.yml`: remove `generate:reference`, `generate:reference:check`, `test:refgen`, their `check` entries and the `## Site reference` comment block; reword `check`'s `desc`
- [ ] 3.4 `ci.yml`: remove `Setup Go`, "Test the reference generator" and "Verify the generated site reference is up to date"; `branch-publish.yml`: remove `Setup Go`
- [ ] 3.5 `release.yml`, job `release-please`: run `opm catalog version set` on a scratch checkout with no registry credentials; remove `Setup Go`, `Install Task`, `task generate:reference`, `docs/site/reference` from `git add` and the `git status --porcelain` test, and the GHCR login with its comment unless the scratch run needed a registry
- [ ] 3.6 Reword `vet:descriptions`' `desc` and `.tasks/description-check.sh`'s header from "generated site reference" to the published catalog reference
- [ ] 3.7 Point the two "Check against" comments that name `catalog-members/` (`docs/site/authoring/attach-a-trait.md`, `choose-a-blueprint.md`) at `catalog_opm/opm/INDEX.md`
- [ ] 3.8 Land the third durable decision: `AGENTS.md` (Purpose's "one Go program" paragraph, the layout lines for `docs/site/` and `tools/refgen/`, the Dependencies Go bullet, the three refgen rows of the commands table and the `task check` row, the release-please bullet's `task generate:reference` clause, the "Site reference" Working Style bullet rewritten as the published catalog reference, and the `task check` bullet) and `openspec/config.yaml` (the context's "The only Go code is `tools/refgen/`" sentence and Principle II's `task generate:reference` bullet)
- [ ] 3.9 `grep -rn "refgen\|generate:reference\|docs/site/reference" --exclude-dir=archive .` names only this change's own files
- [ ] 3.10 `task check` green, then commit `ci(docs): retire tools/refgen and its committed pages`
