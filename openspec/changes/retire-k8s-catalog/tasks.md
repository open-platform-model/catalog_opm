## 1. Remove the `k8s` module

- [x] 1.1 `git rm -r k8s/ CHANGELOG-k8s.md`
- [x] 1.2 `release-please-config.json` and `.release-please-manifest.json`: drop the `k8s` package
- [x] 1.3 `.github/workflows/ci.yml`, `branch-publish.yml`, `release.yml`: drop `k8s` from every loop, the `k8s_*` outputs and any `k8s`-only step
- [x] 1.4 `Taskfile.yml`: `MODULES: opm`, delete `vet:layering` and its entry in `check`
- [x] 1.5 `tools/refgen`: load `opm/` only, stop writing the `k8s` table, refuse a reappearing `kubernetes-resources.md` (design D5), update `refgen_test.go`; `git rm docs/site/reference/kubernetes-resources.md`
- [x] 1.6 `task check` green, then commit `refactor: remove the k8s catalog module`

## 2. Move `opm/` to `src/`

- [x] 2.1 `git mv opm src`; `git mv CHANGELOG-opm.md CHANGELOG.md`
- [x] 2.2 `release-please-config.json` and `.release-please-manifest.json` per design D1 (package key `src`, component `opm`, `changelog-path: "/CHANGELOG.md"`, no `prerelease-type`)
- [x] 2.3 Workflows per design D2: `src--tag_name` and `src--version` outputs, the `paths_released` matrix replaced by one publish job, the identity-advance loop written out once (component `opm`, directory `src`), `opm catalog publish ./src`, every path filter and `working-directory` on `src`
- [x] 2.4 `Taskfile.yml` per design D3: `MODULE_DIR: src`, loops removed, `branch-tag` passes `opm-` literally; the `KUBERNETES_VERSION` comment and the `generate:kinds` block name `src/`
- [x] 2.5 `.tasks/generate-index.sh`: take the INDEX title from the module path, not the directory name (design D3); `task generate:index:check` shows `src/INDEX.md` unchanged
- [x] 2.6 `.tasks/generate-index.sh`, `.tasks/fixtures.sh`, `.tasks/branch-tag.sh`, `.tasks/listing.sh`, `.tasks/description-check.sh`, `.tasks/doc-check.sh`: every usage example and comment names `src`
- [x] 2.7 `tools/refgen`: load `src/`; its tests pass; `task generate:reference` (each member page's Definition row now names `src/`). `tools/kindgen` (design D6): read `src/cue.mod/module.cue`, write `src/schemas/kinds/table.cue`, package doc names `src/`; `task test:kindgen` passes
- [x] 2.8 `openspec/changes/publish-docs-bundle/`: `./opm` becomes `./src` in proposal, design and tasks; its G3 notes this change; its design's backfill note states the old path for tags before this change
- [x] 2.9 `opm catalog publish ./src --dry-run` reports the same tree digest as `opm catalog publish ./opm --dry-run` on `main` (design, Risks)
- [x] 2.10 `task check` green, then commit `refactor: move the opm module to src/`

## 3. One catalog in every description

- [ ] 3.1 `AGENTS.md`: Purpose (one catalog, the raw catalog retired, `objects@v1alpha1` as the escape hatch), Repository Rules (drop the `k8s` beta-line rule and `k8s-v*` from the tag list except as historical tags), Version-segment filing, Repository Layout, Dependencies, Version & Identity, Commit conventions (drop the `k8s` beta line), every `opm/` path
- [ ] 3.2 `README.md`: one module at `src/`, the retirement note for `k8s@v1` (last build `1.0.0-beta.2`, still resolvable)
- [ ] 3.3 `openspec/config.yaml`: the constitution's opening paragraph, Principle I (drop the `k8s` beta-line bullet and the D48 sentence), Principle III (drop the layering bullet), Principle IV (one module at `src/`), the proposal and tasks rules that name `k8s`
- [ ] 3.4 `openspec/schemas/catalog-change/schema.yaml` and `templates/proposal.md`, `templates/tasks.md`: drop `k8s`, name `src/`
- [ ] 3.5 `docs/site/authoring/*.md`, `docs/site/extending/*.md`: every "Check against" path from `catalog_opm/opm/` to `catalog_opm/src/`; drop every mention of the raw catalog, `k8s/`, `k8s@v1` or two catalogs (`write-a-resource.md:8` drops the raw-catalog filing sentence; `write-a-resource.md`, `write-a-trait.md` and `write-a-blueprint.md` name `src/INDEX.md` only)
- [ ] 3.6 `docs/name-constraints.md`: delete the section "`k8s/`: exact-name kinds and the override"; every `opm/` path in `docs/*.md` (`cue-guard-closedness-workaround.md`, `name-constraints.md`, `struct-disjunctions.md`) to `src/`
- [ ] 3.7 Closing grep over the tree, excluding `openspec/changes/archive/`, `CHANGELOG.md` and this change: `grep -rIn -E 'catalogs/k8s|k8s catalog|raw (kubernetes )?catalog|two (first-party )?catalogs|both catalogs|catalog_opm/opm/|\./opm\b|CHANGELOG-(opm|k8s)'` returns nothing
- [ ] 3.8 `task check` green, then commit `docs: describe catalog_opm as one catalog`
