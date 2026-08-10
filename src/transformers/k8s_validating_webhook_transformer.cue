package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sValidatingWebhookConfigurationTransformer passes native Kubernetes
// ValidatingWebhookConfiguration resources through with OPM context applied.
// ValidatingWebhookConfiguration is cluster-scoped: no namespace.
#K8sValidatingWebhookConfigurationTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-validatingwebhookconfiguration-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-validatingwebhookconfiguration-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ValidatingWebhookConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "validatingwebhookconfiguration"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sValidatingWebhookConfigurationResource.metadata.fqn): res.#K8sValidatingWebhookConfigurationResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_vwc:  #component.spec.k8sValidatingwebhookconfiguration
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "admissionregistration.k8s.io/v1"
			kind:       "ValidatingWebhookConfiguration"
			metadata: {
				name:   _name
				labels: #context.labels
				if _vwc.metadata != _|_ {
					if _vwc.metadata.annotations != _|_ {
						annotations: _vwc.metadata.annotations
					}
				}
			}
			if _vwc.webhooks != _|_ {
				webhooks: _vwc.webhooks
			}
		}
	}
}
