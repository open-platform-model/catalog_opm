package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ClusterRole Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes ClusterRole, granting permissions cluster-wide or in
// every namespace.
#ClusterRoleResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "clusterrole"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/clusterrole@v1"
		description:    "A native Kubernetes ClusterRole, granting permissions cluster-wide or in every namespace"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: clusterrole: schemas.#ClusterRoleSchema
}

#ClusterRole: c.#Component & {
	#resources: {(#ClusterRoleResource.metadata.fqn): #ClusterRoleResource}
}
