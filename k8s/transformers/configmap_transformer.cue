package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ConfigMapTransformer passes native Kubernetes ConfigMap resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#ConfigMapTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "configmap-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/configmap-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ConfigMap resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "configmap"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ConfigMapResource.metadata.fqn): res.#ConfigMapResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_cm:   #component.spec.configmap
		_name: #component.#names.resourceName

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
