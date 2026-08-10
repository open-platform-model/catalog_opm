package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sMutatingWebhookConfigurationTransformer passes native Kubernetes
// MutatingWebhookConfiguration resources through with OPM context applied.
// MutatingWebhookConfiguration is cluster-scoped: no namespace.
#K8sMutatingWebhookConfigurationTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-mutatingwebhookconfiguration-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-mutatingwebhookconfiguration-transformer@\(id.Version)"
		description:    "Passes native Kubernetes MutatingWebhookConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "mutatingwebhookconfiguration"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sMutatingWebhookConfigurationResource.metadata.fqn): res.#K8sMutatingWebhookConfigurationResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_mwc:  #component.spec.k8sMutatingwebhookconfiguration
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
