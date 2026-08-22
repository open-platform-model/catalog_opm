package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// MutatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// #MutatingWebhookConfigurationResource defines a native Kubernetes
// MutatingWebhookConfiguration as an OPM resource.
// Use this to register admission webhooks that mutate resource requests.
#MutatingWebhookConfigurationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "mutatingwebhookconfiguration"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/mutatingwebhookconfiguration@v1"
		description:    "A native Kubernetes MutatingWebhookConfiguration resource"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	spec: mutatingwebhookconfiguration: schemas.#MutatingWebhookConfigurationSchema
}

#MutatingWebhookConfiguration: c.#Component & {
	#resources: {(#MutatingWebhookConfigurationResource.metadata.fqn): #MutatingWebhookConfigurationResource}
}
