package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// MutatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes MutatingWebhookConfiguration that registers mutating
// admission webhooks.
#MutatingWebhookConfigurationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "mutatingwebhookconfiguration"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/mutatingwebhookconfiguration@v1"
		description:    "A native Kubernetes MutatingWebhookConfiguration that registers mutating admission webhooks"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	spec: mutatingwebhookconfiguration: schemas.#MutatingWebhookConfigurationSchema
}

#MutatingWebhookConfiguration: c.#Component & {
	#resources: {(#MutatingWebhookConfigurationResource.metadata.fqn): #MutatingWebhookConfigurationResource}
}
