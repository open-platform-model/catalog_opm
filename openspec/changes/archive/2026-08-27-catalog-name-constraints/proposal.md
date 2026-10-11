## Why

Core `v2.0.0-alpha.6` shipped the naming contract of enhancement 0019 ("Three name types, the label stays the safety floor, the subdomain becomes the override ceiling, DNS-1035 closes the Service gap", "Dot-hostile primitives declare a `#nameConstraint`; the component asserts the resolved name against their conjunction, the matchLabels pattern applied to naming" and "A primitive computes its `#nameConstraint` from its own state; the stateful constraint lives on the container resource"): the `#ObjectNameType` and `#ServiceNameType` types, a hidden `#nameConstraint` slot on every primitive, and a `#Component` assertion of the resolved `metadata.resourceName` against the conjunction of the attached slots. Every slot in this catalog is still top, so a dotted or leading-digit `resourceName` override on a component that renders a Service, a StatefulSet or a Namespace is accepted at vet and refused by the API server at apply. The Service name is also still a render-time formula inside the Service transformer, which `#names.dns.*` cannot see, so the projection and the rendered Service agree only by coincidence. This change is the first of three catalog slices for 0019 Phase A: the constraint declarations and the Expose default, before the transformer read sweeps.

## What Changes

- `#ExposeTrait` declares `#nameConstraint: c.#ServiceNameType` (D21).
- **BREAKING** `#ExposeSchema.name` moves from `name?: string` to a required, DNS-1035-typed `name: c.#ServiceNameType`; the `#Expose` component wrapper defaults it to `#names.dns.short` (D22). A module that attaches `#ExposeTrait` without the wrapper now refuses at vet with `field is required but not present`; every known consumer attaches through the wrapper.
- The Service transformer reads `spec.expose.name` and nothing else; the list-index fallback is deleted (D22). Default output is byte-identical: `<instance>-<component>`.
- The `#Container` component wrapper computes the container entry's `#nameConstraint` from the component's derived `matchLabels`: `c.#NameType` when `workload-type` reads `stateful`, top otherwise (D23, landed on the wrapper rather than on the resource definition; see design.md for the measured reason).
- `#StatefulWorkloadBlueprint` declares `#nameConstraint: c.#NameType` (D21).
- **BREAKING** The `#Namespaces` wrapper asserts every rendered namespace name against `c.#NameType` (a dotted map key or explicit name now refuses at vet; the schema field itself stays `string`, because a type there silently kills the key default, measured), and `#NamespacesResource` declares `#nameConstraint: c.#NameType` (D21, both landed per the 2026-08-26 decision).
- No member moves to a new `apiVersion` segment: the slot is additive on every primitive, and the two tightened fields stay in `v1beta1` / `v1alpha1` under the `feat!:` convention (Principle I).

## Before / After

**Before**

```cue
// opm/traits/v1beta1/expose.cue
#ExposeTrait: c.#Trait & {
	appliesTo: [res.#ContainerResource]
	spec: expose: #ExposeSchema
}
#Expose: c.#Component & {
	#traits: (#ExposeTrait.metadata.fqn): #ExposeTrait
}
#ExposeSchema: {
	name?: string
}

// opm/transformers/service_transformer.cue
output: metadata: name: [
	if _expose.name != _|_ {_expose.name},
	"\(#context.#moduleInstanceMetadata.name)-\(#component.metadata.name)",
][0]

// opm/resources/v1beta1/container.cue
#Container: c.#Component & {
	#resources: (#ContainerResource.metadata.fqn): #ContainerResource
}

// opm/blueprints/v1beta1/stateful_workload.cue
#StatefulWorkloadBlueprint: c.#Blueprint & {
	matchLabels: "core.opmodel.dev/workload-type": "stateful"
}

// opm/resources/v1alpha1/namespace.cue
#NamespacesResource: c.#Resource & {
	spec: namespaces: [KeyName=string]: #NamespaceSchema & {name: string | *KeyName}
}
#NamespaceSchema: name: string
```

**After**

```cue
// opm/traits/v1beta1/expose.cue
#ExposeTrait: c.#Trait & {
	appliesTo: [res.#ContainerResource]
	#nameConstraint: c.#ServiceNameType
	spec: expose: #ExposeSchema
}
#Expose: c.#Component & {
	#names: _ // re-declared: not in lexical scope from the embedded #Component
	#traits: (#ExposeTrait.metadata.fqn): #ExposeTrait
	spec: expose: name: *#names.dns.short | c.#ServiceNameType
}
#ExposeSchema: {
	name!: c.#ServiceNameType
}

// opm/transformers/service_transformer.cue
output: metadata: name: _expose.name

// opm/resources/v1beta1/container.cue
#Container: c.#Component & {
	matchLabels: _ // re-declared: lexical scope
	#resources: (#ContainerResource.metadata.fqn): #ContainerResource & {
		#nameConstraint: [
			if matchLabels["core.opmodel.dev/workload-type"] == "stateful" {c.#NameType},
			_,
		][0]
	}
}

// opm/blueprints/v1beta1/stateful_workload.cue
#StatefulWorkloadBlueprint: c.#Blueprint & {
	matchLabels: "core.opmodel.dev/workload-type": "stateful"
	#nameConstraint: c.#NameType
}

// opm/resources/v1alpha1/namespace.cue
#NamespacesResource: c.#Resource & {
	#nameConstraint: c.#NameType
	spec: namespaces: [KeyName=string]: #NamespaceSchema & {name: string | *KeyName}
}
#Namespaces: c.#Component & {
	spec: _
	_namespaceNamesFit: [for _, ns in spec.namespaces {"\(ns.name)" & c.#NameType}]
}
#NamespaceSchema: name: string // unchanged; asserted by the wrapper
```

## Impact

- **Release class:** `feat!(opm):` on the `opm` module only; `k8s/` is untouched. Advances the v2 alpha counter (this relies on the module still shipping the v2 alpha line) and is the first `opm` release built on core `v2.0.0-alpha.6`.
- **`modules` fleet (v2 staging on `main`):** 17 modules attach Expose, all through `tr.#Expose` (verified 2026-08-26), so the default name resolves for every one of them. Two set `expose.name` explicitly: `istio_ambient` (`"istiod"`) and `jellystat` (`#config.database.bundled.serviceName`, default `"jellystat-db"`), both DNS-1035. Existing `resourceName` values (`istiod`, `istio-cni-node`, `ztunnel`) are labels. The fleet re-pins to the released catalog in its own PR; no source edit is expected.
- **Subscribing platforms:** the `library` parity harness pins the catalog build in three places and re-pins after the release in its own PR; rendered output for default-named Services is unchanged.
- **`cli` fixtures and templates:** `tests/fixtures/modules/podinfo`, `tests/integration/module-apply/testdata`, `templates/standard`, `templates/advanced` all attach via `tr.#Expose`; nothing to re-publish for this slice.
- **Migration cost of the breaking pieces:** a module attaching `#ExposeTrait` raw must switch to the wrapper or set `spec.expose.name`; a namespace map key or explicit name with a dot must become a valid label. No known consumer does either.

## Enhancement

Implements enhancement 0019 (the name constraint slots, the Service name field and the stateful container constraint; the types it states are consumed, not implemented here). The change declared it in an `enhancement.yaml` file, since retired. The read sweep of the `opm` transformers and the `k8s` sweep of the same enhancement are the two following slices.
