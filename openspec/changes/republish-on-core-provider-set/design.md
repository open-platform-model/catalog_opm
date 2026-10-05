## Context

Files touched, no member files and no `apiVersion` segment:

- `src/cue.mod/module.cue`: the `opmodel.dev/core@v2` pin (`v2.0.0-beta.1` to `v2.0.0-beta.3`). `language.version`, `cue.dev/x/k8s.io@v0` (`v0.12.0`) and `.opm-cli-version` (`v1.0.0-beta.8`) do not change.
- `src/catalog_fixtures.cue` (new): a fixtures-only assertion on the catalog root.

The pin skips beta.2. Core beta.2 (core#103, `perf`) only moved core's own schema pins into a `src/pins` subpackage, and catalog_opm imports nothing from it. Beta.3 (core#120) adds the derived field to `#Catalog`:

```cue
// core src/catalog.cue at v2.0.0-beta.3, inside #Catalog
provides: [...#ContractFQNType] & list.Sort([for fqn, _ in providerSet {fqn}], list.Ascending)
```

`providerSet` collects every `requiredResources` or `requiredTraits` key of the catalog's own `#transformers` whose requirement reads `fulfilment: "provider"`. It is derived and never authored. `#Catalog` stays closed.

Closedness, defaults and required fields: no change in any catalog member. The catalog root gains one regular field from core.

## Goals / Non-Goals

**Goals:**

- The next `opm` release is built on core beta.3, so the published catalog carries `provides` (owner decision h2, catalog half).
- Every package and every rendered-output fixture vets on the new core (`task vet`, `task vet:fixtures`, inside `task check`).
- A vet failure, not a silent republish, if `opm` ever starts to provide a contract.

**Non-Goals:**

- The j3 consumer pin bump, the library fallback removal, and the operator's old-catalog test (proposal Non-goals and Impact).
- Changing `#PreBoundRegistration` (proposal Non-goals).

## Decisions

**D-A. Bump by hand, with exactly the cascade's edit.** `cue mod get opmodel.dev/core@v2.0.0-beta.3` and one `cue mod tidy` in `src/`, as `.tasks/cascade/cascade.sh` does. The cascade itself does not run: it is in dry run, and it would also move `.opm-cli-version` to the newest cli, which the supervisor notes leave out. If a `deps/cascade` PR that moves core appears before this merges, stop and report it instead of racing it (tasks 1.1 and 2.1).

**D-B. Pin `opm`'s derived `provides` to `[]` with a package-level fixture.**

```cue
// src/catalog_fixtures.cue
@if(fixtures)

package opm

// The opm catalog defines provider-fulfilled contracts (backup@v1alpha1,
// backup-command@v1alpha1) and implements none: a transformer here that
// required one would make opm a provider. Core derives provides; this
// pins it empty.
provides: []
```

A hidden `_test` field cannot be used here, because `provides` comes from the embedded `c.#Catalog`, and a lexical reference to it from a sibling file fails with `reference "provides" not found` (spike below). A regular field in an `@if(fixtures)` file unifies with the derived value in `cue vet -t fixtures ./...` (the second half of `task vet`) and never reaches a consumer. It is not a top-level `_test*` field, so `task vet:fixtures:tagged` does not apply to it. The tag line is still required, or the assertion ships.

Alternative considered: re-derive the set in the fixture and compare it with `provides`, as core's pins do. Rejected: core#120's pins already prove the derivation. The catalog-specific fact worth pinning is the value for `opm`, and AGENTS.md "Provider-fulfilled members ship no transformer here, and never a stub" says why that value must be empty.

## Research & Decisions

### Spike: what the bump changes, and whether the fixture bites

**Context**: the design assumes beta.3 vets clean and only adds `provides`, and that a fixture can compare against a field from an embedded definition.
**Explored**: 2026-10-05, cue v0.17.1, a scratch copy of `src/` at `origin/main` 7c0dc2d with `cue mod get opmodel.dev/core@v2.0.0-beta.3` and `cue mod tidy`:
- `module.cue` changed only on the core line; `cue.dev/x/k8s.io@v0` stayed `v0.12.0`.
- `cue vet ./...` and `cue vet -t fixtures ./...` passed.
- `cue eval -e provides .` gave `[]`. `cue export .` differed from the beta.1 export only by `"provides": []`.
- `_testCatalogProvides: provides & []` in a fixture file failed with `reference "provides" not found`.
- `provides: []` at package level in the fixture file passed. With the literal set to `["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]`, it failed with `provides: incompatible list lengths (0 and 1)`.
- With the pin set back to beta.1, the package-level `provides: []` still passed, because the package root accepts the field. So the fixture pins the value, not the core floor. The floor is the pin itself, which only the cascade or a hand-made bump moves, and both only move forward.
**Decision**: D-A and D-B as written. Task 2.3 still checks the fixture against a real stub-transformer mutation.
**Rationale**: every assumption except the stub mutation was measured, and the stub mutation is a task, not an open design question.

### Release route

**Context**: the plan entry says "release a catalog_opm minor"; its release class is `fix`.
**Explored**: catalog_opm#145 (`chore(main): release opm 4.7.0`, open, another session) carries #143's `feat`. No `deps/cascade` branch exists on origin, and no open PR moves core.
**Decision**: the PR is titled `fix(deps)` (a patch class). Release-please folds it into the open 4.7.0 release PR, so the republish ships as 4.7.0 when the owner or supervisor merges #145.
**Rationale**: only the title reaches release-please, and the version is chosen by the highest unreleased class on `main` (`feat` from #143), not by this PR.

## Risks / Trade-offs

- The publish compatibility gate (cli `v1.0.0-beta.8`) could treat the new root field or core's changed definitions as a violation. -> Task 1.4 runs `opm catalog publish ./src --dry-run` and accepts only "already published" as a refusal. Any other refusal stops the change and gets reported, with no workaround.
- `opm-docs` could render the new root field into the reference bundle. -> `task docs:bundle:check` is part of `task check`. Note any page diff in the report.
- A platform on core beta.3 with an older `opm` release has no `provides` for that entry. -> That is why the library keeps its fallback until GA (owner decision h2).

## Durable decisions

None. The rule the fixture enforces is already in `AGENTS.md` ("Provider-fulfilled members ship no transformer here, and never a stub"), and the fixture's own comment points at it.
