package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// ServiceAccount Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sServiceAccountResource defines a native Kubernetes ServiceAccount as an OPM resource.
// Use this to provide an identity for processes running in pods.
#K8sServiceAccountResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-serviceaccount"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-serviceaccount@v1"
		description:    "A native Kubernetes ServiceAccount resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: k8sServiceaccount: schemas.#ServiceAccountSchema
}

#K8sServiceAccount: c.#Component & {
	#resources: {(#K8sServiceAccountResource.metadata.fqn): #K8sServiceAccountResource}
}
