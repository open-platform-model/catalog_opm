package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sIngressClassTransformer passes native Kubernetes IngressClass resources through
// with OPM context applied (name prefix, labels). IngressClass is cluster-scoped: no namespace.
#K8sIngressClassTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-ingressclass-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-ingressclass-transformer@\(id.Version)"
		description:    "Passes native Kubernetes IngressClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "ingressclass"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sIngressClassResource.metadata.fqn): res.#K8sIngressClassResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_ic:   #component.spec.k8sIngressclass
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "IngressClass"
			metadata: {
				name:   _name
				labels: #context.labels
				if _ic.metadata != _|_ {
					if _ic.metadata.annotations != _|_ {
						annotations: _ic.metadata.annotations
					}
				}
			}
			if _ic.spec != _|_ {
				spec: _ic.spec
			}
		}
	}
}
