# OPM core catalog

The canonical catalog for the Open Platform Model. `catalog_opm` provides the reusable Kubernetes building blocks — `#Resource`s, `#Trait`s, `#Blueprint`s, and `#ComponentTransformer`s — that OPM module and platform authors compose and render against.

This repository holds one CUE module, in `src/`: `opmodel.dev/catalogs/opm@v4` (published to `ghcr.io/open-platform-model/catalogs/opm`, imported as `import "opmodel.dev/catalogs/opm@v4"`, package `opm`). It is on major `v4`; a breaking change crosses the major and moves the module path with it.

A Kubernetes object the catalog does not model goes through its `objects` resource (`objects@v1alpha1`), which renders native objects as written and validates a built-in kind against its closed Kubernetes definition; any other kind, such as a custom resource, passes open.

`opmodel.dev/catalogs/opm@v4` ships no env-secret path: the legacy `#Secret` contract type is removed and its replacement, a `core`-owned `#Secret` resolved by the kernel (enhancement 0013), lands in a later change. Hand-authored Secret objects (`#SecretsResource`, inline `secret` volume sources) keep working with string data.

It is typed against the OPM `core` schema and depends on it (plus vendored Kubernetes types), so `cue vet` needs a reachable registry.

## Layout

`src/` is the module root (catalog package files plus `cue.mod/`) and ships its own generated definition index, so the index travels with the published module. Everything else (README, Taskfile, CI workflows, the changelog) stays at the repo root and does not ship.

```text
src/cue.mod/module.cue   CUE module manifest — opmodel.dev/catalogs/opm@v4
src/catalog.cue          catalog manifest (c.#Catalog, enumerates transformers)
src/identity/            ModulePath + Version (the committed identity publish reads)
src/resources/           #Resource definitions
src/traits/              #Trait definitions
src/blueprints/          #Blueprint definitions
src/transformers/        #ComponentTransformer definitions (OPM -> Kubernetes)
src/schemas/             shared + vendored Kubernetes types
src/INDEX.md             generated definition index

CHANGELOG.md             release notes, kept outside the module root so they do
                         not ship inside the published artifact
```

## Dependencies

- `opmodel.dev/core@v2` — the OPM schema the catalog instantiates.
- `cue.dev/x/k8s.io@v0` — vendored Kubernetes types.

## Release lifecycle

The module has its own release cadence, independent of any consumer.

- Conventional-commit history drives [release-please](https://github.com/googleapis/release-please) in manifest mode with one package, path `src`, component `opm`. It opens the release PR; `release.yml` writes the decided version into `src/identity/identity.cue` on that PR via `opm catalog version set`.
- Merging the release PR tags `opm-vX.Y.Z` and creates the GitHub Release. Bare `vX.Y.Z` tags predate the component tags and stay resolvable.
- The same `release.yml` run then publishes the module with `opm catalog publish` against `ghcr.io/open-platform-model` — the committed tree exactly, gated by the publish pipeline (enhancement 0011).

The module path is pinned to major `@v4` and ships stable `v4.x.x` releases; a break is a new major (the `v2.x.x-alpha.x` line of the core-v2 rollout, enhancement 0010, closed at `2.0.0`). The `v1` maintenance branch keeps the retired v1 line on `1.0.x` fix releases.

## Retired: the `k8s` module

This repository also published `k8s@v1`, a passthrough module of native Kubernetes APIs under the same `opmodel.dev/catalogs/` prefix, from a `k8s/` directory. It is retired: its last build is `1.0.0-beta.2`, and no further release follows. Every published build and every `k8s-v*` tag stays, so a platform or module that pins one keeps resolving. Use `objects@v1alpha1` in `opmodel.dev/catalogs/opm@v4` instead.

## Common commands

```bash
task fmt             # format the module's CUE files
task vet             # validate the catalog packages
task generate:index  # regenerate src/INDEX.md
task check           # every gate: fmt check, vet, listing, descriptions, fixtures, fixture tags, INDEX and reference freshness, cascade wiring
opm catalog publish ./src --dry-run   # run every publish gate, push nothing (publishing itself is CI-only)
```
