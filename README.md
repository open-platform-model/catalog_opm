# OPM core catalog

The canonical catalog for the Open Platform Model. `catalog_opm` provides the reusable Kubernetes building blocks — `#Resource`s, `#Trait`s, `#Blueprint`s, and `#ComponentTransformer`s — that OPM module and platform authors compose and render against.

This repository is a single CUE module, `opmodel.dev/catalogs/opm@v2`, published to `ghcr.io/open-platform-model/catalogs/opm` and consumed via `import "opmodel.dev/catalogs/opm@v2"` (package `opm`).

The module is pre-1.0: `v0.x` makes no stability promise — breaking changes may land in minor releases until it graduates to `v1`.

It is typed against the OPM `core` schema and depends on it (plus vendored Kubernetes types), so `cue vet` needs a reachable registry.

## Layout

This repo publishes **two CUE modules**, one per subdirectory. Each subdirectory is its own module root (catalog package files plus `cue.mod/`), and each ships its own generated definition index so the index travels with the published module. Everything else (README, Taskfile, CI workflows, changelogs) stays at the repo root.

| Directory | Module | What it is |
| --- | --- | --- |
| `opm/` | `opmodel.dev/catalogs/opm@v2` | the abstraction catalog: intentional OPM abstractions |
| `k8s/` | `opmodel.dev/catalogs/k8s@v1` | the raw catalog: native Kubernetes APIs carried through as-is |

Neither catalog imports the other. A platform subscribes to each one it wants.

```text
opm/cue.mod/module.cue   CUE module manifest — opmodel.dev/catalogs/opm@v2
opm/catalog.cue          catalog manifest (c.#Catalog, enumerates transformers)
opm/identity/            ModulePath + Version (the committed identity publish reads)
opm/resources/           #Resource definitions
opm/traits/              #Trait definitions
opm/blueprints/          #Blueprint definitions
opm/transformers/        #ComponentTransformer definitions (OPM -> Kubernetes)
opm/schemas/             shared + vendored Kubernetes types
opm/INDEX.md             generated definition index

k8s/cue.mod/module.cue   CUE module manifest — opmodel.dev/catalogs/k8s@v1
k8s/catalog.cue          catalog manifest (c.#Catalog, enumerates transformers)
k8s/identity/            ModulePath + Version
k8s/resources/           passthrough #Resource definitions, filed by upstream apiVersion
k8s/transformers/        passthrough #ComponentTransformer definitions
k8s/schemas/             open (`...`) wrappers over the native Kubernetes shapes
k8s/INDEX.md             generated definition index

CHANGELOG-opm.md         per-module changelogs, kept outside the module roots so
CHANGELOG-k8s.md         they do not ship inside the published artifacts
```

## Dependencies

- `opmodel.dev/core@v2` — the OPM schema both catalogs instantiate.
- `cue.dev/x/k8s.io@v0` — vendored Kubernetes types, used by the `opm` module only. The `k8s` module depends on `core` alone.

## Release lifecycle

Each module has its own release cadence, independent of the other and of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please) in manifest mode with one package per module. Each opens its own release PR; `release.yml` writes the decided version into that module's `identity/identity.cue` on that PR via `opm catalog version set`.
- Merging a release PR tags `opm-vX.Y.Z` or `k8s-vX.Y.Z` and creates the GitHub Release. Bare `vX.Y.Z` tags predate the split and stay resolvable.
- The same `release.yml` run then publishes the released module with `opm catalog publish` against `ghcr.io/open-platform-model` — the committed tree exactly, gated by the publish pipeline (enhancement 0011).

The `opm` module path is pinned to major `@v2` and ships stable `v2.x.x` releases (the `v2.x.x-alpha.x` line of the core-v2 rollout, enhancement 0010, closed at `2.0.0`); the `v1` maintenance branch keeps the retired v1 line on `1.0.x` fix releases. The `k8s` module starts at major `@v1` on its own alpha line.

## Common commands

```bash
task fmt             # format CUE files in both modules
task vet             # validate both catalog packages
task generate:index  # regenerate opm/INDEX.md and k8s/INDEX.md
task check           # fmt check + vet + layering + INDEX freshness, both modules
opm catalog publish ./opm --dry-run   # run every publish gate, push nothing (publishing itself is CI-only)
opm catalog publish ./k8s --dry-run
```
