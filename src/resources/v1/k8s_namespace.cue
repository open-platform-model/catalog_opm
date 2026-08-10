package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Namespace Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sNamespaceResource defines a native Kubernetes Namespace as an OPM resource.
// Use this to create and manage cluster-scoped namespace isolation boundaries.
#K8sNamespaceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-namespace"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-namespace@v1"
		description:    "A native Kubernetes Namespace resource"
		labels: {
			"resource.opmodel.dev/category": "cluster"
		}
	}

	spec: k8sNamespace: schemas.#NamespaceSchema
}

#K8sNamespace: c.#Component & {
	#resources: {(#K8sNamespaceResource.metadata.fqn): #K8sNamespaceResource}
}
