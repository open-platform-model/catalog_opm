package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// ConfigMap Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sConfigMapResource defines a native Kubernetes ConfigMap as an OPM resource.
// Use this for environment config, application settings, and non-sensitive key-value data.
#K8sConfigMapResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-configmap"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-configmap@v1"
		description:    "A native Kubernetes ConfigMap resource"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	spec: k8sConfigmap: schemas.#ConfigMapSchema
}

#K8sConfigMap: c.#Component & {
	#resources: {(#K8sConfigMapResource.metadata.fqn): #K8sConfigMapResource}
}
