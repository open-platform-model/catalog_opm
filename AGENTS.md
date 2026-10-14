# catalog_opm repository guide

This repo defines and publishes one first-party OPM catalog: the CUE module `opmodel.dev/catalogs/opm@v4`, rooted at `src/`. It is the canonical set of OPM Kubernetes building blocks (`#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer`) that platform and module authors consume. It is typed against `opmodel.dev/core@v2`, instantiates its constructs and defines none. Members are intentional OPM abstractions (`container`, `volume`, `scaling`) that may differ from Kubernetes on purpose. Experimental candidates live here at `v1alpha1`: alpha promises nothing (enhancement 0010).

The catalog is pure CUE plus the tooling to validate, index and publish it. The one Go program is `tools/kindgen/`, its own module, never shipped. It generates the Kubernetes kind table in `src/schemas/kinds/`. The catalog reference is not committed: docs-kit's `opm-docs` builds it from the module into the `catalog-opm` docs bundle.

## Branch model

| Branch | Line | What may land |
| --- | --- | --- |
| `main` | `opmodel.dev/catalogs/opm@v4`, stable `v4.x.x` | All catalog work. It stays stable through the OPM beta while it depends on the `core@v2` beta line. |
| `v1` | retired v1 line | Fixes only, `1.0.x` releases. Never merge `main` into it. |

Release-please keeps `versioning: prerelease` with `prerelease: false` on `main`. A `feat!:` PR title bumps the major and the module path; a core beta break that would force an `opm` major needs owner sign-off.

## Repository rules

- Authority is this file, `openspec/config.yaml` and `Taskfile.yml`. There is no `CONSTITUTION.md`. `Taskfile.yml` wins on how commands run.
- Cut work into mergeable sections: each ends green under `task check` and closes with its own commit (`openspec/config.yaml`).
- The catalog is a published contract: downstream platforms and modules pin it. Prefer additive evolution. A contract's `apiVersion` moves only when that primitive's own shape breaks (enhancement 0010).
- Never run the publish flow against a live registry by hand. CI publishes with `opm catalog publish`. There is no publish task, so a laptop publish needs `OPM_REGISTRY` pointed at the local registry on purpose.
- Release tags are immutable: `opm-v*`, the retired `k8s-v*` and the older bare `v*`. Never overwrite a published catalog version. A wrong release is fixed by the next version.
- The directory is `src/`; the module path, the release-please component and the tag prefix are `opm`. release-please's package key is the path (`src`), so its manifest entry and outputs (`src--tag_name`, `src--version`) read `src`. Anything that needs both names the directory and the component separately. Never derive one from the other.
- Keep one module. Do not add a sibling module or a passthrough member family: a Kubernetes object no abstraction models goes through `objects@v1alpha1`.
- Never place an `if spec.<nested>.<field> != _|_` guard inside a component's `spec` block for a struct- or list-valued field. Hoist it to component level. The in-spec form trips a CUE closedness regression still present in `v0.17.1`. Do not "modernize" the hoisted form away.
- The `vet:listing` gate keys on a member's `fqn` field, not on its location. A definition with no `fqn` is not a member and gets no entry in the catalog map.
- A provider-fulfilled member (`fulfilment: "provider"`) ships no transformer here, and never a stub. A stub would make `opm@v4` a provider and break the contract for any real provider elsewhere.
- Never hand-edit `Version` in the identity package (`src/identity/`), `apiVersion`, `catalogVersion` or `fqn` to chase a release. The release workflow writes `Version` on the release PR with `opm catalog version set`.
- Merge a catalog release PR only when its head is the `chore: advance opm identity.Version to <v>` commit and CI has passed on that head: `gh pr merge <N> --squash --body '' --match-head-commit <sha>`, never `--admin`. An earlier head burns the version.
- The opm CLI that CI installs is pinned in `.opm-cli-version` and nowhere else. No version literal for it goes under `.github/workflows/`.
- Never delete or hand-edit `src/RELEASE`. It makes every release PR touch a file under the package path. Without it a release merge commit can touch no module file, which breaks the next-release commit boundary (measured 2026-08-31: a bogus "release opm 2.0.0" PR right after `opm-v3.0.0`).
- No Actions cache in a job that publishes (the release, branch-publish and docs workflows).
- A fixture lives in a `*_fixtures.cue` file that opens with `@if(fixtures)`, so a plain build and every consumer leave it out. `task vet:fixtures` is the gate that makes it concrete.
- Pin `language: version: "v0.17.0"` in `src/cue.mod/module.cue`. It is a consumer floor, not a toolchain pin.
- Keep the generated index in `src/` in sync when a definition or the module tree changes: run `task generate:index` and review the output.
- Non-trivial catalog work goes through OpenSpec with the project-local `catalog-change` schema: proposal, design, tasks. It has no specs artifact by design: there is no `openspec/specs/` and no `specs/` inside a change, and each change's `.openspec.yaml` carries `skip_specs: true`. The definition is the spec.
- A decision a future catalog author needs is declared in the change's design under Durable decisions and lands in `docs/` or a `references/` file before the change is archived. `task openspec:check` enforces it.
- `openspec-sync-specs` is deleted because there are no specs to sync. Delete it again after `openspec init` or `openspec update`.
- Cite an enhancement as the id beside a reason in words, `(enhancement 0010)`. Never a decision number. The workspace `references/enhancements.md` has the rule.

## Layout

```text
src/                     the CUE module root: opmodel.dev/catalogs/opm@v4, with the catalog manifest and generated index
src/identity/            ModulePath and Version (the publish-time stamping anchor)
src/resources/<v>/       #Resource definitions per apiVersion segment; v1alpha1 holds candidates and objects
src/traits/<v>/          #Trait definitions per apiVersion segment
src/blueprints/<v>/      #Blueprint definitions per apiVersion segment
src/transformers/        #ComponentTransformer definitions, flat, with their fixtures
src/schemas/             shared schema types and vendored Kubernetes types
src/schemas/kinds/       generated Kubernetes kind table (tools/kindgen)
tools/kindgen/           Go generator of the kind table (own go.mod)
docs/                    authoring notes that outlive a change
docs/site/               site pages (authoring/, extending/); the catalog-opm-docs bundle
docs/catalogs/opm/       pages that ship only in the catalog-opm bundle;
docs-kit.cue             the docs bundles config, outside the module root
.opm-docs-version        the pinned docs-kit release
.opm-cli-version         the pinned opm CLI tag
openspec/                OpenSpec workspace: config.yaml (constitution), schemas/catalog-change/, changes/
.tasks/                  Taskfile script fragments; .tasks/cascade/ holds the cascade task and wiring check
```

`src/` is the module root, so the import path has no per-version subdirectory and internal imports resolve from `src/`. Repo-level material (README, Taskfile, workflows, changelog) sits at the repo root. A breaking revision bumps the module major and never adds a sibling package. Raw `cue` runs from `src/`; the Taskfile points every task there through `MODULE_DIR`.

## Dependencies

- `opmodel.dev/core@v2`: the schema the catalog instantiates.
- `cue.dev/x/k8s.io@v0`: vendored Kubernetes types. A bump of its pin moves `KUBERNETES_VERSION` in `Taskfile.yml` and runs `task generate:kinds` in the same PR.
- Go, at the version in `tools/kindgen/go.mod`: only for `task test:kindgen` and `task generate:kinds`.
- `cue vet` needs a reachable registry. Export `CUE_REGISTRY` and `OPM_REGISTRY` as the workspace registry reference says before raw `cue` outside `task`.

## Commands

| Command | What it does | When |
| --- | --- | --- |
| `task fmt` / `task fmt:check` | Format CUE files / verify formatting. `fmt:check` diffs the git index, so stage first | Before a commit |
| `task vet` | `cue vet` in both views: shipped (fixture files left out) and `-t fixtures` | After a CUE edit |
| `task vet:listing` | Every member is a key of its catalog map, and every key a member | After adding or moving a member |
| `task vet:descriptions` | Refuse a member without a non-blank `metadata.description` | After adding a member |
| `task vet:fixtures` | Export every rendered-output transformer fixture | After a transformer or fixture edit |
| `task vet:fixtures:tagged` | Refuse a `_test*` field in a file without `@if(fixtures)` (offline) | After adding a fixture |
| `task tidy` | Tidy the CUE module manifest | After a dependency change |
| `task generate:index` / `task generate:index:check` | Regenerate / verify the generated index | After a definition change |
| `task docs:check` | Fail on a doc comment over 6 lines | After a comment edit |
| `task docs:bundle` | Build both docs bundles into `out/<project>/` (gitignored) | To preview the site |
| `task docs:bundle:check` | Check the docs-kit pins, then build and lint each bundle | Before a PR |
| `task docs:pins:check` | Refuse a docs-kit workflow ref that differs from `.opm-docs-version` (offline) | After a docs-kit bump |
| `task tools:opm-docs` | Install or reuse `.bin/opm-docs` at `.opm-docs-version` | Before a local bundle build |
| `task test:kindgen` | Vet and unit-test `tools/kindgen` (offline) | After a kindgen edit |
| `task generate:kinds` | Regenerate the kind table from the pinned x/k8s.io and the OpenAPI spec (downloads; CI never runs it) | After an x/k8s.io bump |
| `task openspec:check` | Check every active change's Durable decisions section and its target files | Before archiving |
| `task cite-lint` | Fail on a decision number or a lone enhancement id in a Go or CUE comment (needs network and Go 1.26.9 or newer; not in `task check`; CI runs it) | Before a PR that edits comments |
| `task cascade:wiring:check` | Run the cascade wiring check offline (needs mikefarah yq v4) | After a workflow edit |
| `task branch-tag` | Print the deterministic `-dev` tag for HEAD | To predict a branch build |
| `task deps:release-check` | Fail on a `-0.dev.` pin or a tracked local module file (CI runs it on release branches) | Anywhere, safe |
| `task -x deps:cascade` (and `:title`, `:body`, `:test`) | The cascade's per-repo task. Always use `-x`: plain `task` turns exit 3 into 201 | Only in a cascade run or its test |
| `task check` | fmt check, vet, listing, descriptions, fixtures, fixture tags, INDEX, kindgen tests, docs bundle check, doc-comment limit, durable decisions, cascade wiring | Before you finish |

## Style

- Follow the CUE style used across the workspace catalogs and the workspace `STYLE.md`.
- A doc comment is at most 6 lines (`task docs:check` fails on more). Rationale goes in a `// WHY` block above it.

@CONTEXT.md
