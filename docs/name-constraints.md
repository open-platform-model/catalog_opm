# Name constraints: where they go and how they behave

Core (`opmodel.dev/core@v2`, from `v2.0.0-alpha.6`) gives every `#Resource`, `#Trait` and `#Blueprint` a hidden slot `#nameConstraint: _`, and `#Component` asserts the resolved `metadata.resourceName` against the conjunction of every attached primitive's slot (enhancement 0019 D21). This note is the catalog side of that contract: what a catalog author declares, where, and two evaluator behaviours that are invisible in review.

## The rule: the primitive that owns the reason declares the constraint

A name is dot-restricted iff it becomes a DNS label somewhere. The primitive whose rendered object puts the name in that position is the one that declares the slot; `#Component` and the transformers never carry per-kind knowledge.

| Primitive | Slot | Why |
| --- | --- | --- |
| `#ExposeTrait` | `c.#ServiceNameType` | the Service name is the first FQDN label, and the API server validates it as DNS-1035 (alphabetic first rune) |
| `#StatefulWorkloadBlueprint` | `c.#NameType` | pod DNS `<sts>-<n>.<svc>...` puts the StatefulSet name in a label position; the server enforces dots and the 63-rune cap there |
| the `#Container` wrapper, on its container entry | computed: `c.#NameType` when the component's derived `matchLabels` `workload-type` reads `stateful`, top otherwise (0019 D23) | the StatefulSet transformer keys on the label, not on the blueprint, so a raw container component must be covered too |
| `#NamespacesResource` | `c.#NameType`; the rendered names are asserted on the `#Namespaces` wrapper (`"\(ns.name)" & c.#NameType`) | a Namespace name is the second label of every FQDN; this resource renders exact names from its map, so the wrapper assertion is what protects the object. The schema field stays `string`: a type there unifies into the `*KeyName` default and silently drops it (measured) |

A primitive that does not care leaves the slot alone: top is the identity under unification and costs nothing. Never guard on the slot's presence (`x.#nameConstraint != _|_` is false for a non-concrete value on cue v0.17.1 and silently never propagates); core collects unconditionally.

## A computed constraint must resolve on every attachment path

```cue
#Container: c.#Component & {
	matchLabels: _
	#resources: (#ContainerResource.metadata.fqn): #ContainerResource & {
		#nameConstraint: [
			if matchLabels["core.opmodel.dev/workload-type"] == "stateful" {c.#NameType},
			_,
		][0]
	}
}
```

- The list index is load-bearing. `c.#NameType | *_` reads as "the type, defaulting to top" and means the opposite: a default arm wins over the concrete one.
- **The hazard (measured, cue v0.17.1, change `catalog-name-constraints`, 2026-08-26):** an unresolved `#nameConstraint` anywhere in a component's attachments defers every `strings.MaxRunes` / `MinRunes` validator in the whole conjunction while the regex bounds still fire. The natural D23 spelling, the same conditional on `#ContainerResource` reading the entry's own key, stays unresolved whenever a workload blueprint answers the key instead of the entry, and then a 64-rune override on the StatefulSet and on the Expose Service beside it vetted clean while a dotted one was refused. A `!= _|_ &&` guard does not rescue it: the presence test is `false`, but `false && <unresolved>` does not short-circuit. Reading the component's derived `matchLabels` from the wrapper resolves on every path where a key is answered, and where nothing answers the component already fails its required key.
- Rule: a computed slot is read from a value that is concrete on every path the primitive can be attached through. Test the length bound, not only the dot, when measuring: the dot refusal lies.

## Lexical scope: re-declare what you reference

A struct literal unified with a definition does not see that definition's fields by name. Two sites bite:

- The `#Expose` component wrapper references `#names` to default the Service name (`spec: expose: name: *#names.dns.short | c.#ServiceNameType`). It must declare `#names: _` first, or vet fails with `reference "#names" not found`. Unification with `#Component`'s own slot makes it the same value.
- The `#Container` wrapper references `matchLabels` for the computed constraint and declares `matchLabels: _` first; the `#Namespaces` wrapper references `spec` for its name assertion and declares `spec: _`.

This is the same rule the catalog's `#transform` slots already follow.

## Fixtures that exercise a wrapper default

Transformer test data never passes through `#Module`, so core never injects `#instance`. A fixture that relies on the `#Expose` default must set `#instance: {name, namespace, uuid}` by hand and pin the result with a resolution guard, `"\(x.metadata.name)" & "expected"`: the interpolation collapses the default to a string, so a wrong default fails loudly, where a plain golden would unify vacuously against the type arm. A *missing* `#instance` is not caught by `cue vet` (measured 2026-08-27, core alpha.6): the guard is merely incomplete, `cue vet ./...` (what `task vet` runs, no `-c`) exits 0, and the guard passes vacuously. `cue eval -c ./transformers -e <guard>` is the concreteness gate; a guard it reports incomplete is a fixture missing `#instance`. See `opm/transformers/service_transformer.cue`.

## Reading fields across builds

A transformer that reads a field whose posture changed within an `apiVersion` (optional → required, or a default moved from the schema to a wrapper) MUST keep a fallback for components compiled against earlier builds of that `apiVersion`, and MUST pin it with a `_test*Legacy*` fixture carrying the earlier shape (0010 D27: a supplier at or above the build a module compiled against is unconditionally safe). The kernel hands `#transform` the module's own evaluated value, so a module pinned to an older build presents the older shape to the newest transformer; the schema's `!` protects new builds at vet time and nothing else.

- **Measured (2026-08-28, `opm-v2.0.0-alpha.6`/`alpha.7`):** `#ExposeSchema.name` went `name?: string` → `name!: c.#ServiceNameType` with the default moved to the `#Expose` wrapper, and the Service transformer's read became bare `_expose.name`. Every module pinned to `alpha.2 … alpha.5` then lost its Services on an alpha.6+ platform: `output.metadata.name: cannot reference optional field: name`. The same bare read sat in the StatefulSet `serviceName` (alpha.5 had an inner guard; alpha.6 removed it) and the four route transformers' `backendRefs` (a read alpha.6 introduced). The fix is one list-index fallback in `#ServiceName` (`opm/transformers/name_helpers.cue`: `expose.name` when set or defaulted, else `#names.dns.short`, the wrapper's own default) that all six readers go through; new-build components render byte-identically.
- **Legacy-shape fixtures are hand-built structs handed to `#transform` directly; they never embed the current trait.** Embedding `tr.#Expose` gives `name!` and cannot express "optional and unset". Write the field as the older build published it (`name?: string`, nothing set), set `#names` as core would derive it, and carry every default the older schema supplied (`protocol: "TCP"`), so the transformer sees exactly what the kernel would hand it. Pin the result with a resolution guard.
- **`cue vet` does not catch the regression.** A reference to an unset optional field is *incomplete*, not an error, under plain `cue vet ./...` (what `task vet` runs): the legacy guard exits 0 vacuously on the broken transformer. `cue eval -c ./transformers -e _testServiceLegacyExposeResolves` is the gate that refuses it; run it when touching a transformer's name read.

## Transformers read names, never derive them

A transformer reads the primary object's name from `#component.#names.resourceName` (enhancement 0019 D15). It never re-interpolates `<instance>-<component>` from `#context`: that formula is a second authority for the same string, and it silently ignores `metadata.resourceName`. Core computes `resourceName` once (the default is that formula, so default-named output is byte-identical) and the transformer renders what it is given. The seven workload transformers (deployment, statefulset, daemonset, job, cronjob, hpa, pdb) read through one seam, `#WorkloadName` (`opm/transformers/name_helpers.cue`), for the `#ResourceNameTrait` deprecation window: the trait's exact name when set, else `#names.resourceName`. The seam exists so HPA and PDB target the workload by a byte-identical name; it collapses to a direct read when the trait is deleted. Three carve-out classes are exempt, and each site carries an inline `// exact — <contract>` comment naming what it honours:

1. **Exact-name kinds**: the name is a contract with something outside the module and renders verbatim from the authored spec. In `opm/`: `namespaces` (externally referenced), `crd` (`<plural>.<group>`), the validating and mutating webhook configurations (patched by name at runtime), `admission_policy` (policy and binding), `role` (every RBAC object, `_role.name`) and the ServiceAccount (`#ToK8sServiceAccount`, referenced by workloads and RoleBindings). The `k8s/` list is in the section below.
2. **Secondary and multi-object names**: `configmap` and `secret` emit content-hashed per-item names through the one helper, `#ImmutableName` (`opm/resources/v1beta1/configmap.cue`), which names ConfigMap and hand-authored Secret objects alike; `pvc` emits one prefixed name per persistent volume. These are derived because each renders several objects from one component, and stay derived.
3. **Cross-object references** follow the referenced object's naming rule, never the referencing transformer's own name: the route transformers' `backendRefs[].name` and the StatefulSet `serviceName` name the Service, whose one authoritative name field is `expose.name` (D22). They read it through `#ServiceName` (`opm/transformers/name_helpers.cue`), the same seam the Service transformer renders through, never through their own `expose.name` read: one seam is what keeps the reference byte-identical to the rendered Service, including the fallback for a component compiled against a build whose `expose.name` was optional (see "Reading fields across builds"). The four route transformers therefore require `#ExposeTrait`: a route without a Service has nothing to reference and is refused at match time rather than rendered with a dangling backendRef.

**No transformer copies `resourceName` into a label value** (0019 D19). `app.kubernetes.io/name` and the selector labels carry the component name (`#NameType`, at most 63 runes); `resourceName` may be up to 253 runes and would be refused by the API server as a label value. Both rules are enforced in review, not by the evaluator: CUE cannot forbid a string interpolation.

Fixtures for a transformer in the sweep set `#instance` on the component stub and pin the rendered name by interpolation (`"\(x.metadata.name)" & "expected"`, checked with `cue eval -c`); a cross-reference guard pins the referencing field against the referenced transformer's output for the same stub (see `opm/transformers/http_route_transformer.cue`).

## `k8s/`: exact-name kinds and the override

The raw catalog reads `#component.#names.resourceName` for every kind whose name is a free choice (instance-prefixed by default, `metadata.resourceName` overrides it, `#ObjectNameType` the ceiling; 0019 D20). No `k8s/` resource declares a `#nameConstraint`: none of their names lands in a DNS label position. Every other transformer's `_name` line is `#component.#names.resourceName` (0019 D15/D19: read, never derived). A few kinds are contracts with something outside the module and render the authored name verbatim:

| Kind | Name | Why |
| --- | --- | --- |
| `apiservice` | exact | `<version>.<group>` is the aggregation contract |
| `objects` | exact user segment, prefixed | the author's key is the object identity; only the prefix is instance-scoped |
| `csidriver` | exact | kubelet registers the driver under this name in `CSINodeInfo`, and every `StorageClass.provisioner` references it; a prefixed or overridden name breaks provisioning silently |
| `namespace` | `#names.resourceName` | unlike `opm/`'s `namespaces` resource (exact names from its map), the raw kind renders the prefixed name and stays in the sweep: it is not an exact kind in this catalog |
| `storageclass` | `#names.resourceName` | referenced only by `storageClassName`, label-shaped; the override is the contract |
| `volumesnapshotclass` | `#names.resourceName` | identical position to `storageClassName` (`VolumeSnapshot.spec.volumeSnapshotClassName`); follows StorageClass |

A fixture for an exact-name kind sets `metadata.resourceName` on the component stub and pins the authored name, proving the override is ignored; `#instance` is not needed because nothing reads `#names`. A fixture for an override-honouring kind sets `#instance` and pins both the default (`<instance>-<component>`) and the override. See `k8s/transformers/csidriver_transformer.cue` and `volumesnapshotclass_transformer.cue`.
