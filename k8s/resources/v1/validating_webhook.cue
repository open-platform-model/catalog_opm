package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ValidatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// #ValidatingWebhookConfigurationResource defines a native Kubernetes
// ValidatingWebhookConfiguration as an OPM resource.
// Use this to register admission webhooks that validate resource requests.
#ValidatingWebhookConfigurationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "validatingwebhookconfiguration"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/validatingwebhookconfiguration@v1"
		description:    "A native Kubernetes ValidatingWebhookConfiguration resource"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	spec: validatingwebhookconfiguration: schemas.#ValidatingWebhookConfigurationSchema
}

#ValidatingWebhookConfiguration: c.#Component & {
	#resources: {(#ValidatingWebhookConfigurationResource.metadata.fqn): #ValidatingWebhookConfigurationResource}
}
