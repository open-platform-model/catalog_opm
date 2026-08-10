package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sServiceTransformer passes native Kubernetes Service resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sServiceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-service-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-service-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Service resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "network"
			"core.opmodel.dev/resource-type":     "service"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sServiceResource.metadata.fqn): res.#K8sServiceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_svc:  #component.spec.k8sService
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
