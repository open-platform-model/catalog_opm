package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #StatefulSetTransformer passes native Kubernetes StatefulSet resources through
// with OPM context applied (name prefix, namespace, labels).
#StatefulSetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "statefulset-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/statefulset-transformer@\(id.Version)"
		description:    "Passes native Kubernetes StatefulSet resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "statefulset"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#StatefulSetResource.metadata.fqn): res.#StatefulSetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_sts:  #component.spec.statefulset
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _sts.metadata != _|_ {
					if _sts.metadata.annotations != _|_ {
						annotations: _sts.metadata.annotations
					}
				}
			}
			if _sts.spec != _|_ {
				spec: _sts.spec
			}
		}
	}
}
