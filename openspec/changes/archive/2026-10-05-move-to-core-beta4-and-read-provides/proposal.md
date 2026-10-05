## Why

Core `v2.0.0-beta.4` (core#125, released by core#126) binds the key of every attachment map to the member's `metadata.fqn` as a hard vet error: component `#resources`, `#traits` and `#blueprints`, and the `#Catalog` member maps of the same names. The owner decided this in the beta.1 kernel plan walkthrough (task j3): "Bind attachment map keys to metadata.fqn on all five maps (component #resources/#traits/#blueprints and the catalog.cue member maps), as a hard vet error. Breaking core beta tightening: rewrite core's short-key pins and re-vet catalog_opm and the module fleet first." The re-vet against core beta.4 found `opm` clean: no published `opm` release (4.1.0 to 4.6.0) and nothing on `main` is mis-keyed. `opm` still pins `opmodel.dev/core@v2` at `v2.0.0-beta.3`, so its next release would not carry the tighter core floor. This change is the consumer pin bump for j3.

Core beta.3 (core#120, owner decision h2) gave every `#Catalog` a derived `provides`: the sorted provider-fulfilled contracts its own `#transformers` require. `opm` has carried it since #156. `#PreBoundRegistration` (`src/resources/v1alpha1/transformer_registration.cue:99-130`) still folds the same set out of a bare `#transformers` map through its own `_providerSet` (`:114-123`). Two copies of one rule can drift apart, and library ADR-012 exists to prevent that drift. catalog_opm#155 proposes reading core's `#Catalog.provides` and deleting the local fold. The pin is now past beta.3, so this change does that.

It implements no undelivered enhancement decision (j3 and h2 are walkthrough tasks, and #155 is an issue), so it carries no `enhancement.yaml`.

## What Changes

- **`src/cue.mod/module.cue`**: `opmodel.dev/core@v2` moves from `v2.0.0-beta.3` to `v2.0.0-beta.4`, with one `cue mod tidy` in `src/`. The diff touches only the core line (measured on a scratch copy of `origin/main` 0560990). `cue.dev/x/k8s.io@v0` and `.opm-cli-version` do not move. Every package is re-vetted in both views (`task vet`), and every rendered-output fixture is exported (`task vet:fixtures`).
- **`#PreBoundRegistration`** (`src/resources/v1alpha1/transformer_registration.cue`): its inputs, `#identity` and `#transformers`, stay. The local `_providerSet` fold is deleted. The helper builds a hidden `_catalog: c.#Catalog` from the two inputs and reads `provides` from `_catalog.provides`, which core derives. Because `#Catalog` stamps each transformer's `catalogVersion` from `#identity.version`, a `#transformers` map taken from a catalog other than the one `#identity` names is a conflict, so the claim still cannot disagree with the catalog it names (0015:D11).
- **`provides` is now sorted ascending** (core's `list.Sort`). The local fold emitted the map's insertion order. This is a rendered-output change in `v1alpha1`, which the alpha level allows (0010:D34). The set of contracts in each registration is unchanged, which the six rewritten `_testPreBound*` fixtures pin. A rendered `TransformerRegistration` whose provider catalog requires two or more provider contracts can list them in a different order. opm-operator sorts both sides before it compares (`internal/controller/transformerregistration_contracts.go`), so acceptance does not change.
- **`#transformers` must be catalog-shaped.** `_catalog` applies `#Catalog`'s `#transformers` constraint: keys are `#ImplFQNType`, values are `#ComponentTransformer`s. A provider catalog's own map, the documented input, already is. A hand-built map with bare keys is refused with `field not allowed`; only this repository's fixtures built one, and they are rewritten. This is an input tightening in `v1alpha1`, allowed by the alpha level (0010:D34).
- **`docs/cue-guard-closedness-workaround.md`** Rule 2: the `#PreBoundRegistration` example shows `_catalog` in place of `_providerSet`, and the closing paragraph's fixture count becomes six. `src/INDEX.md` is regenerated if the helper's first doc-comment sentence changes.

No member moves `apiVersion` segment, no definition is removed or renamed, and `opm` does not take a major. The call shape a provider module uses does not change, so there is no migration.

## Before / After

**Before** (core `v2.0.0-beta.3`)

```cue
// src/cue.mod/module.cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-beta.3"

// src/resources/v1alpha1/transformer_registration.cue
#PreBoundRegistration: #TransformerRegistration & {
	#identity: {
		modulePath: c.#ModulePathType
		version:    c.#VersionType
	}
	#transformers: [string]: _
	_providerSet: {
		for _, t in #transformers {
			if t.requiredTraits != _|_ {
				for fqn, m in t.requiredTraits if m.fulfilment == "provider" {(fqn): true}
			}
			if t.requiredResources != _|_ {
				for fqn, m in t.requiredResources if m.fulfilment == "provider" {(fqn): true}
			}
		}
	}
	spec: transformerRegistration: {
		catalog:  #identity.modulePath
		version:  #identity.version
		provides: [for fqn, _ in _providerSet {fqn}]
	}
}
```

**After** (core `v2.0.0-beta.4`)

```cue
// src/cue.mod/module.cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-beta.4"

// src/resources/v1alpha1/transformer_registration.cue
#PreBoundRegistration: #TransformerRegistration & {
	#identity: {
		modulePath: c.#ModulePathType
		version:    c.#VersionType
	}
	#transformers: [string]: _
	let T = #transformers
	_catalog: c.#Catalog & {
		metadata: {modulePath: #identity.modulePath, version: #identity.version}
		#transformers: T
	}
	spec: transformerRegistration: {
		catalog:  #identity.modulePath
		version:  #identity.version
		provides: _catalog.provides
	}
}
```

Measured 2026-10-05 on a scratch copy of `origin/main` 0560990 with the pin at beta.4: `cue vet ./...` and `cue vet -t fixtures ./...` pass with the helper and the rewritten fixtures. The six goldens keep their sets, and the multi case renders `provides: [".../traits/backup-command@v1alpha1", ".../traits/backup@v1alpha1"]`.

## Impact

- **`modules` fleet, `opm-modules`, subscribing platforms**: nothing to do in this change. When they move to the `opm` release that carries it, MVS raises them to core `v2.0.0-beta.4`, and j3 then refuses any attachment map whose key differs from the member's `metadata.fqn`. The j3 re-vet found the fleet and `opm-modules` clean. No module in the workspace calls `#PreBoundRegistration` today.
- **opm-operator**: nothing to do for acceptance. It re-derives `provides` and sorts both lists before comparing (0015:D11), so the new order is invisible to it. Its `test/fixtures/modules/README.md` and `backup_provider/components.cue` record a planned follow-up that moves the `backup_provider` fixture onto opm's `#PreBoundRegistration` once `backup` 0.1.0 is on GHCR. That fixture pins opm v4.4.4 today, so nothing breaks. The follow-up keeps the call shape it expects (`#identity` plus the catalog's own `#transformers`), because the inputs do not change.
- **Provider modules outside the workspace** that call `#PreBoundRegistration` with a catalog's own `#transformers`: nothing to do; their next render lists `provides` sorted. One that builds the map by hand must key it by transformer fqn with `#ComponentTransformer` values.
- **library**: nothing to do. `Catalog.Provides()` already decodes `provides` from an `opm` build that carries it. The library takes core beta.4 through its own pin change.
- **`cli` fixtures under `testing.opmodel.dev`**: nothing to do.
- **Release class:** section 1 `fix(deps)` (the published module gains the core beta.4 floor), section 2 `fix(resources)` (a published `v1alpha1` helper drops its duplicate fold and its output order changes). PR title: `fix(deps): move the opm catalog onto core v2.0.0-beta.4 and read its provides`, a patch class with no `!`. `opm` stays on `@v4`. The open release PR catalog_opm#145 (opm 4.7.0) already carries a `feat`, so release-please folds this change into it. The PR closes catalog_opm#155.

## Principle V

Nothing is added to the published surface. The helper swaps one hidden field for another; its inputs and its rendered fields stay.

## Non-goals

- Binding `#transformers` keys to their `fqn`: core leaves them unbound under j3, and `opm` authors them as `(t.#X.metadata.fqn)` already.
- Removing the library's Go fallback for catalogs without `provides`: it is removed before GA, after this `opm` release is published (owner decision h2).
- Cutting or merging a release: release-please and catalog_opm#145 handle that.

## Enhancement

None.
