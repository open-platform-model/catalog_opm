package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// WHY the group, version and kind below are literals: they name a CRD that
// opm-operator owns (enhancement 0015 D3), so nothing in this catalog can
// derive them. The operator's TransformerRegistration CRD must match these
// three strings exactly — this file and that CRD are the two sides of one
// contract, and changing either alone breaks the other.
// WHY the group is the bare `opmodel.dev`, with no `opm.` or kind-specific
// prefix: enhancement 0002 D5 chose one flat group for every OPM CRD and
// rejected prefixed and per-kind groups, paying a full cluster migration for
// it. A prefixed group here would name a CRD no cluster installs, so the
// rendered claim could never be applied (measured: `opm` 4.3.0 shipped a
// dot-prefixed group here and was unappliable).

// TransformerRegistrationTransformer renders a provider module's claim as the
// cluster-scoped TransformerRegistration the operator accepts. The object's
// name and spec.providerRef come from the rendering instance alone, so a
// module cannot claim to be another provider (0015 D11, D12).
#TransformerRegistrationTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "transformer-registration-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/transformer-registration-transformer@\(id.Version)"
		description:    "Renders a provider module's contract claim as a cluster-scoped TransformerRegistration"

		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "transformerregistration"
		}
	}

	requiredLabels: {}

	// The contract FQN alone selects this transformer; the resource declares
	// no matchLabels, so there is no label vocabulary to require.
	requiredResources: {
		(res.#TransformerRegistrationResource.metadata.fqn): res.#TransformerRegistrationResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	producesKinds: ["TransformerRegistration"]

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		_i: #context.#moduleInstanceMetadata
		_r: #component.spec.transformerRegistration

		// One claim per component carrying the contract, so output is a
		// struct (core's StructKind arm), never a list.
		output: {
			apiVersion: "opmodel.dev/v1alpha1"
			kind:       "TransformerRegistration"
			metadata: {
				// Cluster-scoped, dot-joined (0015 D12): a namespace cannot
				// contain a dot, so two instances of one provider module
				// produce two claims and the second is refused at acceptance
				// naming the claimant, rather than fighting over one object.
				name:   "\(_i.namespace).\(_i.name)"
				labels: #context.labels
			}
			spec: {
				catalog:  _r.catalog
				version:  _r.version
				provides: _r.provides

				// Stamped from the rendering instance, never authored: the
				// provider IS the instance that rendered the claim (0015 D11).
				providerRef: {name: _i.name, namespace: _i.namespace}
			}
		}
	}
}
