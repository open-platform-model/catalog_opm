## Why

Core `v2.0.0-alpha.8` gave `#Catalog` three contract member maps (`#resources`, `#traits`, `#blueprints`, enhancement 0015 D1) so that "this catalog defines contract X" is a fact of the artifact rather than a derivation over its transformers. The maps mean nothing until the first-party catalogs populate them: the inventory core derives since `v2.0.0-alpha.9` (`#Platform.#contracts`) reads only what is listed, and a catalog that lists nothing makes the readiness answer a vacuous "fulfilled" (0015 `06-operational.md`, Rollback). Both catalogs here still pin `alpha.6`. This change bumps them and lists every member, with a gate so a member cannot be added without being listed.

## What Changes

- `opm/cue.mod/module.cue` and `k8s/cue.mod/module.cue`: core pin `v2.0.0-alpha.6` to `v2.0.0-alpha.9` (the current release; `task deps:update` resolves to it), through the workspace's `task deps:update` (or its per-module equivalent, `cue mod get`).
- `opm/catalog.cue`: `#resources` (11 members across `v1beta1` and `v1alpha1`), `#traits` (26 across `v1beta1`, plus the two `v1alpha1` backup traits once `backup-traits-alpha` has landed) and `#blueprints` (5, `v1beta1`), each entry keyed by the member's own `metadata.fqn` exactly as `#transformers` is. The header comment saying primitives are not enumerated is rewritten.
- `k8s/catalog.cue`: `#resources` (29 members across `v1` and `v2`). No traits or blueprints exist in the raw catalog; the maps stay absent, which is empty.
- `.tasks/listing.sh` and `task vet:listing`, wired into `task check`: every member definition under `<module>/<kind>/<apiVersion>/` is a key of the corresponding map, and every key names a member. Closes the completeness hole `core` cannot check.
- `CLAUDE.md`: the listing rule beside the filing rule.

Not in this change: the trait `optional` postures, the member shapes, the `#transformers` map. Nothing about any member changes; the catalog root value grows three maps.

## Before / After

**Before**

```cue
// opm/catalog.cue
c.#Catalog
metadata: {modulePath: id.ModulePath, version: id.Version, description: "..."}

#transformers: {
	(t.#ConfigMapTransformer.metadata.fqn): t.#ConfigMapTransformer
	// ...
}
```

**After**

```cue
// opm/catalog.cue
import (
	c "opmodel.dev/core@v2"
	id "opmodel.dev/catalogs/opm/identity"
	t "opmodel.dev/catalogs/opm/transformers"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	resa "opmodel.dev/catalogs/opm/resources/v1alpha1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
	tra "opmodel.dev/catalogs/opm/traits/v1alpha1"
	bp "opmodel.dev/catalogs/opm/blueprints/v1beta1"
)

c.#Catalog
metadata: {modulePath: id.ModulePath, version: id.Version, description: "..."}

#resources: {
	(res.#ConfigMapsResource.metadata.fqn): res.#ConfigMapsResource
	(res.#ContainerResource.metadata.fqn):  res.#ContainerResource
	// ... every #Resource under opm/resources/
	(resa.#NamespacesResource.metadata.fqn): resa.#NamespacesResource
}

#traits: {
	(tr.#DisruptionBudgetTrait.metadata.fqn): tr.#DisruptionBudgetTrait
	// ... every #Trait under opm/traits/
	(tra.#BackupTrait.metadata.fqn):          tra.#BackupTrait
}

#blueprints: {
	(bp.#StatelessWorkloadBlueprint.metadata.fqn): bp.#StatelessWorkloadBlueprint
	// ... every #Blueprint under opm/blueprints/
}

#transformers: {
	// unchanged
}
```

Each map's pattern constraint in core stamps the member's `modulePath` (`<registryPath>/<kind>/<apiVersion>`) and `catalogVersion`; every member already authors exactly those values from the identity package, so listing is agreement, not migration.

## Impact

- **`modules` fleet:** nothing to do. Modules import member packages, never a catalog's root package, and no member changes.
- **Subscribing platforms:** nothing to do. A platform still on core `alpha.7` or older evaluates a listing catalog unchanged: measured 2026-09-13 on cue v0.17.1, a closed definition admits an undeclared hidden map, so the three maps are inert there (no stamps, no inventory) rather than refused. A platform on `alpha.8` gets the stamps; one on `alpha.9` also derives `#contracts` over them (core `platform-contract-inventory`, released 2026-09-13), which is what the library's `Platform.Contracts()` and the operator's readiness condition read.
- **`cli` fixtures under `testing.opmodel.dev`:** nothing to do. `opm catalog publish` enumerates members by walking packages; the maps are extra root fields it neither reads nor refuses (verified by the dry-run gate in section 2).
- **Release class:** `fix(deps)` for the pin bump (both modules release), `feat(opm)` and `feat(k8s)` for the listings, `chore(tasks)` for the gate. `opm` goes to its next minor, `k8s` likewise. No member moves segment. The `opm` module is on the stable v4 line; nothing here relies on a pre-release line.
- **Ordering with `backup-traits-alpha`:** independent. If this lands first, the listing gate makes that change's section 2 list its two traits; if that lands first, section 2 here lists them.

## Enhancement

`enhancements/0015` D1, the catalog half: the first-party catalogs publish their contracts as members. `enhancement.yaml` declares it.
