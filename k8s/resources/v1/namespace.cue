package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Namespace Resource Definition
/////////////////////////////////////////////////////////////////

// #NamespaceResource defines a native Kubernetes Namespace as an OPM resource.
// Use this to create and manage cluster-scoped namespace isolation boundaries.
#NamespaceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "namespace"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/namespace@v1"
		description:    "A native Kubernetes Namespace resource"
		labels: {
			"resource.opmodel.dev/category": "cluster"
		}
	}

	spec: namespace: schemas.#NamespaceSchema
}

#Namespace: c.#Component & {
	#resources: {(#NamespaceResource.metadata.fqn): #NamespaceResource}
}
