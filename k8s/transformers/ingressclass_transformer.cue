package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #IngressClassTransformer passes native Kubernetes IngressClass resources through
// with OPM context applied (name from the component's `#names`, labels). IngressClass is cluster-scoped: no namespace.
#IngressClassTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "ingressclass-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/ingressclass-transformer@\(id.Version)"
		description:    "Passes native Kubernetes IngressClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "ingressclass"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#IngressClassResource.metadata.fqn): res.#IngressClassResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_ic:   #component.spec.ingressclass
		_name: #component.#names.resourceName

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
