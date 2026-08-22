package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ConfigMap Resource Definition
/////////////////////////////////////////////////////////////////

// #ConfigMapResource defines a native Kubernetes ConfigMap as an OPM resource.
// Use this for environment config, application settings, and non-sensitive key-value data.
#ConfigMapResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "configmap"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/configmap@v1"
		description:    "A native Kubernetes ConfigMap resource"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	spec: configmap: schemas.#ConfigMapSchema
}

#ConfigMap: c.#Component & {
	#resources: {(#ConfigMapResource.metadata.fqn): #ConfigMapResource}
}
