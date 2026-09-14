package v1alpha1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
)

/////////////////////////////////////////////////////////////////
//// TransformerRegistration Resource
/////////////////////////////////////////////////////////////////

// WHY fulfilment is "catalog": the transformer that renders this claim ships
// in this catalog (transformers/transformer_registration_transformer.cue), so
// registration is self-hosting on the contract machinery it configures
// (enhancement 0015 D9).
//
// WHY there is no matchLabels: the renderer selects on this contract's FQN
// alone, so the contract introduces no matching vocabulary and D5's guard is
// untouched. #nameConstraint stays unset for a related reason — the rendered
// CR's name comes from the rendering instance, never from the owning
// component's resourceName, so this member constrains no authored name.

// A provider module's claim that its catalog implements platform contracts.
// Renders one cluster-scoped TransformerRegistration per component carrying
// it. All three spec fields are required: a claim missing one is not a partial
// claim, it is nothing, and failing the render loudly (0010 D28) beats
// registering an empty `provides`.
#TransformerRegistrationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1alpha1"
		name:           "transformer-registration"
		apiVersion:     "v1alpha1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/transformer-registration@v1alpha1"
		description:    "A provider module's claim that its catalog implements platform contracts"
		labels: {
			"resource.opmodel.dev/category": "cluster"
		}
	}

	fulfilment: "catalog"

	spec: transformerRegistration: {
		// The provider CATALOG's module path, never a module's: a catalog is
		// what carries transformers, so a claim naming a module names nothing
		// that could implement a contract. The operator's acceptance refuses a
		// non-catalog artifact structurally (0015 D10), so nothing beyond the
		// type is gated here.
		catalog!: c.#ModulePathType

		// The released version of that catalog. It pins the claim to one
		// build, which is what lets acceptance re-derive `provides` from the
		// artifact this names.
		version!: c.#VersionType

		// Every provider-fulfilled contract the named catalog's own
		// transformers require. Authored today; a provider catalog derives it
		// from its own transformer map once 0015 D11's fold ships.
		provides!: [...c.#ContractFQNType]
	}
}

#TransformerRegistration: c.#Component & {
	#resources: (#TransformerRegistrationResource.metadata.fqn): #TransformerRegistrationResource
}
