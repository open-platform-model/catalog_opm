package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #NetworkPolicyTransformer passes native Kubernetes NetworkPolicy resources through
// with OPM context applied (name prefix, namespace, labels).
#NetworkPolicyTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "networkpolicy-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/networkpolicy-transformer@\(id.Version)"
		description:    "Passes native Kubernetes NetworkPolicy resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "networkpolicy"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#NetworkPolicyResource.metadata.fqn): res.#NetworkPolicyResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_np:   #component.spec.networkpolicy
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
