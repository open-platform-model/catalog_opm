## 1. k8s/schemas/storage.cue

- [x] 1.1 Add `#CSIDriverSchema` (D-A, all eleven `CSIDriverSpec` fields, `metadata.name!` with its `// WHY:` block above the doc comment) and `#VolumeSnapshotClassSchema` (D-B), following `#StorageClassSchema`.

## 2. k8s/resources/v1

- [x] 2.1 `csidriver.cue`: `#CSIDriverResource` and `#CSIDriver` wrapper, modelled on `storageclass.cue`.
- [x] 2.2 `volumesnapshotclass.cue`: `#VolumeSnapshotClassResource` and `#VolumeSnapshotClass` wrapper.

## 3. k8s/transformers

- [x] 3.1 `csidriver_transformer.cue`: `#CSIDriverTransformer`, `metadata.name` verbatim with an `// exact` comment; fixtures modelled on the `k8s/` idiom introduced by `catalog-names-readonly-k8s` (`opm/transformers/service_transformer.cue` as the origin): one pinned by interpolation to the authored name, one with `metadata.resourceName` set proving it is ignored (`#instance` not needed, nothing reads `#names`).
- [x] 3.2 `volumesnapshotclass_transformer.cue`: `#VolumeSnapshotClassTransformer` reading `#component.#names.resourceName`; default and override fixtures with `#instance` on the component stub, pinned by interpolation, checked with `cue eval -c`.
- [x] 3.3 `k8s/catalog.cue`: enumerate both transformers.
- [x] 3.4 `k8s/resources/v1/object.cue`: reword the doc comment that cites VolumeSnapshotClass as the escape-hatch example.

## 4. Durable decisions

- [x] 4.1 `docs/name-constraints.md`, `k8s/` subsection: add CSIDriver (exact) and VolumeSnapshotClass (override-honouring).

## 5. Verification

- [x] 5.1 `task generate:index`.
- [x] 5.2 `task check`.
