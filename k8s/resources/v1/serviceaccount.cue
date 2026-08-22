package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ServiceAccount Resource Definition
/////////////////////////////////////////////////////////////////

// #ServiceAccountResource defines a native Kubernetes ServiceAccount as an OPM resource.
// Use this to provide an identity for processes running in pods.
#ServiceAccountResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "serviceaccount"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/serviceaccount@v1"
		description:    "A native Kubernetes ServiceAccount resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: serviceaccount: schemas.#ServiceAccountSchema
}

#ServiceAccount: c.#Component & {
	#resources: {(#ServiceAccountResource.metadata.fqn): #ServiceAccountResource}
}
