## Why

Enhancement 0015 D3 puts the effective registry partly in cluster state: a provider module tells the platform "I implement these contracts" by way of a cluster-scoped `TransformerRegistration` CR, gated by the RBAC the operator already enforces. D9 decides where that CR is authored, and the answer is here rather than in `core`: a `#Resource` contract this catalog publishes plus the transformer that renders it, so registration is self-hosting on the contract machinery it configures. Nothing of it exists yet, and it is the one piece the operator slice consumes rather than produces: the CRD the operator adds is the other end of this contract. `backup@v1alpha1` (opm 4.2.0) gave the fleet its first provider-fulfilled contract; without a registration surface no provider catalog can claim to implement it.

## What Changes

- `opm/resources/v1alpha1/transformer_registration.cue` (new): the `transformer-registration@v1alpha1` `#Resource` contract. `fulfilment: "catalog"` (this catalog ships the transformer), no `matchLabels` (the renderer selects on the contract FQN alone, so D5's guard and the match glue are untouched). Spec: `catalog!`, `version!`, `provides!`.
- `opm/transformers/transformer_registration_transformer.cue` (new): renders one `opm.opmodel.dev/v1alpha1 TransformerRegistration` per component carrying the contract. `metadata.name` is the dot-joined `<namespace>.<name>` of the rendering instance (D12) and `spec.providerRef` is stamped from the same instance metadata, never authored (D11). Golden fixtures in the file, the convention every transformer here follows.
- `opm/catalog.cue`: both members listed in `#resources` and `#transformers`, which `task vet:listing` requires.
- **Not in this change**: the pre-bound `#PreBoundRegistration` fold a provider catalog exports (D11's authoring half), the acceptance gates (D8, D10, D11 verification), and any change to `#Module`. D9 is explicit that `#Module` gains no authored field and that the derived `#provides` fold ships only when a consumer exists.

No member moves apiVersion; nothing published changes shape. The contract is new at `v1alpha1`, which promises nothing (0010 D34), so the operator slice can still move it while both sides are being built.

## Before / After

**Before**

```cue
// none — no registration surface exists in any catalog
```

**After**

```cue
// opm/resources/v1alpha1/transformer_registration.cue
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

	// The declaring catalog implements it: the transformer below renders the
	// CR, so registration is self-hosting on the contract machinery.
	fulfilment: "catalog"

	// NO matchLabels, deliberately: the renderer selects on this contract's
	// FQN alone, so the bucket needs no label vocabulary.

	spec: transformerRegistration: {
		// The provider CATALOG's coordinates — never a module's. The
		// operator's acceptance refuses a non-#Catalog artifact structurally
		// (0015 D10), which is why no gate is needed here.
		catalog!: c.#ModulePathType
		version!: c.#VersionType

		// Every provider-fulfilled contract the named catalog's own
		// transformers require. Authored today; a provider catalog derives it
		// from its own transformer map once D11's fold ships.
		provides!: [...c.#ContractFQNType]
	}
}
```

```cue
// opm/transformers/transformer_registration_transformer.cue
#TransformerRegistrationTransformer: c.#ComponentTransformer & {
	requiredResources: (res.#TransformerRegistrationResource.metadata.fqn): res.#TransformerRegistrationResource
	producesKinds: ["TransformerRegistration"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext
		let _i = #context.#moduleInstanceMetadata
		output: {
			apiVersion: "opm.opmodel.dev/v1alpha1"
			kind:       "TransformerRegistration"
			// D12: cluster-scoped, dot-joined; a namespace cannot contain a
			// dot, so two instances of one provider module produce two
			// claims and the second is refused at acceptance naming the
			// claimant, rather than fighting over one object.
			metadata: name: "\(_i.namespace).\(_i.name)"
			spec: {
				catalog:  #component.spec.transformerRegistration.catalog
				version:  #component.spec.transformerRegistration.version
				provides: #component.spec.transformerRegistration.provides
				// D11: stamped from the rendering instance, never authored —
				// the provider IS the instance that rendered the claim.
				providerRef: {name: _i.name, namespace: _i.namespace}
			}
		}
	}
}
```

## Impact

- **`opm-operator`**: the consumer this exists for. Its 0015 slice adds the `TransformerRegistration` CRD, whose shape must match the rendered object above, plus acceptance (D8, D10, D11) and the RBAC split (D3). Nothing to do until that slice; this change is what it builds against. The two must agree on the group, version and kind literals, which is why they are written here as literals rather than derived.
- **`modules` and `opm-modules`**: nothing. No existing module attaches the contract, and no existing member changes.
- **Platforms subscribing to the catalog**: nothing to do. A platform on the new build gains one more listed resource and one more transformer; a platform on an older build is unaffected. A cluster with no `TransformerRegistration` CRD is unaffected until a module attaches the contract, at which point the apply fails on the missing kind, which is the correct loud failure (0010 D28).
- **`cli` fixtures under `testing.opmodel.dev`**: nothing. They pin their own catalog builds.
- **Release class**: `feat:` for both members, so opm cuts a minor. The change does not rely on the v2 alpha line: it adds members and touches no published shape.

## Enhancement

`enhancements/0015` D9, the authoring surface, with the shapes pre-drafted in that entry's `contracts/contracts.cue` (`#TransformerRegistrationContract`, `#RenderedRegistration`). D11's stamping and D12's naming are implemented here because they are properties of the rendered object; D11's derivation fold and D10's and D11's acceptance checks are the operator's and a provider catalog's, not this change's. Declared in `enhancement.yaml`.
