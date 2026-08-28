## Why

Every workload transformer in `opm/` rebuilds the rendered object's name by hand through `#WorkloadName` (`opm/transformers/name_helpers.cue`): the exact name from `#ResourceNameTrait` when set, otherwise `"\(#context.#moduleInstanceMetadata.name)-\(#component.metadata.name)"`. The helper exists because HPA and PDB must target the workload by a byte-identical name, and the failure when they drift (an autoscaler pointed at nothing) is silent.

Since `library` v1.0.0-alpha.14 the kernel fills `#component` with the whole evaluated component, so `#component.#names.resourceName` (core's single source of truth, `core@v2.0.0-alpha.6`) is readable inside `#transform`. Enhancement 0019 D15 makes reading it the contract: a transformer reads the primary object's name, never derives it. This is the first of three catalog slices and takes the seven transformers where drift is silent.

This slice is the first sweep of a staged retirement of `#ResourceNameTrait` (user decision 2026-08-27, revising D15's "removed outright"): introduce the read and publish; migrate the `modules` fleet; delete the trait in a later change.

## What Changes

- `#WorkloadName` becomes the single seam between the two name authorities that coexist during the deprecation window: the deprecated trait override, else `#component.#names.resourceName`. The `#instance` input is removed; the hand-rolled formula is gone.
- The seven `#WorkloadName` callers (deployment, statefulset, daemonset, job, cronjob, hpa, pdb) keep calling it, so the HPA `scaleTargetRef.name` and the PDB's own name stay byte-identical to the workload's name.
- StatefulSet `spec.serviceName`: `#ExposeTrait` is optional on the StatefulSet transformer, so the outer `expose` guard stays; the hand-rolled fallback for a component without `#Expose` becomes `#component.#names.dns.short` (a read, the value a default-named headless Service would carry), and the inner `expose.name != _|_` guard goes (`name!` since D22).
- `#ResourceNameTrait`, the `#ResourceName` wrapper and `#ResourceNameSchema` are marked deprecated in their doc comments, pointing at `metadata.resourceName`. No behaviour change.
- In-file fixtures for the seven transformers gain `#instance: {name, namespace, uuid}` so `#names` resolves outside `#Module` (rule already in `docs/name-constraints.md`); job and cronjob, which have no fixtures today, get one; each kind gets a default-named fixture pinned by interpolation; PDB and StatefulSet gain name-parity guards matching the HPA one.

Not breaking for any rendered output: default-named components already render `<instance>-<component>`, which is exactly what D16 made `#names.resourceName` compute; trait users keep the trait's value through the seam.

## Before / After

**Before**

```cue
#WorkloadName: {
	#comp!:     _
	#instance!: string
	out: [
		if #comp.spec.resourceName != _|_ {#comp.spec.resourceName},
		"\(#instance)-\(#comp.metadata.name)",
	][0]
}

// deployment_transformer.cue (and the six siblings)
metadata: name: (#WorkloadName & {
	#comp:     #component
	#instance: #context.#moduleInstanceMetadata.name
}).out
```

**After**

```cue
// #WorkloadName resolves a workload's rendered object name during the
// #ResourceNameTrait deprecation window: the trait's exact name when set,
// otherwise the component's own #names.resourceName (0019 D15).
#WorkloadName: {
	#comp!: _
	out: [
		if #comp.spec.resourceName != _|_ {#comp.spec.resourceName},
		#comp.#names.resourceName,
	][0]
}

// deployment_transformer.cue (and the six siblings)
metadata: name: (#WorkloadName & {#comp: #component}).out

// resource_name.cue
// Deprecated: set #Component.metadata.resourceName instead; the core field
// also carries the DNS variants. Removed in a later catalog release.
#ResourceNameTrait: c.#Trait & {...}
```

## Impact

- **Rendered output:** byte-identical for every default-named and every trait-named component. Gate: the `library` parity harness (`library/testdata/parity`) against a `-dev` pre-release of this catalog, plus `cue eval -c` of every in-file name guard (plain `cue vet` accepts an incomplete `#names`, see design Risks).
- **Kernel floor:** a `#names` read against a kernel that strips definitions fails with an empty-disjunction error, so consumers of the release carrying this change need `library` >= v1.0.0-alpha.14 (`cli` pins alpha.17, `opm-operator` pins alpha.14). This is the one contract change and is why the release class is `feat!:` (advances the alpha counter; no major crossing, no `apiVersion` segment moves).
- **`modules` fleet:** no action for this slice. `istio_ambient` (`components_control_plane.cue`, the only `#ResourceName` user in the tree) keeps rendering `istiod`; its migration to `metadata.resourceName` is the second sweep, in `modules`.
- **Subscribing platforms, `cli` fixtures under `testing.opmodel.dev`:** no authoring change; they pick up the kernel floor with the release.
- Relies on the v2 alpha line: yes (trait deprecation without an `apiVersion` segment move is the alpha stance).

## Enhancement

`enhancements/0019` D15 (transformers read `#component.#names` for the primary object), first slice; D15's deletion of `#ResourceNameTrait` is deliberately deferred to a later change and D15 needs a dated revision note recording the staged retirement. `enhancement.yaml` declares D15.
