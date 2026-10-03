package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// ServiceAccountResourceTransformer converts standalone ServiceAccount resources
// to Kubernetes ServiceAccounts. Separate from the WorkloadIdentity-based
// #ServiceAccountTransformer which handles trait-attached identities.
#ServiceAccountResourceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "serviceaccount-resource-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/serviceaccount-resource-transformer@\(id.Version)"
		description:    "Converts standalone ServiceAccount resources to Kubernetes ServiceAccounts"

		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "serviceaccount-resource"
		}
	}

	requiredLabels: {}

	// Required resources - ServiceAccount resource MUST be present
	requiredResources: {
		(res.#ServiceAccountResource.metadata.fqn): res.#ServiceAccountResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_serviceAccount: #component.spec.serviceAccount

		output: (#ToK8sServiceAccount & {
			"in":    _serviceAccount
			context: #context
		}).out
	}
}
