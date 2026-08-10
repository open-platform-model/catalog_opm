package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sIngressTransformer passes native Kubernetes Ingress resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sIngressTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-ingress-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-ingress-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Ingress resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "ingress"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sIngressResource.metadata.fqn): res.#K8sIngressResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_ing:  #component.spec.k8sIngress
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _ing.metadata != _|_ {
					if _ing.metadata.annotations != _|_ {
						annotations: _ing.metadata.annotations
					}
				}
			}
			if _ing.spec != _|_ {
				spec: _ing.spec
			}
		}
	}
}
