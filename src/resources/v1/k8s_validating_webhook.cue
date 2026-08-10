package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// ValidatingWebhookConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sValidatingWebhookConfigurationResource defines a native Kubernetes
// ValidatingWebhookConfiguration as an OPM resource.
// Use this to register admission webhooks that validate resource requests.
#K8sValidatingWebhookConfigurationResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-validatingwebhookconfiguration"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-validatingwebhookconfiguration@v1"
		description:    "A native Kubernetes ValidatingWebhookConfiguration resource"
		labels: {
			"resource.opmodel.dev/category": "admission"
		}
	}

	spec: k8sValidatingwebhookconfiguration: schemas.#ValidatingWebhookConfigurationSchema
}

#K8sValidatingWebhookConfiguration: c.#Component & {
	#resources: {(#K8sValidatingWebhookConfigurationResource.metadata.fqn): #K8sValidatingWebhookConfigurationResource}
}
