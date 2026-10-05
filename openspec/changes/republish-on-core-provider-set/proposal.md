## Why

Core `v2.0.0-beta.3` (core#120, published 2026-10-05) gives every `#Catalog` a derived regular field, `provides`: the sorted provider-fulfilled contracts its own transformers require. A catalog only carries that field when it is evaluated at a core pin that has it, and `opm` still pins `opmodel.dev/core@v2` at `v2.0.0-beta.1` (`src/cue.mod/module.cue`). Until an `opm` release built on beta.3 is published, the library's `Catalog.Provides()` has to keep its deprecated Go fold for this catalog.

The owner decided this in the beta.1 kernel plan walkthrough (task h2): "Core gains a per-catalog provider set (additive core release); Provides() decodes it and falls back to the deprecated Go fold for older catalogs; the fallback is removed before GA, after catalog_opm is republished. Needs a catalog_opm rebuild and an operator test for an old catalog." This change is that rebuild: the catalog half of h2 only. Library ADR-012 is the rule behind it (one derived rule moves into core at a time).

It implements no undelivered enhancement decision (h2 is a walkthrough task, and ADR-012 is a library ADR), so it carries no `enhancement.yaml`.

## What Changes

- **`src/cue.mod/module.cue`**: `opmodel.dev/core@v2` moves from `v2.0.0-beta.1` to `v2.0.0-beta.3`, with one `cue mod tidy` in `src/`. This is the same edit `task -x deps:cascade` makes. The cascade is in dry run (`CASCADE_DRY_RUN=true`), so no bot PR exists, and no open PR makes this bump. `.opm-cli-version` and `cue.dev/x/k8s.io@v0` stay where they are.
- **`src/catalog_fixtures.cue`** (new, `@if(fixtures)`, never ships): asserts at package level that the derived `provides` of `opm` is `[]`. `task vet` loads it in its fixtures view. `opm` defines provider-fulfilled contracts (`backup@v1alpha1`, `backup-command@v1alpha1`) but implements none, and AGENTS.md says it never ships a stub transformer for one. The fixture turns that rule into a vet failure that names the contract.
- Re-vet everything in both views (`task vet`) and every rendered-output fixture (`task vet:fixtures`) on the new core, as part of `task check`.

No catalog member changes, no member moves `apiVersion` segment, and nothing is **BREAKING**.

## Before / After

No member's shape changes. The published catalog value gains one derived field from core:

**Before** (core `v2.0.0-beta.1`)

```cue
// src/cue.mod/module.cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-beta.1"

// cue export ./src (catalog root): no provides field
kind: "Catalog"
metadata: {...}
```

**After** (core `v2.0.0-beta.3`)

```cue
// src/cue.mod/module.cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-beta.3"

// cue export ./src (catalog root): derived by core's #Catalog, never authored here
kind: "Catalog"
metadata: {...}
provides: []

// src/catalog_fixtures.cue (fixtures view only)
@if(fixtures)
package opm
provides: []
```

Measured 2026-10-05 on a scratch copy of `origin/main` 7c0dc2d: `cue export ./src` differs only by `"provides": []`.

## Impact

- **library** (`lib-h2`, same round): `Catalog.Provides()` decodes `provides` from this catalog once the `opm` release carrying this change is published, and folds in Go for every older `opm` build. That release is the gate for removing the library fallback before GA. The removal is not part of this change.
- **opm-operator**: nothing to do here. Its test for an old catalog belongs to the operator's h2 work.
- **`modules` fleet, `opm-modules`, subscribing platforms**: nothing to do. They pick up the release through the cascade. A platform evaluates every catalog at its own core pin, so the field is present only where a platform's core is at beta.3 or later.
- **`cli` fixtures under `testing.opmodel.dev`**: nothing to do. The j3 consumer pin bump is not part of this change (below).
- **Release class:** section 1 `fix(deps)` (the published module changes: a new core pin and one derived field), section 2 `test(catalog)` (hidden; the fixture file never ships). PR title: `fix(deps): move the opm catalog onto core v2.0.0-beta.3`. This is a patch class and has no `!`; the AGENTS.md cascade-title rule gives the same title. The open release PR catalog_opm#145 (opm 4.7.0, another session) already carries #143's `feat`, so when this change merges release-please folds it into that PR, and the republish ships as 4.7.0, not as its own patch. That PR is not touched here.

## Principle V

No published surface is authored here. The `provides` field comes from core, and the fixture file never ships.

## Non-goals

- The j3 consumer pin bump (core-j3's binding of the attachment maps): it follows core-j3's release, as a separate change.
- Moving `#PreBoundRegistration._providerSet` (`src/resources/v1alpha1/transformer_registration.cue:114`) onto core's `provides`. core#120 lists it as not in that change, and no owner decision covers it. `#PreBoundRegistration` takes a bare `#transformers` map, not a catalog value, so it has no `provides` to read.
- Cutting or merging a release: release-please and catalog_opm#145 handle that.
