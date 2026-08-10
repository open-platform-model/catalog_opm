package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sDaemonSetTransformer passes native Kubernetes DaemonSet resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sDaemonSetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-daemonset-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-daemonset-transformer@\(id.Version)"
		description:    "Passes native Kubernetes DaemonSet resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "daemonset"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sDaemonSetResource.metadata.fqn): res.#K8sDaemonSetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_ds:   #component.spec.k8sDaemonset
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _ds.metadata != _|_ {
					if _ds.metadata.annotations != _|_ {
						annotations: _ds.metadata.annotations
					}
				}
			}
			if _ds.spec != _|_ {
				spec: _ds.spec
			}
		}
	}
}
