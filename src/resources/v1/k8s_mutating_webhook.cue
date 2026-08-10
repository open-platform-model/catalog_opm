package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// MutatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sMutatingWebhookConfigurationResource defines a native Kubernetes
// MutatingWebhookConfiguration as an OPM resource.
// Use this to register admission webhooks that mutate resource requests.
#K8sMutatingWebhookConfigurationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-mutatingwebhookconfiguration"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-mutatingwebhookconfiguration@v1"
		description:    "A native Kubernetes MutatingWebhookConfiguration resource"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	spec: k8sMutatingwebhookconfiguration: schemas.#MutatingWebhookConfigurationSchema
}

#K8sMutatingWebhookConfiguration: c.#Component & {
	#resources: {(#K8sMutatingWebhookConfigurationResource.metadata.fqn): #K8sMutatingWebhookConfigurationResource}
}
