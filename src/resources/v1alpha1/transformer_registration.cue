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
		// transformers require. Required, not derived, so a claim arriving
		// without one is refused; #PreBoundRegistration below is what fills
		// it, folding the list out of the provider catalog's transformers.
		provides!: [...c.#ContractFQNType]
	}
}

#TransformerRegistration: c.#Component & {
	#resources: (#TransformerRegistrationResource.metadata.fqn): #TransformerRegistrationResource
}

/////////////////////////////////////////////////////////////////
//// Pre-bound registration
/////////////////////////////////////////////////////////////////

// WHY this definition carries no fqn: it is a constructor, not a catalog
// member. `task vet:listing` (.tasks/listing.sh) builds its expected set by
// grepping for an `fqn:` field under each kind directory, so a definition
// without one contributes nothing to the diff and needs no catalog.cue entry.
// Adding an fqn here would list a member no platform can subscribe to and
// break the gate. Do not add one.
//
// WHY this catalog cannot exercise the fold on itself: a provider-fulfilled
// member ships no transformer here, and never a stub (CLAUDE.md, Working
// Style), so no opm transformer requires a provider-fulfilled contract and
// folding over opm's own #transformers yields an empty set. That is the
// correct result for opm; the helper exists for a PROVIDER catalog to
// instantiate, and the fixtures in transformers/ supply synthetic input.
//
// WHY it EMBEDS #TransformerRegistration rather than sitting beside it:
// unifying two closed definitions closes the result to the INTERSECTION of
// their allowed fields, so `#TransformerRegistration & #PreBoundRegistration`
// refuses metadata.name with "field not allowed" (measured, cue v0.17.1). A
// helper that extends a definition embeds it, and adds only definition and
// hidden fields, which closedness does not check. See
// docs/cue-guard-closedness-workaround.md.

// #TransformerRegistration pre-bound for a provider catalog: pass the
// catalog's own identity package and its own #transformers map and the module
// authors no spec field. catalog and version come from the identity; provides
// folds out of those transformers, so the claim cannot disagree with the
// catalog it names (0015 D11).
#PreBoundRegistration: #TransformerRegistration & {
	// The provider catalog's identity package — `{modulePath: id.ModulePath,
	// version: id.Version}` at the call site.
	#identity: {
		modulePath: c.#ModulePathType
		version:    c.#VersionType
	}

	// The provider catalog's own #transformers map. Typed openly because the
	// fold reads two fields of each value and nothing else.
	#transformers: [string]: _

	// Every provider-fulfilled contract those transformers require,
	// deduplicated through struct keys. Both demand maps are optional on
	// core's #ComponentTransformer, so each is guarded before comprehending.
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
