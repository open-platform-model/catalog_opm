package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sNetworkPolicyTransformer passes native Kubernetes NetworkPolicy resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sNetworkPolicyTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-networkpolicy-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-networkpolicy-transformer@\(id.Version)"
		description:    "Passes native Kubernetes NetworkPolicy resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "networkpolicy"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sNetworkPolicyResource.metadata.fqn): res.#K8sNetworkPolicyResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_np:   #component.spec.k8sNetworkpolicy
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _np.metadata != _|_ {
					if _np.metadata.annotations != _|_ {
						annotations: _np.metadata.annotations
					}
				}
			}
			if _np.spec != _|_ {
				spec: _np.spec
			}
		}
	}
}
