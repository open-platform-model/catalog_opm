## Why

`#ResourceNameTrait` has been deprecated since `catalogs/opm` 2.0.0-alpha.7 (sweep 1 of the staged retirement recorded as enhancement 0019 D25), and its only user, `modules/istio_ambient`, moved to `metadata.resourceName` in sweep 2. Two name authorities still coexist in the seven workload transformers through the `#WorkloadName` seam. This change is sweep 3: the trait, its wrapper, its schema and the seam are deleted, leaving `#component.#names.resourceName` as the one source of a workload's rendered name (0019 D15). Now, because the deletion is a member removal and therefore a major crossing, and every consumer still pins `@v2`: nobody has re-pinned to `@v3` yet, so the crossing costs the re-pin they already owe and nothing more.

## What Changes

- **BREAKING** `opm/traits/v1beta1/resource_name.cue` is deleted: `#ResourceNameTrait`, the `#ResourceName` component wrapper and `#ResourceNameSchema`. The member key `opmodel.dev/catalogs/opm/traits/resource-name@v1beta1` leaves the catalog. This is a removal, not a reshape, so no member moves to a new `apiVersion` segment.
- `#WorkloadName` is deleted from `opm/transformers/name_helpers.cue`. `#ServiceName` is untouched.
- The seven workload transformers (deployment, statefulset, daemonset, job, cronjob, hpa, pdb) drop the trait from `optionalTraits` and read `#component.#names.resourceName` directly for the object name (HPA: `scaleTargetRef.name`).
- The seven exact-name fixtures attach `metadata: resourceName:` instead of `tr.#ResourceName` plus `spec.resourceName`. Every pinned name and every HPA/PDB/StatefulSet parity guard keeps its string. The StatefulSet exact fixture's comments are rewritten to state what they prove without the trait (design D-C).
- **Major crossing**: `opmodel.dev/catalogs/opm@v3` becomes `@v4` (`opm/cue.mod/module.cue`, `identity.ModulePath`; `identity.Version` to `4.0.0` through `opm catalog version set`; `CLAUDE.md`, `README.md`, `openspec/config.yaml`). Member fqns derive from the major-free `RegistryPath`, so no contract key changes.
- `docs/name-constraints.md` § "Transformers read names, never derive them" loses the seam sentences; `opm/INDEX.md` is regenerated.

## Before / After

**Before**

```cue
// opm/traits/v1beta1/resource_name.cue
#ResourceNameTrait: c.#Trait & {
	metadata: fqn: "\(id.kindPrefix.traits)/resource-name@v1beta1"
	optional:  bool | *true
	appliesTo: [res.#ContainerResource]
	spec: resourceName: #ResourceNameSchema
}
#ResourceName: c.#Component & {#traits: (#ResourceNameTrait.metadata.fqn): #ResourceNameTrait}
#ResourceNameSchema: string

// opm/transformers/name_helpers.cue
#WorkloadName: {
	#comp!: _
	out: [
		if #comp.spec.resourceName != _|_ {#comp.spec.resourceName},
		#comp.#names.resourceName,
	][0]
}

// deployment_transformer.cue and the six siblings
optionalTraits: (tr.#ResourceNameTrait.metadata.fqn): tr.#ResourceNameTrait
metadata: name: (#WorkloadName & {#comp: #component}).out

// exact-name fixture (deployment; the other six follow the same shape)
_testDeployExactComponent: {
	res.#Container
	tr.#ResourceName
	metadata: name: "istiod"
	spec: resourceName: "istiod"
}

// opm/cue.mod/module.cue, opm/identity/identity.cue
module:     "opmodel.dev/catalogs/opm@v3"
ModulePath: "opmodel.dev/catalogs/opm@v3"
Version:    "3.0.0"
```

**After**

```cue
// opm/traits/v1beta1/resource_name.cue: deleted
// #WorkloadName: deleted; #ServiceName unchanged

// deployment_transformer.cue and the six siblings
metadata: name: #component.#names.resourceName

// exact-name fixture
_testDeployExactComponent: {
	res.#Container
	metadata: {name: "istiod", resourceName: "istiod"}
}
_testDeployExactNameResolves: "\(_testDeployExactTransformer.metadata.name)" & "istiod"

// opm/cue.mod/module.cue, opm/identity/identity.cue
module:     "opmodel.dev/catalogs/opm@v4"
ModulePath: "opmodel.dev/catalogs/opm@v4"
Version:    "4.0.0" // opm catalog version set; core asserts VersionMajor == Major
```

## Impact

1. **Release class: `feat!:`**, cutting `opm-v4.0.0`. Does not rely on the v2 alpha line (closed at 2.0.0). The publish compat gate refuses a member removal within `@v3` (`traits/resource-name@v1beta1` is reachable through seven `optionalTraits` maps), which is what forces the crossing. `branch-publish.yml` derives `v4.0.0-0.dev.*` from the new path.
2. **Rendered output: byte-identical** for every component that renders today. A default-named component already resolved through the seam's `#names` arm; an exact-named component (`istio_ambient`, on `metadata.resourceName` since sweep 2) never reached the seam's trait arm. Gate: the `library` parity harness (`library/testdata/parity`) against a `-dev` pre-release, plus `cue eval -c` on every name guard in the seven files.
3. **`modules` fleet (`main`, v2 staging, publish disabled)**: all 20 modules pin `catalogs/opm@v2` at 2.0.0-alpha.7 and still owe the `@v3` re-pin. No module attaches the trait (measured 2026-08-30). They re-pin straight to `@v4` once 4.0.0 is on GHCR. The `v1` branch is untouched.
4. **Subscribing platforms** (the `opm-operator` sample Platform, the `cli` DefaultPlatformTemplate seed): re-pin to `@v4`; FQN subscriptions see no key change. The same edit they owe for `@v3`.
5. **`cli` fixtures under `testing.opmodel.dev`, `opm-operator/test/fixtures`, `library/testdata`**: none attach the trait (measured 2026-08-30); they re-pin through `task deps:pins:fixtures` in their own repos.
6. **Kernel floor**: unchanged, `library` >= v1.0.0-alpha.14 (set at alpha.7).

## Enhancement

`enhancements/0019` D15 (a transformer reads the primary object's name from `#component.#names`; the trait deletion it states) and D25 (the staged retirement; this is sweep 3, and D25 records why the deletion crosses a major). Closes the catalog half of open-platform-model/catalog_opm#44. `enhancement.yaml` declares D15 and D25.
