# Design: transformer-registration-contract

## Context

See `proposal.md` § Why. The decision is `enhancements/0015` D9, with D11's stamping and D12's naming as properties of the rendered object; the pre-drafted shapes are that entry's `contracts/contracts.cue` (`#TransformerRegistrationContract`, `#RenderedRegistration`).

Current state, measured 2026-09-14 against core `v2.0.0-alpha.9` and this catalog at `4.2.0`:

- `opm/resources/v1alpha1/` holds three members (`admission_policy`, `namespace`, `webhook`); `opm/transformers/` is flat, 23 transformer files, each carrying its golden fixture in the same file.
- `#Resource.spec` is `spec!: (strings.ToCamel(metadata.#definitionName)): _`, so a member named `transformer-registration` owns `spec.transformerRegistration` and MAY declare required fields inside it.
- Core's `#TransformerContext.#moduleInstanceMetadata` is a **projection** computed at the `#transform` site from `#moduleInstance` (0019 D12, core alpha.7). A fixture can no longer fill it directly; it supplies `#moduleInstance` and `#context.#runtimeName`.
- `task vet:listing` requires every member filed under a kind directory to be a key of the matching `catalog.cue` map.

## Goals / Non-Goals

**Goals**

- One contract a provider module attaches, and one transformer that renders the cluster-scoped CR the operator will accept.
- The rendered object's identity comes from the rendering instance alone: a module MUST NOT be able to claim to be another provider.
- A golden fixture that actually evaluates, so the emitted shape is checked rather than assumed.

**Non-Goals**

- D11's `#PreBoundRegistration` derivation fold (a provider catalog's export). It needs a provider catalog to live in; authored `provides` is the interim.
- The acceptance side (D8, D10, D11 verification) and the CRD itself: opm-operator's slice.
- Any `#Module` change, including the derived `#provides` fold D9 defers until a consumer exists.
- Repairing the 21 pre-existing broken fixtures (see Risks).

## Decisions

### The contract

`opm/resources/v1alpha1/transformer_registration.cue`, package `v1alpha1`:

```cue
#TransformerRegistrationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1alpha1"
		name:           "transformer-registration"
		apiVersion:     "v1alpha1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/transformer-registration@v1alpha1"
		description:    "A provider module's claim that its catalog implements platform contracts"
		labels: "resource.opmodel.dev/category": "cluster"
	}

	fulfilment: "catalog"

	spec: transformerRegistration: {
		catalog!:  c.#ModulePathType
		version!:  c.#VersionType
		provides!: [...c.#ContractFQNType]
	}
}
```

All three spec fields MUST be required. A claim with no `catalog` is not a partial claim, it is nothing, and D28's posture (an unsupplied demand fails the render) is the one that suits a provider module: failing loudly beats registering an empty `provides`. The definition adds no `matchLabels`, so the contract introduces no matching vocabulary and D5's guard is untouched; the renderer selects on the FQN alone.

`#nameConstraint` stays top (unset): the CR's name is derived from the instance, never from the owning component's `resourceName`, so this member constrains nothing.

### The transformer

`opm/transformers/transformer_registration_transformer.cue`, package `transformers`:

```cue
#TransformerRegistrationTransformer: c.#ComponentTransformer & {
	requiredResources: (res.#TransformerRegistrationResource.metadata.fqn): res.#TransformerRegistrationResource
	producesKinds: ["TransformerRegistration"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext
		_i: #context.#moduleInstanceMetadata
		_r: #component.spec.transformerRegistration
		output: {
			apiVersion: "opm.opmodel.dev/v1alpha1"
			kind:       "TransformerRegistration"
			metadata: {
				name:   "\(_i.namespace).\(_i.name)" // D12
				labels: #context.labels
			}
			spec: {
				catalog:  _r.catalog
				version:  _r.version
				provides: _r.provides
				providerRef: {name: _i.name, namespace: _i.namespace} // D11
			}
		}
	}
}
```

`output` is a struct, not a list: one claim per component carrying the contract, which is the `StructKind` arm of core's dispatch. `providerRef` and `metadata.name` read the projected instance metadata and nothing else, so a module cannot author either; this is what makes D11's "every field derived or stamped" structural rather than a rule.

The group, version and kind are **literals**. They name an opm-operator CRD, so nothing in this catalog can derive them, and the operator slice must match these three strings exactly.

### `metadata.labels` is `#context.labels`

The pre-draft emits no labels. Every other transformer here stamps `#context.labels`, and the fold gives the object `managed-by`, `app.kubernetes.io/name`, `app.kubernetes.io/instance` and `module-instance.opmodel.dev/name`. A cluster-scoped object that no label identifies is hard to attribute when an admin lists claims, and the operator keys on `spec.providerRef`, not on labels, so adding them changes no behavior. Verified in the spike below.

## Research & Decisions

### The rendered shape, measured end to end

**Context**: The proposal's After block is a claim until something evaluates it, and the fixture convention in this repo is a golden literal in the member's own file.
**Explored**: A throwaway CUE module pinning core `v2.0.0-alpha.9` and this catalog at `4.2.0`, holding the contract, the transformer, a component attaching the contract, and a rendered fixture (scratchpad, 2026-09-14, cue v0.17.1).
**Decision**: The shapes above ship as written.
**Rationale**: `cue vet` passes and `cue export` of the rendered output yields exactly D12's name and D11's stamp:

```json
{
  "apiVersion": "opm.opmodel.dev/v1alpha1",
  "kind": "TransformerRegistration",
  "metadata": {
    "name": "backup-system.k8up",
    "labels": {"app.kubernetes.io/name": "k8up", "app.kubernetes.io/instance": "k8up",
               "app.kubernetes.io/managed-by": "opm-test",
               "module-instance.opmodel.dev/name": "k8up"}
  },
  "spec": {
    "catalog": "opmodel.dev/catalogs/k8up@v1", "version": "1.0.0",
    "provides": ["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"],
    "providerRef": {"name": "k8up", "namespace": "backup-system"}
  }
}
```

### The fixture must supply `#moduleInstance`, not `#moduleInstanceMetadata`

**Context**: The first spike copied the fixture idiom from `namespace_transformer.cue`, filling `#context: #moduleInstanceMetadata: {...}` directly.
**Explored**: That form under `cue export`; then the form the library's own pins use (supply `#moduleInstance`, leave the projection to compute).
**Decision**: New fixtures MUST supply `#transform.#moduleInstance` (an instance-shaped value with `metadata.{name,namespace,fqn,uuid}` and `#moduleMetadata.version`) plus `#context: #runtimeName`, and MUST NOT write `#moduleInstanceMetadata`.
**Rationale**: since 0019 D12 that field is a projection of `#moduleInstance`, which the old form leaves as `_`. Measured: the old form fails `cue export` with `#moduleInstance.metadata undefined as #moduleInstance is incomplete (type _)`, while `cue vet` exits 0 because the failure is incomplete-class, not an error. The new form exports concretely.

### `provides` is authored here, derived later

**Context**: D11 says the only authored fact in the whole flow is the module's catalog dependency version, with `provides` folded from the provider catalog's own transformer map.
**Explored**: Shipping `#PreBoundRegistration` in this change; shipping the contract alone.
**Decision**: The contract alone. `provides!` is a typed list a provider authors for now.
**Rationale**: The fold reads a *provider catalog's* `#transformers` and belongs in that catalog beside its identity package, not in `catalog_opm`. No provider catalog exists yet (`catalog_k8up` is 0015's last landing), so shipping the fold here would put it where nothing can call it, against Principle V. The acceptance-side re-derivation (D11) refuses drift, so an authored list that disagrees is caught at the operator, not silently honoured.

## Risks / Trade-offs

- [The literals `opm.opmodel.dev/v1alpha1` and `TransformerRegistration` must match a CRD that does not exist yet] -> D3 fixes the group and kind, the operator slice builds against this change, and both are `v1alpha1`, which promises nothing (0010 D34) while the two sides converge.
- [A module attaching the contract on a cluster with no CRD fails at apply] -> the correct loud failure (0010 D28); no module attaches it today, and the provider module lands with the operator slice.
- [`provides` can disagree with the named catalog] -> D11's acceptance re-derives and refuses drift naming both lists. Not detectable in this catalog, which never sees the provider's transformer map.
- [**Pre-existing, out of scope**: 21 of 23 transformer fixtures no longer evaluate] -> they fill `#context.#moduleInstanceMetadata`, retired as an input by 0019 D12, and `cue vet` stays green because the failure is incomplete-class. Every golden output in this catalog has been unchecked since core alpha.7. This change does not repair them; it must not copy the pattern, and the finding needs its own change.

## Durable decisions

- **A transformer fixture supplies `#moduleInstance`, never `#moduleInstanceMetadata`** — with the measured reason (the projection, and `cue vet` not reporting the failure). Lands as a `CLAUDE.md` rule under Working Style, beside the guard-hoisting pitfall, since it binds every future transformer author.
- **The registration CR's group, version and kind are literals shared with opm-operator** — where a future author must look before changing them. Lands in the transformer file's doc comment; the cross-repo half belongs to the operator's own change.
- The rest stays with the change.

## Open Questions

None.
