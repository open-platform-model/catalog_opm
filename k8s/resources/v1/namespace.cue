package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Namespace Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes Namespace.
#NamespaceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "namespace"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/namespace@v1"
		description:    "A native Kubernetes Namespace"
		labels: {
			"resource.opmodel.dev/category": "cluster"
		}
	}

	spec: namespace: schemas.#NamespaceSchema
}

#Namespace: c.#Component & {
	#resources: {(#NamespaceResource.metadata.fqn): #NamespaceResource}
}
