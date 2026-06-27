# OPM core catalog

The canonical catalog for the Open Platform Model. `catalog_opm` provides the reusable Kubernetes building blocks — `#Resource`s, `#Trait`s, `#Blueprint`s, and `#ComponentTransformer`s — that OPM module and platform authors compose and render against.

This repository is a single CUE module, `opmodel.dev/catalogs/opm@v1`, published to `ghcr.io/open-platform-model/catalogs/opm` and consumed via `import "opmodel.dev/catalogs/opm@v1"` (package `opm`).

The module is pre-1.0: `v0.x` makes no stability promise — breaking changes may land in minor releases until it graduates to `v1`.

It is typed against the OPM `core` schema and depends on it (plus vendored Kubernetes types), so `cue vet` needs a reachable registry.

## Layout

The CUE module lives under `src/` — both the catalog package files and `cue.mod/` sit there, so `src/` is the module root and the import path stays `opmodel.dev/catalogs/opm@v1` (no per-version subdirectory). The generated definition index ships inside `src/` so it travels with the published module; everything else (README, Taskfile, CI workflows) stays at the repo root.

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/catalogs/opm@v1
src/catalog.cue          catalog manifest (c.#Catalog, enumerates transformers)
src/identity/            ModulePath + Version (publish-time stamping anchor)
src/resources/           #Resource definitions
src/traits/              #Trait definitions
src/blueprints/          #Blueprint definitions
src/transformers/        #ComponentTransformer definitions (OPM -> Kubernetes)
src/schemas/             shared + vendored Kubernetes types
src/INDEX.md             generated definition index
```

## Dependencies

- `opmodel.dev/core@v1` — the OPM schema this catalog instantiates.
- `cue.dev/x/k8s.io@v0` — vendored Kubernetes types.

## Release lifecycle

`catalog_opm` has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please), which opens a release PR.
- Merging the release PR tags `vX.Y.Z` and creates the GitHub Release.
- The same `release.yml` run then publishes the module via publish-time version stamping (`task publish`) against `ghcr.io/open-platform-model`.

The CUE module path is pinned to major `@v1` and ships on the v1 prerelease line (`v1.x.x-alpha.x`) during the post-rename rollout (enhancement 0002 / D14). Was: major `@v0`, tags within `v0.x.x`.

## Common commands

```bash
task fmt             # format CUE files
task vet             # validate the catalog package
task generate:index  # regenerate src/INDEX.md
task check           # fmt check + vet + INDEX freshness
task publish VERSION=v0.1.0   # stamp + publish the CUE module (CI does this on release)
```
