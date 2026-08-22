package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ClusterRole Resource Definition
/////////////////////////////////////////////////////////////////

// #ClusterRoleResource defines a native Kubernetes ClusterRole as an OPM resource.
// Use this to grant cluster-scoped permissions or namespace permissions across all namespaces.
#ClusterRoleResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "clusterrole"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/clusterrole@v1"
		description:    "A native Kubernetes ClusterRole resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: clusterrole: schemas.#ClusterRoleSchema
}

#ClusterRole: c.#Component & {
	#resources: {(#ClusterRoleResource.metadata.fqn): #ClusterRoleResource}
}
