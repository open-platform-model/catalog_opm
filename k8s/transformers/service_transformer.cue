package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ServiceTransformer passes native Kubernetes Service resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#ServiceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "service-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/service-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Service resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "service"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ServiceResource.metadata.fqn): res.#ServiceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_svc:  #component.spec.service
		_name: #component.#names.resourceName

		output: {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _svc.metadata != _|_ {
					if _svc.metadata.annotations != _|_ {
						annotations: _svc.metadata.annotations
					}
				}
			}
			if _svc.spec != _|_ {
				spec: _svc.spec
			}
		}
	}
}
