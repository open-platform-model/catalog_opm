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

Transformer test data never passes through `#Module`, so core never injects `#instance`. A fixture that relies on the `#Expose` default must set `#instance: {name, namespace, uuid}` by hand and pin the result with a resolution guard, `"\(x.metadata.name)" & "expected"`: the interpolation collapses the default to a string, so a missing or wrong default fails loudly, where a plain golden would unify vacuously against the type arm. See `opm/transformers/service_transformer.cue`.
