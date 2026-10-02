package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ServiceAccount Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes ServiceAccount that gives pods an identity.
#ServiceAccountResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "serviceaccount"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/serviceaccount@v1"
		description:    "A native Kubernetes ServiceAccount that gives pods an identity"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: serviceaccount: schemas.#ServiceAccountSchema
}

#ServiceAccount: c.#Component & {
	#resources: {(#ServiceAccountResource.metadata.fqn): #ServiceAccountResource}
}
