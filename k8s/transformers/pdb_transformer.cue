package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #PodDisruptionBudgetTransformer passes native Kubernetes PodDisruptionBudget resources through
// with OPM context applied (name prefix, namespace, labels).
#PodDisruptionBudgetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "poddisruptionbudget-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/poddisruptionbudget-transformer@\(id.Version)"
		description:    "Passes native Kubernetes PodDisruptionBudget resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "policy"
			"core.opmodel.dev/resource-type":     "poddisruptionbudget"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PodDisruptionBudgetResource.metadata.fqn): res.#PodDisruptionBudgetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pdb:  #component.spec.poddisruptionbudget
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _pdb.metadata != _|_ {
					if _pdb.metadata.annotations != _|_ {
						annotations: _pdb.metadata.annotations
					}
				}
			}
			if _pdb.spec != _|_ {
				spec: _pdb.spec
			}
		}
	}
}
