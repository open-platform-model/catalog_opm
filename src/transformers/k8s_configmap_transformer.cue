package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sConfigMapTransformer passes native Kubernetes ConfigMap resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sConfigMapTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-configmap-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-configmap-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ConfigMap resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "configmap"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sConfigMapResource.metadata.fqn): res.#K8sConfigMapResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_cm:   #component.spec.k8sConfigmap
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _cm.metadata != _|_ {
					if _cm.metadata.annotations != _|_ {
						annotations: _cm.metadata.annotations
					}
				}
			}
			if _cm.data != _|_ {
				data: _cm.data
			}
			if _cm.binaryData != _|_ {
				binaryData: _cm.binaryData
			}
			if _cm.immutable != _|_ {
				immutable: _cm.immutable
			}
		}
	}
}
