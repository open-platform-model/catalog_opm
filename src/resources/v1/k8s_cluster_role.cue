package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// ClusterRole Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sClusterRoleResource defines a native Kubernetes ClusterRole as an OPM resource.
// Use this to grant cluster-scoped permissions or namespace permissions across all namespaces.
#K8sClusterRoleResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-clusterrole"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-clusterrole@v1"
		description:    "A native Kubernetes ClusterRole resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: k8sClusterrole: schemas.#ClusterRoleSchema
}

#K8sClusterRole: c.#Component & {
	#resources: {(#K8sClusterRoleResource.metadata.fqn): #K8sClusterRoleResource}
}
