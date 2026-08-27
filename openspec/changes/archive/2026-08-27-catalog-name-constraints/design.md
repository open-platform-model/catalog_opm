## Context

See proposal.md for motivation. Core `v2.0.0-alpha.6` (the pinned dependency of both modules) provides `#ServiceNameType`, `#ObjectNameType`, the hidden non-optional `#nameConstraint: _` slot on `#Resource`/`#Trait`/`#Blueprint`, and `#Component._nameFits: "\(metadata.resourceName)" & _nameConstraints`, collected unconditionally over the three attachment maps. Nothing in this catalog uses any of it yet.

Member files touched, all in `opm/` (`opmodel.dev/catalogs/opm@v2`):

- `opm/traits/v1beta1/expose.cue` (`v1beta1`): `#ExposeTrait`, `#Expose`, `#ExposeSchema`
- `opm/transformers/service_transformer.cue`: `#ServiceTransformer` and its in-file test data
- `opm/resources/v1beta1/container.cue` (`v1beta1`): `#ContainerResource`
- `opm/blueprints/v1beta1/stateful_workload.cue` (`v1beta1`): `#StatefulWorkloadBlueprint`
- `opm/resources/v1alpha1/namespace.cue` (`v1alpha1`): `#NamespacesResource`, `#NamespaceSchema`
- `opm/traits/v1beta1/resource_name.cue`: doc comment only (the trait is deleted in the next slice)

`k8s/` is not touched.

## Goals / Non-Goals

**Goals:**

- Every dot-hostile primitive in this catalog declares its constraint on itself, so a bad `resourceName` override refuses at `cue vet`.
- The Service name has exactly one source, the Expose trait's `name`, defaulted from the component's own projection.
- Default-named rendered output is byte-identical before and after.

**Non-Goals:**

- Making any other transformer read `#component.#names` (D15, next slice).
- Deleting `#ResourceNameTrait` / `#WorkloadName` (next slice).
- Anything in `k8s/` (D19, third slice).

## Decisions

### The Expose default lives on the component wrapper, with `#names` re-declared

```cue
#Expose: c.#Component & {
	#names: _
	#traits: (#ExposeTrait.metadata.fqn): #ExposeTrait
	spec: expose: name: *#names.dns.short | c.#ServiceNameType
}
```

The trait's spec schema has no lexical path to the owning component, and a field referenced from inside a struct literal that unifies with `#Component` is not in scope unless the literal declares it (the same rule the catalog's `#transform` slots follow). Re-declaring `#names: _` makes the reference resolve; unification makes it the same value as core's slot. Alternative rejected: keeping the default in the transformer, which leaves the name a render-time fact the projection cannot see (0019 D22).

**Required-field-set change:** `#ExposeSchema.name` becomes required. That is what makes a raw `#ExposeTrait` attachment refuse instead of rendering an unnamed Service. **Default change:** none for wrapper users; the wrapper's default reproduces the transformer's old formula exactly.

### The container constraint is computed on the `#Container` wrapper from the derived `matchLabels`

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

D23 places the conditional on the container resource, keyed off the entry's own key. That spelling was measured and rejected here (Research & Decisions below): on the blueprint path the entry's key is never answered, the conditional stays unresolved, and an unresolved slot defers every validator in the component's conjunction. The wrapper is the catalog's own component-level surface (the same site the Expose default lives on), and the component's derived `matchLabels` is concrete on every path where a key is answered, so the conditional always resolves. The slot still lands on the container entry, so core's collection reads it exactly as D23 intends; only the input moved. `#ContainerResource` itself keeps top. A default arm (`c.#NameType | *_`) would win over the concrete one; the list index picks the first present element. The key stays `core.opmodel.dev/workload-type`.

Consequence for D23's letter: a module attaching `#ContainerResource` raw, without `#Container`, gets no stateful constraint from the container. The fleet and the cli fixtures attach through wrappers everywhere; the deviation is reported to 0019 for a D23 amendment.

### The blueprint keeps its own constraint

`#StatefulWorkloadBlueprint: #nameConstraint: c.#NameType` stays as D21 prescribes. With the wrapper spelling above it is genuinely redundant on the `#StatefulWorkload` path (both resolve to `#NameType`), and the only source for a component that attaches the blueprint without the `#Container` wrapper.

### Namespace names are asserted on the `#Namespaces` wrapper, and the schema field stays `string`

Typing `#NamespaceSchema.name: c.#NameType` was measured and reverted: the type unifies into the map default `string | *KeyName`, a dotted key's default arm drops out, the field is left a bare non-concrete `#NameType`, and neither `cue vet` nor an interpolated assertion downstream sees a string to refuse (the failure mode 0019 experiment 11 recorded for `resourceName`). So the schema keeps `name: string`, and the wrapper re-declares `spec` and asserts `_namespaceNamesFit: [for _, ns in spec.namespaces {"\(ns.name)" & c.#NameType}]`; the interpolation forces the default to a string, so a dotted key (`"a.b": {}`) and an explicit dotted name (`foo: name: "x.y"`) both refuse naming the string and the label regex, while `"cert-manager": {}` and `foo: name: "bar"` render `cert-manager` and `bar`.

### Namespace lands on both the emitted name and the resource slot

`#NamespacesResource` emits a map of exact names, not the component's `resourceName`, so the string that reaches the API server is `#NamespaceSchema.name`; typing it `c.#NameType` is what protects the rendered object. The resource additionally declares `#nameConstraint: c.#NameType` as D21 prescribes (user decision 2026-08-26: both).

### The transformer reads the field and nothing else

`metadata: name: _expose.name`. The list-index fallback goes; there is no path on which the field is unset, because the schema requires it.

## Research & Decisions

### An unresolved `#nameConstraint` defers every validator in the component

**Context**: D23 spells the container conditional on the resource definition, reading the entry's own `workload-type` key. For a blueprint-attached component that key is answered by the blueprint's `matchLabels` and never on the container entry, so the entry holds the unanswered required disjunction.

**Explored**: cue v0.17.1, scratch files in `opm/` against core `v2.0.0-alpha.6`. Matrix: `#StatefulWorkload` with a 64-rune override, a dotted override, a 63-rune override and a default; raw `#Container` stateful with 64 runes and with a dot; raw stateless with a dot; `#StatelessWorkload` with a dot; Expose on a stateful blueprint with 64 runes; Expose with a leading-digit `resourceName`. Three spellings of the container conditional: plain compare on the entry (D23 as written), `!= _|_ &&` guarded on the entry, and the plain compare on the `#Container` wrapper reading the component's derived `matchLabels`.

**Decision**: The wrapper spelling.

**Rationale**: With either entry-level spelling, the blueprint path admitted the 64-rune override on the StatefulSet AND on the Expose Service beside it, while the dotted override was refused. The entry's slot evaluates to `_ & _ & [if ... {c.#NameType}, _][0]`, unresolved; core's `_nameConstraints` becomes `_ & b.#nameConstraint & r.#nameConstraint` with that term inside, and against a concrete string the regex bounds fire but the `strings.MaxRunes` validators do not. Replicating the collection in-package confirmed it: over `#blueprints` alone the 64-rune string is refused (`does not satisfy strings.MaxRunes(63)`); adding the `#resources` walk admits it. The guard does not help: `matchLabels[key] != _|_` evaluates to `false` on the unanswered key, but `false && (v == "stateful")` with an unresolved right operand does not short-circuit and the comprehension stays unresolved. The wrapper spelling resolves on every path (blueprint stateful slot evaluates to `#NameType`, stateless to `_`): all seven refusals fire (each naming the string and the violated bound) and all admits hold (63 runes, `prod-cache`, `web.internal` on both stateless paths, `istiod`, `prod-web` with `prod-web.media.svc.cluster.local`). Lexical rule: a literal referencing `matchLabels` must declare `matchLabels: _`.

### `cue vet` does not refuse an unset typed field on a hidden fixture

**Context**: The first cut typed `#ExposeSchema.name: c.#ServiceNameType` without the required marker; a raw `#ExposeTrait` attachment vetted clean.

**Explored**: Same scratch matrix.

**Decision**: `name!: c.#ServiceNameType`.

**Rationale**: A plain typed field is merely non-concrete, which `cue vet` admits without `-c`; the `!` marker is what D22's "refuses at vet" needs. The wrapper's `spec: expose: name: *#names.dns.short | c.#ServiceNameType` satisfies the marker.

### Transformer fixtures never pass through `#Module`

**Context**: The in-file Service test data builds components by embedding wrappers and never injects `#instance`, so the wrapper default is incomplete there and a unification golden would silently accept `"shop-web"` against the type arm.

**Explored**: `service_transformer.cue` test data and the resolution-guard convention already recorded there (`_testServiceUDPPortResolves`).

**Decision**: Give the fixtures a concrete `#instance` matching their `#moduleInstanceMetadata`, and add a resolution guard `"\(...metadata.name)" & "shop-web"` for the default-named case.

**Rationale**: The interpolation forces the default to a string before unification; a wrong or missing default fails loudly.

## Risks / Trade-offs

- [A downstream module attaches `#ExposeTrait` raw] -> refuses at vet with `field is required but not present`; the fix is the wrapper or an explicit `spec.expose.name`. No known consumer does this (17 fleet modules and 4 cli fixtures/templates checked).
- [The wrapper default masks a wrong `#instance`] -> the resolution guard in the transformer test data pins the resolved string.
- [A future dot-hostile kind is added without a slot, or with a conditional that can stay unresolved] -> `docs/name-constraints.md` records the rule and the deferred-validator hazard; the transformer test data carries the must-fail record.
- [A module attaches `#ContainerResource` or `#StatefulWorkloadBlueprint` raw] -> the wrapper-hosted conditional does not reach it; the blueprint constant does. Reported to 0019 as a D23 deviation.

## Durable decisions

- Where a `#nameConstraint` goes (the primitive that owns the reason), that a computed slot must resolve on every attachment path because an unresolved slot defers every validator in the component (hence the wrapper spelling), and the wrapper re-declaration rule for `#names` / `matchLabels` / `spec` (lexical scope): lands in `docs/name-constraints.md`, linked from `CLAUDE.md` § Working Style for Agents.
- Transformer fixtures that exercise a wrapper default must carry a concrete `#instance` and a resolution guard: lands in the same note.
