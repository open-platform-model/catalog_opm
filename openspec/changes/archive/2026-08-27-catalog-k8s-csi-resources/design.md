## Context

Files added: `k8s/resources/v1/csidriver.cue`, `k8s/resources/v1/volumesnapshotclass.cue`, `k8s/transformers/csidriver_transformer.cue`, `k8s/transformers/volumesnapshotclass_transformer.cue`; files edited: `k8s/schemas/storage.cue` (two schemas), `k8s/catalog.cue` (two entries), `k8s/INDEX.md` (generated). Segment `v1` in both cases. Pattern source: `k8s/resources/v1/storageclass.cue` and `k8s/transformers/storageclass_transformer.cue`. Depends on `catalog-names-readonly-k8s` for the read idiom and the docs subsection it extends.

## Goals / Non-Goals

**Goals:**
- Two members that follow the neighbouring `storageclass` member byte for byte in structure.
- `CSIDriver` renders its authored name verbatim; `VolumeSnapshotClass` honours `metadata.resourceName`.

**Non-Goals:**
- `VolumeSnapshot` / `VolumeSnapshotContent` (instance-level objects, no module asks for them).
- Validating CSI spec semantics beyond the upstream shape (open schema, raw family stance).

## Decisions

**D-A. `CSIDriver` name is required and verbatim.**

```cue
#CSIDriverSchema: {
	metadata: {
		name!: string
		annotations?: [string]: string
	}
	spec: {
		attachRequired?:     bool
		podInfoOnMount?:     bool
		volumeLifecycleModes?: [...string]
		storageCapacity?:    bool
		fsGroupPolicy?:      string
		requiresRepublish?:  bool
		seLinuxMount?:       bool
		tokenRequests?: [...{audience!: string, expirationSeconds?: int}]
		nodeAllocatableUpdatePeriodSeconds?: int
		preventPodSchedulingIfMissing?:      bool
		serviceAccountTokenInSecrets?:       bool
		...
	}
}
```
(`metadata` also carries `labels?` and `annotations?` like every other `k8s/schemas` member; `fsGroupPolicy` and `volumeLifecycleModes` MAY narrow to their upstream enums the way `#StorageClassSchema` narrows `reclaimPolicy`.) `name!` with no type narrowing: a CSIDriver name is a dotted domain-style string, so neither `#NameType` nor `#ServiceNameType` applies; `#ObjectNameType` (253-rune subdomain) is the right ceiling if any. The rationale (kubelet `CSINodeInfo` registration, `StorageClass.provisioner`) goes in a `// WHY:` block above the field, not in the ≤6-line doc comment. The transformer's `metadata.name: _csi.metadata.name` is the exact-name carve-out (D19), same form as `apiservice_transformer.cue:47`. The resource declares no `#nameConstraint`: per `docs/name-constraints.md` the slot exists for names that land in a DNS label position, and neither kind's name does (no `k8s/` resource declares one today).

**D-B. `VolumeSnapshotClass` follows `StorageClass`.**

```cue
#VolumeSnapshotClassSchema: {
	metadata?: annotations?: [string]: string
	driver!:         string
	deletionPolicy!: "Delete" | "Retain"
	parameters?: [string]: string
	...
}
```
Transformer: `metadata.name: #component.#names.resourceName`, cluster-scoped, labels from `#context.labels`. The override ceiling is `#ObjectNameType` (D20); nothing further to declare. Closedness: both schemas open (`...`) and hand-written per the raw family convention in `k8s/schemas/` (no vendored k8s types dependency in `k8s/cue.mod`, and none is added).

**D-C. Category labels.** Both carry `"resource.opmodel.dev/category": "storage"` and `"core.opmodel.dev/resource-category": "storage"` on the transformer, matching `storageclass`.

## Research & Decisions

### Whether CSIDriver is exact-name
**Context**: D19 re-enumerates carve-outs on this catalog's evidence.
**Explored**: D19's rationale (kubelet `CSINodeInfo` registration and `StorageClass.provisioner` reference the driver by name; `experiments/09-name-constraint-propagation/` in `enhancements/0019`).
**Decision**: exact; authored `metadata.name!`.
**Rationale**: a prefixed or overridden name breaks provisioning silently.

### Whether VolumeSnapshotClass honours the override
**Context**: same D19 contrast as StorageClass.
**Explored**: `snapshot.storage.k8s.io/v1` names are referenced by `VolumeSnapshot.spec.volumeSnapshotClassName`, label-shaped.
**Decision**: read `#names.resourceName`.
**Rationale**: identical position to `storageClassName`; D19 keeps StorageClass in the sweep for the same reason.

## Risks / Trade-offs

- Snapshot CRDs are not installed on every cluster -> the member exists; a platform that lacks the CRD simply has no consumer; no catalog-side check is possible or wanted.
- Open schemas admit typos in spec fields -> raw family stance; unchanged from every other `k8s/` member.
- `k8s/resources/v1/object.cue:17` names VolumeSnapshotClass as the escape-hatch example -> reword that doc comment so `INDEX.md` does not send users to `object` for a kind that now has a member.
- D19's carve-out prose mentions `crd`; `k8s/` has no CRD member -> the docs entry lists apiservice, object, csidriver only.

## Durable decisions

- "CSIDriver is a `catalogs/k8s` exact-name kind; VolumeSnapshotClass honours the override" -> the `k8s/` subsection of `docs/name-constraints.md` created by `catalog-names-readonly-k8s` gains both entries (create it if absent).
