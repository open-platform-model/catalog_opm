## Why

Core `v2.0.0-beta.4` (core#125, released by core#126) binds the key of every attachment map to the member's `metadata.fqn` as a hard vet error: component `#resources`, `#traits` and `#blueprints`, and the `#Catalog` member maps of the same names. The owner decided this in the beta.1 kernel plan walkthrough (task j3): "Bind attachment map keys to metadata.fqn on all five maps (component #resources/#traits/#blueprints and the catalog.cue member maps), as a hard vet error. Breaking core beta tightening: rewrite core's short-key pins and re-vet catalog_opm and the module fleet first." The re-vet against core beta.4 found `opm` clean: no published `opm` release (4.1.0 to 4.6.0) and nothing on `main` is mis-keyed. `opm` still pins `opmodel.dev/core@v2` at `v2.0.0-beta.3`, so its next release would not carry the tighter core floor. This change is the consumer pin bump for j3.

Core beta.3 (core#120, owner decision h2) gave every `#Catalog` a derived `provides`: the sorted provider-fulfilled contracts its own `#transformers` require. `opm` has carried it since #156. `#PreBoundRegistration` (`src/resources/v1alpha1/transformer_registration.cue:99-130`) still folds the same set out of a bare `#transformers` map through its own `_providerSet` (`:114-123`). Two copies of one rule can drift apart, and library ADR-012 exists to prevent that drift. catalog_opm#155 proposes reading `#catalog.provides` and deleting the local fold. The pin is now past beta.3, so this change does that.

It implements no undelivered enhancement decision (j3 and h2 are walkthrough tasks, and #155 is an issue), so it carries no `enhancement.yaml`.

## What Changes

- **`src/cue.mod/module.cue`**: `opmodel.dev/core@v2` moves from `v2.0.0-beta.3` to `v2.0.0-beta.4`, with one `cue mod tidy` in `src/`. The diff touches only the core line (measured on a scratch copy of `origin/main` 0560990). `cue.dev/x/k8s.io@v0` and `.opm-cli-version` do not move. Every package is re-vetted in both views (`task vet`), and every rendered-output fixture is exported (`task vet:fixtures`).
- **`#PreBoundRegistration`** (`src/resources/v1alpha1/transformer_registration.cue`): its two inputs, `#identity` and `#transformers`, are replaced by one, `#catalog: c.#Catalog`, which is the provider catalog's own root value. `spec.transformerRegistration` reads `catalog` and `version` from `#catalog.metadata`, and reads `provides` from `#catalog.provides`, which core derives. `_providerSet` is deleted. Because `#catalog` is typed `c.#Catalog`, a hand-built value cannot supply a `provides` that disagrees with its own `#transformers`: core's derived list and the authored one conflict.
- **`provides` is now sorted ascending** (core's `list.Sort`). The local fold emitted the map's insertion order. The set of contracts in each registration is unchanged, which the six rewritten `_testPreBound*` fixtures pin. A rendered `TransformerRegistration` whose provider catalog requires two or more provider contracts can list them in a different order. opm-operator sorts both sides before it compares (`transformerregistration_contracts.go`), so acceptance does not change.
- **`docs/cue-guard-closedness-workaround.md`** Rule 2: the `#PreBoundRegistration` example and the fixture count follow the new input. `src/INDEX.md` is regenerated, because the helper's doc comment changes.

**BREAKING** for a provider module that calls `#PreBoundRegistration`, within `v1alpha1`: the old inputs are gone. `v1alpha1` promises nothing (0010:D34), so no member moves `apiVersion` segment and `opm` does not take a major. The workspace has no caller (searched: `modules`, `opm-modules`, `cli`, `opm-operator`, `library` and GitHub code search across both owners). Migration:

```cue
// before
res.#PreBoundRegistration & {
	metadata: name: "k8up"
	#identity:     {modulePath: id.ModulePath, version: id.Version}
	#transformers: k8up.#transformers
}

// after: k8up is the provider catalog's root package, e.g. k8up "opmodel.dev/catalogs/k8up@v1"
res.#PreBoundRegistration & {
	metadata: name: "k8up"
	#catalog: k8up
}
```

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
	#catalog: c.#Catalog
	spec: transformerRegistration: {
		catalog:  #catalog.metadata.modulePath
		version:  #catalog.metadata.version
		provides: #catalog.provides
	}
}
```

Measured 2026-10-05 on a scratch copy of `origin/main` 0560990 with the pin at beta.4: `cue vet ./...` and `cue vet -t fixtures ./...` pass. A registration built from a two-transformer synthetic catalog renders `provides: [".../traits/backup-command@v1alpha1", ".../traits/backup@v1alpha1"]`. A hand-built `c.#Catalog` with no transformers and `provides: [".../traits/backup@v1alpha1"]` fails with `provides: incompatible list lengths (0 and 1)`. Passing the imported `opmodel.dev/catalogs/opm@v4` root as `#catalog` renders `catalog: "opmodel.dev/catalogs/opm@v4"`, `version: "4.6.0"`, `provides: []`.

## Impact

- **`modules` fleet, `opm-modules`, subscribing platforms**: nothing to do in this change. When they move to the `opm` release that carries it, MVS raises them to core `v2.0.0-beta.4`, and j3 then refuses any attachment map whose key differs from the member's `metadata.fqn`. The j3 re-vet found the fleet and `opm-modules` clean. No consumer of `#PreBoundRegistration` exists in the workspace.
- **Provider modules outside the workspace** that call `#PreBoundRegistration`: they rewrite the call as in the migration above. A stale call leaves `catalog` and `version` incomplete, so the render fails on the required spec fields (0010:D28) instead of shipping an empty claim. Task 2.5 measures this.
- **opm-operator**: nothing to do. Acceptance re-derives `provides` and sorts both lists before comparing (0015:D11), so the new order is invisible to it.
- **library**: nothing to do. `Catalog.Provides()` already decodes `provides` from an `opm` build that carries it. The library takes core beta.4 through its own pin change.
- **`cli` fixtures under `testing.opmodel.dev`**: nothing to do.
- **Release class:** section 1 `fix(deps)` (the published module gains the core beta.4 floor), section 2 `fix(resources)` (a published `v1alpha1` helper drops its duplicate fold and its output order changes). PR title: `fix(deps): move the opm catalog onto core v2.0.0-beta.4 and read its provides`, a patch class with no `!`. `opm` stays on `@v4`. The open release PR catalog_opm#145 (opm 4.7.0) already carries a `feat`, so release-please folds this change into it. The PR closes catalog_opm#155.

## Principle V

Nothing is added to the published surface. The helper loses an input and a hidden field, and gains one definition field that replaces both inputs.

## Non-goals

- Binding `#transformers` keys to their `fqn`: core leaves them unbound under j3, and `opm` authors them as `(t.#X.metadata.fqn)` already.
- Removing the library's Go fallback for catalogs without `provides`: it is removed before GA, after this `opm` release is published (owner decision h2).
- Cutting or merging a release: release-please and catalog_opm#145 handle that.

## Enhancement

None.
