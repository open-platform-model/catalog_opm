## Why

`catalogs/k8s@v1` has no `CSIDriver` and no `VolumeSnapshotClass` kind. The first storage module to consume the raw catalog (an `openebs_zfs` module, enhancement 0019 D19's motivating case) needs both: a `CSIDriver` whose name is a contract with kubelet's `CSINodeInfo` registration and every `StorageClass.provisioner` (dotted by convention, `zfs.csi.openebs.io`, rendered verbatim), and a `VolumeSnapshotClass` that is label-shaped and honours the `metadata.resourceName` override like `StorageClass`. D19 adds both as typed members riding the names sweep; this change is the additive half, after `catalog-names-readonly-k8s` has settled the read rule they follow.

## What Changes

- New `#CSIDriverResource` (`k8s/resources/v1/csidriver.cue`, `storage.k8s.io/v1`) with `#CSIDriver` wrapper and `#CSIDriverSchema` in `k8s/schemas/storage.cue`; new `#CSIDriverTransformer` rendering `metadata.name` verbatim from the authored spec (exact-name kind).
- New `#VolumeSnapshotClassResource` (`k8s/resources/v1/volumesnapshotclass.cue`, `snapshot.storage.k8s.io/v1`) with wrapper and schema; new `#VolumeSnapshotClassTransformer` reading `#component.#names.resourceName` (override-honouring).
- Both transformers enumerated in `k8s/catalog.cue`; `INDEX.md` regenerated.

Additive only. Justification against Principle V: a named downstream module needs both kinds and cannot express them without falling back to raw manifests beside the ModuleInstance, which D19 rejects as a permanent split of ownership.

## Before / After

**Before**

```cue
none
```

**After**

```cue
// k8s/resources/v1/csidriver.cue
#CSIDriverResource: c.#Resource & {
	metadata: {name: "csidriver", apiVersion: "v1", fqn: "\(id.kindPrefix.resources)/csidriver@v1", ...}
	spec: csidriver: schemas.#CSIDriverSchema
}
#CSIDriver: c.#Component & {#resources: (#CSIDriverResource.metadata.fqn): #CSIDriverResource}

// k8s/schemas/storage.cue
#CSIDriverSchema: {
	metadata: name!: string // exact: kubelet registration + StorageClass.provisioner
	spec: {...}             // open over storage.k8s.io/v1 CSIDriverSpec
}

// k8s/resources/v1/volumesnapshotclass.cue
#VolumeSnapshotClassResource: c.#Resource & {
	metadata: {name: "volumesnapshotclass", apiVersion: "v1", fqn: "\(id.kindPrefix.resources)/volumesnapshotclass@v1", ...}
	spec: volumesnapshotclass: schemas.#VolumeSnapshotClassSchema
}

// k8s/transformers/csidriver_transformer.cue
output: metadata: name: _csi.metadata.name // exact — CSINodeInfo / provisioner contract

// k8s/transformers/volumesnapshotclass_transformer.cue
output: metadata: name: #component.#names.resourceName
```

## Impact

- **Release class:** `feat:` on the `k8s` module (two new members, two new transformers). No `apiVersion` segment moves; `apiVersion: v1` mirrors upstream (`storage.k8s.io/v1`, `snapshot.storage.k8s.io/v1`, 0010 D48). Relies on the alpha line: no.
- **`modules` fleet, platforms, `cli` fixtures:** nothing to do; new members are opt-in. The `openebs_zfs` module is the first intended consumer.
- **Floors:** `#names` comes from the pinned `core@v2.0.0-alpha.6` (`k8s/cue.mod/module.cue`, no bump); rendering the VolumeSnapshotClass transformer needs the kernel fill (`library` >= v1.0.0-alpha.14), a floor `catalog-names-readonly-k8s` already raises.

## Enhancement

`enhancements/0019` D19 (the two typed resources that ride the `catalogs/k8s` sweep, CSIDriver as an exact-name carve-out). `enhancement.yaml` declares D19.
