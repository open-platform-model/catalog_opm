## 1. Descriptions and the description gate (opm/, k8s/)

- [x] 1.1 `opm/resources/`, `opm/traits/`, `opm/blueprints/`: give every member a doc comment whose first sentence is its `metadata.description`, rewriting vague or inaccurate descriptions; keep every later doc sentence that still holds
- [x] 1.2 `k8s/resources/`: the same for the 29 raw resources (their doc comments open with the description instead of `#XResource defines ...`)
- [x] 1.3 Add `.tasks/description-check.sh` and `task vet:descriptions` (all four catalog maps), wire it into `task check` and `ci.yml`; prove it refuses a missing and a blank description on a scratch copy
- [x] 1.4 Land the description rule in `AGENTS.md` (Working Style, the commands table, the `task check` row)
- [x] 1.5 `task generate:index`
- [x] 1.6 `task check` green, then commit `fix(catalog): give every member a description that opens its doc comment`

## 2. The reference generator and its pages (tools/refgen/, docs/site/reference/)

- [x] 2.1 `tools/refgen/`: Go module on `cuelang.org/go` v0.17.1; load both catalog modules, evaluate the four maps, read doc comments and spec schemas from the source AST
- [x] 2.2 Member pages under `docs/site/reference/catalog-members/{blueprints,resources,traits}/`, each in the fixed order summary, at a glance, spec, example (omitted, see design.md), notes, served by, enforcement; marks and enforcement rows derived only as design.md states
- [x] 2.3 Replace `catalog-members.md` with the section `catalog-members/_index.md` (title, description and weight kept; See also kept) and generate the three subsection pages
- [x] 2.4 Generate the table in `kubernetes-resources.md` between markers; rewrite its authored intro and description
- [x] 2.5 `task generate:reference` and `task generate:reference:check` (also refuses orphan pages), in `task check`; update the two planning-comment paths in `docs/site/authoring/`
- [x] 2.6 Verify on the real site build: `task build` and `task lint:sources` in `opmodel.dev` with `OPM_SRC_CATALOG_OPM` set to this worktree
- [x] 2.7 `task check` green, then commit `docs(site): generate the catalog reference from both catalogs`

## 3. CI, release and repository rules (.github/, AGENTS.md, openspec/config.yaml)

- [ ] 3.1 `ci.yml`: install Go from `tools/refgen/go.mod` and run `task generate:reference:check`
- [ ] 3.2 `release.yml`: install Go and Task in the release-please job and regenerate the reference in the identity-advance commit
- [ ] 3.3 `AGENTS.md` and `openspec/config.yaml`: drop "no Go code", add the reference rule (Durable decisions)
- [ ] 3.4 `task check` green, then commit `ci: check the catalog reference and regenerate it on release PRs`
