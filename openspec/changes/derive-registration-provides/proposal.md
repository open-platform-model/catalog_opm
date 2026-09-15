## Why

Enhancement 0015 D11 states the registration's summary property: *"No field of the shipped CR is hand-written by the module author… the only authored fact left in the whole flow is the catalog dependency version in the module's `cue.mod`."* The CR contains no author-trusted data, which is what keeps acceptance simple — its only free variable is whether a platform-team identity applied it.

`provides` breaks that today. `#TransformerRegistrationResource` declares it as an authored list, and its own doc comment admits the gap:

> Authored today; a provider catalog derives it from its own transformer map once 0015 D11's fold ships.

`opm-operator` shipped the other half in alpha.19: acceptance re-derives the provider set from the fetched catalog and refuses any drift from the claim, naming both lists. So a hand-authored `provides` that disagrees with the catalog is already refused — but the author still has to get it right by hand, and the refusal arrives in a cluster rather than at `cue vet`. This change removes the authoring step, so the two lists agree by construction.

## What Changes

- `opm/resources/v1alpha1/transformer_registration.cue`: add `#PreBoundRegistration`, a definition a provider catalog unifies with its own identity package and its own `#transformers` map. `catalog` and `version` interpolate from the identity; `provides` derives as a fold over those transformers, collecting every required contract whose value carries `fulfilment: "provider"`, deduplicated through struct keys.
- `#TransformerRegistrationResource` is **unchanged**. `provides!` stays required; the helper fills it. Keeping the field required is what lets the operator refuse a claim that arrives without one, which CUE's incomplete-value behaviour makes reachable.
- The resource's doc comment loses the "authored today" note, since it stops being true.

Not breaking. No member's schema changes, no `apiVersion` segment moves, and no `catalog.cue` entry changes. The helper carries no `fqn`, so it is not a catalog member and `task vet:listing` does not expect a listing (`.tasks/listing.sh` detects members by grepping for an `fqn:` field).

## Before / After

**Before**

```cue
// A provider catalog's module authors the list by hand:
#TransformerRegistration & {
	metadata: name: "k8up"
	spec: transformerRegistration: {
		catalog: "opmodel.dev/catalogs/k8up@v1"
		version: "1.0.0"
		provides: ["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]
	}
}
```

**After**

```cue
// The helper (new, in opm/resources/v1alpha1/):
#PreBoundRegistration: {
	#identity: {
		modulePath: c.#ModulePathType
		version:    c.#VersionType
	}
	#transformers: [string]: _

	// Every provider-fulfilled contract this catalog's own transformers
	// require, deduplicated via struct keys.
	_providerSet: {
		for _, t in #transformers {
			if t.requiredTraits != _|_ {
				for fqn, m in t.requiredTraits if m.fulfilment == "provider" {(fqn): true}
			}
			if t.requiredResources != _|_ {
				for fqn, m in t.requiredResources if m.fulfilment == "provider" {(fqn): true}
			}
		}
	}

	spec: transformerRegistration: {
		catalog: #identity.modulePath
		version: #identity.version
		provides: [for fqn, _ in _providerSet {fqn}]
	}
}

// A provider catalog's module then authors nothing:
#TransformerRegistration & #PreBoundRegistration & {
	metadata: name: "k8up"
	#identity: {modulePath: id.ModulePath, version: id.Version}
	#transformers: k8up.#transformers
}
```

## Impact

**Release class: `feat:`** — `opm` 4.3.1 → 4.4.0. One new definition, nothing removed or tightened.

Downstream consumers, and what each does:

- **Subscribing platforms**: nothing. The helper is authoring-side; it changes no rendered output and no contract.
- **The `modules` fleet**: nothing. No module attaches the registration contract.
- **`cli` fixtures under `testing.opmodel.dev`**: nothing. No fixture renders a registration.
- **`opm-operator`**: nothing to do. Its D11 verification compares the claim's `provides` against what it re-derives from the fetched catalog; a claim built through this helper agrees by construction, which is the point. A hand-authored claim keeps working and keeps being verified.
- **A future provider catalog**: this is the consumer the helper exists for. There is none yet, which is why nothing breaks and nothing needs migrating.

Relies on the v2 alpha line: no. `opm` is on the v4 line and this change does not touch the module path.

## Not in this change

- **Making `provides` optional or derived on `#TransformerRegistrationResource` itself.** The field stays required so a claim missing it is refused. The helper is the ergonomic path, not a replacement for the constraint.
- **A `#provides` fold over a module's components** (the derived-not-authored surface D3 mentions for a future `opm module inspect` or 0011 publish gate). Different fold, different consumer, and 0015 D3 explicitly keeps it out of the core delta until something consumes it.
- Anything in `opm-operator`. Its half of D11 shipped in alpha.19.

## Enhancement

`enhancements/0015` D11. This change delivers its authoring half — the pre-bound registration value whose `provides` derives from the provider catalog's own transformer map — and completes the decision, whose verification half shipped in `opm-operator` alpha.19. Declared in `enhancement.yaml`.
