## Context

Files: every `k8s/transformers/*_transformer.cue` (27 files; 25 in the rewrite, `apiservice` and `object` audited). Members under `k8s/resources/v1/`, `k8s/resources/v2/` and `k8s/schemas/` are untouched. Depends on the `opm/` slices only for the docs section they land in; the code is independent.

The `k8s/` transformers are mechanically uniform (one `_name` line per file; `cue fmt` aligns it as `_name:   "..."` in `deployment`, `namespace` and `secret`, and the webhooks sit one line lower), which is what makes a 25-file rewrite one coherent change rather than 25. No `_test*` fixture and no `#instance` exists anywhere in `k8s/` today.

## Goals / Non-Goals

**Goals:**
- One primary-object name source in `k8s/`: `#component.#names.resourceName`.
- `metadata.resourceName` honoured by every kind whose name is not an external contract.
- The exact-name list for this catalog recorded in code comments and in `docs/name-constraints.md`.

**Non-Goals:**
- New kinds (`CSIDriver`, `VolumeSnapshotClass`): next change.
- Cross-object references in passthrough specs (`hpa.spec.scaleTargetRef`, `role_binding.roleRef`, `statefulset.spec.serviceName`): these are user-authored in the raw catalog and pass through untouched; the raw family does not derive them and so cannot drift.

## Decisions

**D-A. The rewrite is one line per file.**

```cue
_name: #component.#names.resourceName
```
No helper: there is no second authority in `k8s/` (no trait), so no seam is needed. Applied with one regex that tolerates the alignment variants, then `cue fmt`:

```sh
sed -i -E 's/^(\t\t_name:)[[:space:]]+"\\\(#context\.#moduleInstanceMetadata\.name\)-\\\(#context\.#componentMetadata\.name\)"$/\1 #component.#names.resourceName/' k8s/transformers/*_transformer.cue
```
Expect exactly 25 hunks. Closedness, defaults, required fields: unchanged.

**D-B. `object`'s prefix reads `#names.resourceName`.** `<instance>-<component>-<user>` is a secondary name with the primary name as prefix (D15's second carve-out class), so the prefix follows the override while the user segment stays verbatim; `_instName` and `_compName` (`object_transformer.cue:40-41`) become dead and are removed (the namespace read at line 56 stays on `#context`). The passthrough body's own `metadata.name` is still ignored by every raw kind; the override path is `component.metadata.resourceName`.

**D-C. Carve-outs for this catalog: `apiservice`, `object` (user segment), `csidriver` (when added).** `StorageClass` stays in the sweep: an external contract via `storageClassName`, but label-shaped, so it wants the override honoured (D19).

**D-D. Fixtures, first ones in `k8s/`.** Modelled on `opm/transformers/service_transformer.cue` and the Fixtures section of `docs/name-constraints.md`: a hidden `_test*Context` stub, a component stub with `#instance: {name, namespace, uuid}` (on the component, since `#names.resourceName` derives from `metadata.resourceName` from `#instance.name`), names pinned by interpolation and checked with `cue eval -c` (plain `cue vet` passes an incomplete guard vacuously). Scope: deployment default-named; storageclass default and override (`metadata: resourceName: "custom"` pinned to `"custom"`); apiservice with an override set, pinned to the authored name; object default. Fixtures for the other 22 kinds are not added here: the edit is identical and the four cover every distinct code path.

**D-E. Doc comments.** The 24 "(name prefix, ...)" transformer doc comments become "(name from the component's `#names`, ...)"; `task generate:index` follows.

## Research & Decisions

### Uniformity of the k8s transformers
**Context**: whether 25 files is one change or several.
**Explored**: `grep -L` for the formula across `k8s/transformers/` (2026-08-27): only `apiservice` and `object` differ; all others share the identical `_name` line.
**Decision**: one change, one commit, grouped as a single coherent group per Principle VI.
**Rationale**: the edit is byte-identical in every file; splitting would create 25 identical PRs.

### Exact-name membership
**Context**: D19 says the class transfers, the membership does not.
**Explored**: D19 text and `experiments/09-name-constraint-propagation/` in `enhancements/0019`; `k8s/transformers/apiservice_transformer.cue:47` (`_as.metadata.name`), `object_transformer.cue:54`.
**Decision**: apiservice, object (user segment), csidriver.
**Rationale**: as decided in D19 (user decision 2026-08-24).

## Risks / Trade-offs

- Override now honoured where it was ignored -> intended, documented in the release note; no consumer affected today.
- 25 files in one commit obscures a typo -> the identical-line edit is done with the D-A regex, `cue fmt`, and reviewed as a diff of 25 identical hunks; `grep -c '#moduleInstanceMetadata.name)-' k8s/transformers/*` must return 0 outside `apiservice`/`object`.

## Durable decisions

- "`catalogs/k8s` exact-name kinds: APIService, `object`'s user segment, CSIDriver; everything else, Namespace included, honours `metadata.resourceName`" -> `docs/name-constraints.md`, a `k8s/` subsection under "Transformers read names, never derive them" (section created by the `opm/` workloads slice; create it if this lands first).
