package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #IngressTransformer passes native Kubernetes Ingress resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#IngressTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "ingress-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/ingress-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Ingress resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "ingress"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#IngressResource.metadata.fqn): res.#IngressResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_ing:  #component.spec.ingress
		_name: #component.#names.resourceName

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
