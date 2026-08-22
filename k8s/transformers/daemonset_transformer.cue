package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #DaemonSetTransformer passes native Kubernetes DaemonSet resources through
// with OPM context applied (name prefix, namespace, labels).
#DaemonSetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "daemonset-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/daemonset-transformer@\(id.Version)"
		description:    "Passes native Kubernetes DaemonSet resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "daemonset"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#DaemonSetResource.metadata.fqn): res.#DaemonSetResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_ds:   #component.spec.daemonset
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
