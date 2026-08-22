package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ValidatingWebhookConfigurationTransformer passes native Kubernetes
// ValidatingWebhookConfiguration resources through with OPM context applied.
// ValidatingWebhookConfiguration is cluster-scoped: no namespace.
#ValidatingWebhookConfigurationTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "validatingwebhookconfiguration-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/validatingwebhookconfiguration-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ValidatingWebhookConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "validatingwebhookconfiguration"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ValidatingWebhookConfigurationResource.metadata.fqn): res.#ValidatingWebhookConfigurationResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_vwc:  #component.spec.validatingwebhookconfiguration
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
