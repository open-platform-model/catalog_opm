package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sPodDisruptionBudgetTransformer passes native Kubernetes PodDisruptionBudget resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sPodDisruptionBudgetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-poddisruptionbudget-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-poddisruptionbudget-transformer@\(id.Version)"
		description:    "Passes native Kubernetes PodDisruptionBudget resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "policy"
			"core.opmodel.dev/resource-type":     "poddisruptionbudget"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sPodDisruptionBudgetResource.metadata.fqn): res.#K8sPodDisruptionBudgetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pdb:  #component.spec.k8sPoddisruptionbudget
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
