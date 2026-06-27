# catalog_opm repository guide

## Purpose

This repo defines and publishes the **OPM core catalog** as a versioned CUE module (`opmodel.dev/catalogs/opm@v1`).

The catalog is the canonical set of OPM Kubernetes building blocks — `#Resource`s, `#Trait`s, `#Blueprint`s, and `#ComponentTransformer`s — that platform and module authors consume to model and render workloads. It is typed entirely against the `core` schema (`opmodel.dev/core@v1`) and instantiates its constructs; it does **not** define new core constructs.

This is a pure CUE repository: catalog definitions plus the tooling to validate, index, and publish them. No Go code.

> History: this content previously lived inside the `library` repo at `library/modules/opm/` and was published from there. It now has its own repo and release cadence. The legacy `catalog/` repo is deprecated/read-only and unrelated to this module.

## Repository Rules

- Authority is this file and `Taskfile.yml`. If they disagree with anything below, they win.
- Keep changes small. Split broad requests into tiny, independently verifiable steps.
- The catalog is a published contract — downstream platforms and modules pin `opmodel.dev/catalogs/opm@v1`. Prefer additive evolution.
- Never run the publish flow against a live registry manually — let CI publish.
- The CUE module is pinned to major `@v1` and ships on the v1 prerelease line (`v1.x.x-alpha.x`) for the post-rename rollout — release-please is configured with `versioning: prerelease` + `prerelease-type: alpha` (enhancement 0002 / D14). Was: major `@v0`, tags within `v0.x.x` (`bump-minor-pre-major: true`).

## Entrypoint

Read these on entry:

- `CLAUDE.md` — repo working rules (this file).
- `Taskfile.yml` — authoritative build/validate/publish entrypoints.
- `src/INDEX.md` — generated definition index (ships inside the CUE module).
- `src/catalog.cue` — the catalog manifest (`c.#Catalog`, enumerates transformers).

## Repository Layout

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/catalogs/opm@v1
src/catalog.cue          catalog manifest (bare c.#Catalog, enumerates transformers)
src/identity/            ModulePath + Version (publish-time stamping anchor)
src/resources/           #Resource definitions (+ #Component wrappers)
src/traits/              #Trait definitions
src/blueprints/          #Blueprint definitions (composed resources + traits)
src/transformers/        #ComponentTransformer definitions (OPM -> Kubernetes)
src/schemas/             shared schema types + vendored Kubernetes types
src/INDEX.md             generated definition index (ships inside the CUE module)
.tasks/                  Taskfile script fragments (index + branch-tag)
```

`src/` is the CUE module root: the catalog package and `cue.mod/` both live there, so the import path stays `opmodel.dev/catalogs/opm@v1` with no per-version subdirectory. Internal imports (`opmodel.dev/catalogs/opm/identity`, `.../resources`, `.../traits`, …) resolve relative to the module root. Repo-level material (README, Taskfile, CI workflows) sits at the repo root. A breaking revision bumps the module major (`@v1` → `@v2`); it does not add a sibling package.

All raw `cue` invocations run from `src/`. The Taskfile handles this via `dir: src` / `cd src`.

## Dependencies

- `opmodel.dev/core@v1` — the OPM schema this catalog instantiates.
- `cue.dev/x/k8s.io@v0` — vendored Kubernetes types used by `schemas/kubernetes/**` and transformers.

`cue vet` therefore needs a reachable registry. Export the workspace registry vars from the root `CLAUDE.md` (`CUE_REGISTRY`, `OPM_REGISTRY`) before running raw `cue` outside `task`.

## Version Stamping (important)

The catalog uses **publish-time version stamping**, not plain `cue mod publish`:

- `src/identity/identity.cue` defines `ModulePath` and `Version`. Every resource/trait/blueprint/transformer threads its `metadata.version` from `identity.Version`.
- The committed tree resolves `Version` to the `0.0.0-dev` sentinel.
- `task publish VERSION=vX.Y.Z` copies `src/` to a transient build dir, writes `identity/version_override.cue` pinning the concrete bare SemVer, vets the build dir, then runs `cue mod publish vX.Y.Z`. The source tree is never mutated, and publishing the dev sentinel is refused.

Never hand-edit `metadata.version` on definitions — change `identity` (or pass `VERSION` at publish).

## Build And Dev Commands

| Command                       | Purpose                                              |
| ---                           | ---                                                  |
| `task fmt` / `task fmt:check` | Format CUE files / verify formatting                 |
| `task vet`                    | Validate the catalog package                         |
| `task tidy`                   | Tidy the CUE module manifest                         |
| `task generate:index`         | Regenerate `src/INDEX.md`                            |
| `task generate:index:check`   | Verify `src/INDEX.md` is up to date                  |
| `task check`                  | fmt check + vet + INDEX freshness                    |
| `task publish VERSION=vX.Y.Z` | Stamp + publish the catalog (CI does this on release)|

### Release & publishing

- release-please (`release.yml`, release type `simple`) opens and updates the release PR. Merging it tags `vX.Y.Z` and creates the GitHub Release.
- The same workflow run publishes the module: a `publish-cue` job gated on `release_created == 'true'` runs `task publish` against `ghcr.io/open-platform-model`, in the run triggered by the human merging the release PR (avoiding GitHub's GITHUB_TOKEN tag-trigger suppression).
- `branch-publish.yml` publishes a `-dev` pre-release for non-main branches via `task publish:branch`.

### Commit conventions and release impact

Releases are driven by Conventional Commit types. Use the right type.

| Commit type                   | Version bump | In changelog | Use for                                          |
| ---                           | ---          | ---          | ---                                              |
| `feat:`                       | minor        | yes          | new resource/trait/blueprint/transformer, new field |
| `fix:`                        | patch        | yes          | wrong constraint, broken transform output        |
| `perf:`                       | patch        | yes          | evaluation cost improvements                     |
| `feat!:` / `BREAKING CHANGE:` | minor (pre-1.0) | yes       | removing/renaming a definition, tightening output |
| `refactor:`/`docs:`/`style:`/`chore:`/`test:`/`ci:`/`build:` | none | hidden | moves, comments, tooling — no published change   |

**Rule of thumb:** if the published catalog is byte-identical before and after, it is not a `feat:` or `fix:`.

## Working Style for Agents

- Keep `src/INDEX.md` in sync when adding, removing, or renaming definitions, or when the `src/` tree changes. `task generate:index` regenerates it (review before commit).
- When adding a transformer, register it in `src/catalog.cue`'s `#transformers` map (keyed by `metadata.fqn`). Resources/traits/blueprints surface transitively through transformer required/optional maps.
- Run `task check` before finishing — fmt, vet, and INDEX freshness in one shot.
- This repo is pure CUE — there is no SPEC.md / core-schema-edit protocol here. Those belong to `core/`.
