package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #MutatingWebhookConfigurationTransformer passes native Kubernetes
// MutatingWebhookConfiguration resources through with OPM context applied.
// MutatingWebhookConfiguration is cluster-scoped: no namespace.
#MutatingWebhookConfigurationTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "mutatingwebhookconfiguration-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/mutatingwebhookconfiguration-transformer@\(id.Version)"
		description:    "Passes native Kubernetes MutatingWebhookConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "mutatingwebhookconfiguration"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#MutatingWebhookConfigurationResource.metadata.fqn): res.#MutatingWebhookConfigurationResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_mwc:  #component.spec.mutatingwebhookconfiguration
		_name: #component.#names.resourceName

		output: {
			apiVersion: "admissionregistration.k8s.io/v1"
			kind:       "MutatingWebhookConfiguration"
			metadata: {
				name:   _name
				labels: #context.labels
				if _mwc.metadata != _|_ {
					if _mwc.metadata.annotations != _|_ {
						annotations: _mwc.metadata.annotations
					}
				}
			}
			if _mwc.webhooks != _|_ {
				webhooks: _mwc.webhooks
			}
		}
	}
}
