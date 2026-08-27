package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #PodTransformer passes native Kubernetes Pod resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#PodTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "pod-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/pod-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Pod resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "pod"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PodResource.metadata.fqn): res.#PodResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pod:  #component.spec.pod
		_name: #component.#names.resourceName

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
