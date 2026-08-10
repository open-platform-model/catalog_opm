package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sPodTransformer passes native Kubernetes Pod resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sPodTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-pod-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-pod-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Pod resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "pod"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sPodResource.metadata.fqn): res.#K8sPodResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pod:  #component.spec.k8sPod
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Pod"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _pod.metadata != _|_ {
					if _pod.metadata.annotations != _|_ {
						annotations: _pod.metadata.annotations
					}
				}
			}
			if _pod.spec != _|_ {
				spec: _pod.spec
			}
		}
	}
}
